#!/usr/bin/env python3
"""
ACOUSTIC BAY - Atlas Prep Pipeline (re-runnable, config-driven)

Turns the opaque JPG contact sheets in assets/sprites/_source/ into packed,
transparent PNG atlases + JSON manifests that ManifestLoader turns into
SpriteFrames at load time.

  python tools/atlas_prep.py                 # build every unit in tools/atlas_prep.json
  python tools/atlas_prep.py --unit archer   # build one unit
  python tools/atlas_prep.py --inspect archer_v1 [--region x0 y0 x1 y1]
                                             # dump numbered components for a sheet

Keying (per sheet, see "key" in the config):
  bg_band  - background = low-saturation pixels whose max channel lies in [lo, hi].
             Covers pure black sheets (lo=0), the baked fake checkerboards and the
             grid sheet (both tones/lines sit inside the band). Background is
             flood-filled from the sheet border; enclosed regions only become holes
             when they are larger than hole_min_area, so small dark interior
             details stay opaque while e.g. the gap inside a bow becomes clear.
             Edge pixels within `feather` px of the background are un-mixed against
             the local background estimate (alpha + de-contaminated colour), which
             removes black halos and grey checker fringe.
  luma     - (per region) alpha from luminance, colour un-premultiplied. Used for
             glow / FX / particle rows; manifest flags them blend="add" unless the
             animation says otherwise. `solid_above` keeps bright cores opaque.

Erase regions (watermark, labels, portraits) are forced transparent before
slicing and listed in every manifest that uses the sheet.

Frames come from connected components inside a region, from hand rects, or
both. Pivots are bottom-centre (feet) or centre; hand fixes go in each frame's
"override": {"ox":..,"oy":..} and survive re-runs (matched by frame id).

Dependencies: numpy + Pillow only.
"""

import argparse
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CONFIG_PATH = os.path.join(BASE_DIR, "tools", "atlas_prep.json")


# --------------------------------------------------------------------------- #
# Small image helpers (no scipy)
# --------------------------------------------------------------------------- #

def box_sum(a, r):
    """Sum over a (2r+1)^2 window, zero padded. a: 2D float/int array."""
    if r <= 0:
        return a.astype(np.float64)
    p = np.pad(a.astype(np.float64), ((r + 1, r), (r + 1, r)))
    c = p.cumsum(0).cumsum(1)
    k = 2 * r + 1
    return c[k:, k:] - c[:-k, k:] - c[k:, :-k] + c[:-k, :-k]


def dilate(mask, r):
    return box_sum(mask, r) > 0.5 if r > 0 else mask.copy()


def label(mask):
    """4-connected component labelling via run-length union-find.
    Returns (labels int32 array, count). Label 0 = not in mask."""
    h, w = mask.shape
    parent = [0]

    def find(x):
        root = x
        while parent[root] != root:
            root = parent[root]
        while parent[x] != root:
            parent[x], x = root, parent[x]
        return root

    rows_runs = []
    prev = []  # (start, end_exclusive, id)
    for y in range(h):
        row = mask[y]
        if not row.any():
            rows_runs.append([])
            prev = []
            continue
        d = np.diff(np.concatenate(([0], row.view(np.int8), [0])))
        starts = np.flatnonzero(d == 1)
        ends = np.flatnonzero(d == -1)
        cur = []
        j = 0
        for s, e in zip(starts.tolist(), ends.tolist()):
            rid = len(parent)
            parent.append(rid)
            while j < len(prev) and prev[j][1] <= s:
                j += 1
            k = j
            while k < len(prev) and prev[k][0] < e:
                a, b = find(rid), find(prev[k][2])
                if a != b:
                    parent[max(a, b)] = min(a, b)
                k += 1
            cur.append((s, e, rid))
        rows_runs.append(cur)
        prev = cur

    remap = {}
    labels = np.zeros((h, w), np.int32)
    for y, runs in enumerate(rows_runs):
        for s, e, rid in runs:
            root = find(rid)
            lab = remap.get(root)
            if lab is None:
                lab = len(remap) + 1
                remap[root] = lab
            labels[y, s:e] = lab
    return labels, len(remap)


def component_boxes(labels, n):
    """Per-label (x0, y0, x1, y1, area) with exclusive x1/y1."""
    ys, xs = np.nonzero(labels)
    lab = labels[ys, xs]
    out = {}
    if lab.size == 0:
        return out
    order = np.argsort(lab, kind="stable")
    lab, ys, xs = lab[order], ys[order], xs[order]
    cuts = np.flatnonzero(np.diff(lab)) + 1
    for seg_l, seg_y, seg_x in zip(np.split(lab, cuts), np.split(ys, cuts), np.split(xs, cuts)):
        out[int(seg_l[0])] = (int(seg_x.min()), int(seg_y.min()), int(seg_x.max()) + 1,
                              int(seg_y.max()) + 1, int(seg_l.size))
    return out


# --------------------------------------------------------------------------- #
# Keying
# --------------------------------------------------------------------------- #

_WATERMARK_CACHE = {}


def watermark_alpha(wm, source_dir):
    """Per-pixel opacity of the generator watermark, measured on a sheet where it
    sits over flat black (observed = a * colour + (1 - a) * 0)."""
    key = (wm["template_sheet"], tuple(wm["rect"]))
    if key not in _WATERMARK_CACHE:
        x0, y0, x1, y1 = wm["rect"]
        img = Image.open(os.path.join(source_dir, wm["template_sheet"] + ".jpg")).convert("RGB")
        sub = np.asarray(img).astype(np.float32)[y0:y1, x0:x1].max(2)
        a = np.clip((sub - wm.get("floor", 4.0)) / float(wm.get("color", 255.0)), 0.0, 0.95)
        a[a < 0.02] = 0.0
        _WATERMARK_CACHE[key] = a
    return _WATERMARK_CACHE[key]


class KeyedSheet:
    def __init__(self, name, cfg, source_dir, watermark=None):
        self.name = name
        self.cfg = cfg
        path = os.path.join(source_dir, cfg.get("file", name + ".jpg"))
        self.rgb = np.asarray(Image.open(path).convert("RGB")).astype(np.float32)
        self.h, self.w = self.rgb.shape[:2]
        self.erased = [dict(e, sheet=name) for e in cfg.get("erase", [])]
        if watermark and cfg.get("watermark", True):
            a = watermark_alpha(watermark, source_dir)[..., None]
            x0, y0, x1, y1 = watermark["rect"]
            col = float(watermark.get("color", 255.0))
            sub = self.rgb[y0:y1, x0:x1]
            self.rgb[y0:y1, x0:x1] = np.clip((sub - a * col) / (1.0 - a), 0, 255)
            self.erased.append({"rect": list(watermark["rect"]), "sheet": name,
                                "reason": "generator watermark (inverse-blended out, art underneath kept)"})
        self.rgba = self._key()

    def _key(self):
        key = self.cfg.get("key", {})
        lo, hi = key.get("lum", [0, 22])
        max_sat = key.get("max_sat", 16)
        hole_min = key.get("hole_min_area", 150)
        feather = key.get("feather", 2)

        rgb = self.rgb
        mx = rgb.max(2)
        sat = mx - rgb.min(2)
        cand = (sat <= max_sat) & (mx >= lo) & (mx <= hi)
        grid = key.get("grid")
        if grid:
            # Baked grid: tones in grid["lum"] count as background only on detected
            # grid-line rows/columns, so dark hatching inside sprites stays opaque.
            g_lo, g_hi = grid["lum"]
            tone = (sat <= max_sat) & (mx >= g_lo) & (mx <= g_hi)
            frac = grid.get("line_frac", 0.35)
            rows = tone.mean(1) > frac
            cols = tone.mean(0) > frac
            rows = dilate(rows[:, None].repeat(3, 1), 1)[:, 1]
            cols = dilate(cols[None, :].repeat(3, 0), 1)[1]
            on_line = rows[:, None] | cols[None, :]
            cand |= tone & on_line
            self.grid_rows, self.grid_cols = int(rows.sum()), int(cols.sum())

        forced = np.zeros(cand.shape, bool)
        for e in self.erased:
            if e["reason"].startswith("generator watermark"):
                continue
            x0, y0, x1, y1 = e["rect"]
            sel = np.ones((y1 - y0, x1 - x0), bool)
            # "only_if" erases just the line-like pixels inside the rect (divider /
            # ground lines that pass under sprite feet), keeping saturated art.
            cond = e.get("only_if")
            if cond:
                sub_mx, sub_sat = mx[y0:y1, x0:x1], sat[y0:y1, x0:x1]
                sel &= (sub_sat <= cond.get("max_sat", 255)) & (sub_mx <= cond.get("max_lum", 255))
            forced[y0:y1, x0:x1] |= sel
        cand |= forced

        open_r = key.get("open_radius", 0)
        if open_r:
            # Morphological opening: thin dark strokes (hatching) inside sprites can
            # no longer carry the border flood fill into the art. Real background is
            # wide, survives erosion, and is grown back afterwards.
            k = 2 * open_r + 1
            eroded = box_sum(cand, open_r) >= k * k - 0.5
            cand_flood = dilate(eroded, open_r) & cand
        else:
            cand_flood = cand
        labels, n = label(cand_flood)
        boxes = component_boxes(labels, n)
        # An enclosed region only counts as a see-through hole when it is large AND
        # mostly the flat background tone; textured dark interiors stay opaque.
        tone_lo, tone_hi = key.get("hole_tone", [lo, hi])
        tone_frac = key.get("hole_tone_frac", 0.0)
        flat = cand_flood & (mx >= tone_lo) & (mx <= tone_hi)
        flat_count = np.bincount(labels[flat], minlength=n + 1)
        bg_ids = []
        for lab, (x0, y0, x1, y1, area) in boxes.items():
            touches = x0 == 0 or y0 == 0 or x1 == self.w or y1 == self.h
            if touches or (area >= hole_min and flat_count[lab] >= tone_frac * area):
                bg_ids.append(lab)
        bg = np.isin(labels, np.array(bg_ids, np.int32)) | forced

        alpha = np.where(bg, 0.0, 1.0).astype(np.float32)
        out_rgb = rgb.copy()

        # --- edge un-mixing: fringe pixels are a blend of fg and local bg ---
        if feather > 0:
            fg = ~bg
            near_bg = dilate(bg, feather) & fg
            interior = fg & ~near_bg
            r_bg, r_fg = feather + 2, feather + 3
            bg_cnt = box_sum(bg, r_bg)
            fg_cnt = box_sum(interior, r_fg)
            bg_col = np.zeros_like(rgb)
            fg_col = np.zeros_like(rgb)
            for c in range(3):
                bg_col[..., c] = box_sum(rgb[..., c] * bg, r_bg) / np.maximum(bg_cnt, 1)
                fg_col[..., c] = box_sum(rgb[..., c] * interior, r_fg) / np.maximum(fg_cnt, 1)
            has_fg_ref = fg_cnt > 0
            fg_col = np.where(has_fg_ref[..., None], fg_col, rgb)
            d = fg_col - bg_col
            dd = (d * d).sum(2)
            a = ((rgb - bg_col) * d).sum(2) / np.maximum(dd, 1e-3)
            a = np.clip(a, 0.0, 1.0)
            # Low-contrast fg/bg pairs can't be un-mixed reliably: keep opaque.
            a = np.where(dd < 18.0 ** 2, 1.0, a)
            # Thin strokes (no interior reference) un-mix against bg only via luminance.
            thin = near_bg & ~has_fg_ref
            lum_a = np.clip((mx - bg_col.max(2)) / np.maximum(255.0 - bg_col.max(2), 1.0) * 2.0, 0.0, 1.0)
            a = np.where(thin, lum_a, a)
            sel = near_bg
            alpha[sel] = a[sel]
            # De-contaminated colour: interior reference where we have one,
            # otherwise un-premultiply against the background estimate.
            unmix = bg_col + (rgb - bg_col) / np.maximum(a, 0.05)[..., None]
            col = np.where(has_fg_ref[..., None], fg_col, np.clip(unmix, 0, 255))
            out_rgb[sel] = col[sel]

        # --- luminance-to-alpha regions (glow / FX / particles) ---
        for reg in self.cfg.get("luma", []):
            x0, y0, x1, y1 = reg["rect"]
            floor = reg.get("floor", float(hi) + 2.0)
            gamma = reg.get("gamma", 1.0)
            # Alpha ramps from 0 at `floor` to 1 at `knee`; above the knee the art is
            # fully opaque with its original colour (glowing bodies stay solid).
            knee = float(reg.get("knee", 255.0))
            sub = rgb[y0:y1, x0:x1]
            smx = sub.max(2)
            la = np.clip((smx - floor) / max(knee - floor, 1.0), 0.0, 1.0) ** gamma
            fz = forced[y0:y1, x0:x1]
            la[fz] = 0.0
            # Neutral greys inside a glow (baked grid lines) are background, not light.
            grey_below = reg.get("drop_grey_below")
            if grey_below:
                ssat = smx - sub.min(2)
                la[(ssat < 18) & (smx < grey_below)] = 0.0
            # Un-premultiply against black so the glow keeps its hue when blended.
            col = np.clip(sub / np.maximum(la, 1e-3)[..., None], 0, 255)
            col = np.where((la >= 1.0)[..., None], sub, col)
            alpha[y0:y1, x0:x1] = la
            out_rgb[y0:y1, x0:x1] = col

        rgba = np.dstack([np.clip(out_rgb, 0, 255), alpha * 255.0]).astype(np.uint8)
        rgba[alpha <= 0.0, :3] = 0
        return rgba

    def region_luma(self, rect):
        """True if rect is (mostly) inside a luma region."""
        for reg in self.cfg.get("luma", []):
            x0, y0, x1, y1 = reg["rect"]
            if rect[0] >= x0 - 2 and rect[1] >= y0 - 2 and rect[2] <= x1 + 2 and rect[3] <= y1 + 2:
                return True
        return False


# --------------------------------------------------------------------------- #
# Frame finding
# --------------------------------------------------------------------------- #

def find_components(sheet, region, join=6, min_area=150, alpha_cut=60):
    x0, y0, x1, y1 = region
    a = sheet.rgba[y0:y1, x0:x1, 3] > alpha_cut
    grown = dilate(a, join)
    labels, n = label(grown)
    labels = np.where(a, labels, 0)
    boxes = component_boxes(labels, n)
    comps = []
    for lab, (bx0, by0, bx1, by1, area) in boxes.items():
        if area < min_area:
            continue
        comps.append((bx0 + x0, by0 + y0, bx1 + x0, by1 + y0, area))
    comps.sort(key=lambda c: (c[0] + c[2]) / 2)
    return comps


def tight_rect(sheet, rect, alpha_cut=8):
    x0, y0, x1, y1 = rect
    a = sheet.rgba[y0:y1, x0:x1, 3] > alpha_cut
    ys, xs = np.nonzero(a)
    if ys.size == 0:
        return rect
    return (x0 + int(xs.min()), y0 + int(ys.min()), x0 + int(xs.max()) + 1, y0 + int(ys.max()) + 1)


def pivot_for(crop_alpha, anchor):
    h, w = crop_alpha.shape
    if anchor == "center":
        return w // 2, h // 2
    if anchor == "top":
        cols = np.flatnonzero(crop_alpha[: max(2, h // 12)].max(0) > 128)
        return (int((cols.min() + cols.max()) // 2) if cols.size else w // 2), 0
    solid = crop_alpha > 128
    rows = np.flatnonzero(solid.sum(1) >= 2)
    oy = int(rows.max()) + 1 if rows.size else h
    band = solid[max(0, oy - max(6, h // 12)):oy]
    cols = np.flatnonzero(band.any(0))
    ox = int((cols.min() + cols.max() + 1) // 2) if cols.size else w // 2
    return ox, oy


# --------------------------------------------------------------------------- #
# Packing
# --------------------------------------------------------------------------- #

def shelf_pack(sizes, max_w=2048, pad=2):
    order = sorted(range(len(sizes)), key=lambda i: -sizes[i][1])
    pos = [None] * len(sizes)
    x = y = shelf_h = 0
    width = 0
    for i in order:
        w, h = sizes[i]
        if x + w + pad > max_w and x > 0:
            y += shelf_h + pad
            x = shelf_h = 0
        pos[i] = (x + pad, y + pad)
        x += w + pad
        shelf_h = max(shelf_h, h + pad)
        width = max(width, x + pad)
    return pos, width, y + shelf_h + pad


# --------------------------------------------------------------------------- #
# Build
# --------------------------------------------------------------------------- #

class Builder:
    def __init__(self, cfg):
        self.cfg = cfg
        self.paths = {k: os.path.join(BASE_DIR, v) for k, v in cfg["paths"].items()}
        self.sheets = {}
        self.comp_cache = {}

    def sheet(self, name):
        if name not in self.sheets:
            print(f"[atlas_prep] keying {name} ...", flush=True)
            self.sheets[name] = KeyedSheet(name, self.cfg["sheets"][name], self.paths["source"],
                                           self.cfg.get("watermark"))
        return self.sheets[name]

    def components(self, sheet_name, region, join, min_area):
        k = (sheet_name, tuple(region), join, min_area)
        if k not in self.comp_cache:
            self.comp_cache[k] = find_components(self.sheet(sheet_name), region, join, min_area)
        return self.comp_cache[k]

    def make_crop(self, sname, r, isolate, tint, drop_low_sat=0, join=6):
        sh = self.sheet(sname)
        crop = sh.rgba[r[1]:r[3], r[0]:r[2]].copy()
        if drop_low_sat:
            # Particle frames over a fake checker: dark grey specks are checker
            # leftovers, not art. Only saturated (crimson) pixels survive.
            c = crop[..., :3].astype(np.int32)
            crop[(c.max(2) - c.min(2)) < drop_low_sat] = 0
        if isolate:
            # Keep only the dominant connected piece in the rect (drops neighbours'
            # overlapping blades/chains that a plain rect crop would include).
            a = crop[..., 3] > 60
            labels, n = label(dilate(a, join))
            if n > 1:
                counts = np.bincount(labels[a], minlength=n + 1)
                counts[0] = 0
                keep = labels == int(counts.argmax())
                crop[~keep] = 0
        if tint:
            # Shift only the crimson body toward the target palette; ink lines and
            # neutral greys keep their value (weight = how red the pixel is).
            rgb = crop[..., :3].astype(np.float32)
            w = np.clip((rgb[..., 0] - np.maximum(rgb[..., 1], rgb[..., 2]) - 40.0) / 80.0, 0.0, 1.0)[..., None]
            tinted = rgb * np.array(tint, np.float32)
            crop[..., :3] = np.clip(rgb + w * (tinted - rgb), 0, 255).astype(np.uint8)
        return crop

    def resolve_frames(self, unit_name, anim_name, spec):
        """Returns list of (sheet_name, rect, isolate, tint) for one animation spec."""
        out = []
        for src in spec.get("sources", [spec]):
            sname = src.get("sheet")
            iso = src.get("isolate", False)
            tint = src.get("tint") or self.cfg["sheets"][sname].get("tint")
            if src.get("drop_low_sat"):
                iso = (iso, src["drop_low_sat"])
            if "rects" in src:
                for r in src["rects"]:
                    out.append((sname, tight_rect(self.sheet(sname), r), iso, tint))
            if "region" in src:
                comps = self.components(sname, src["region"], src.get("join", 6), src.get("min_area", 150))
                picks = src.get("pick", list(range(len(comps))))
                for p in picks:
                    if isinstance(p, list):  # merge several components into one frame
                        cs = [comps[i] for i in p]
                        out.append((sname, (min(c[0] for c in cs), min(c[1] for c in cs),
                                            max(c[2] for c in cs), max(c[3] for c in cs)), iso, tint))
                    else:
                        if p >= len(comps):
                            raise SystemExit(f"[atlas_prep] {unit_name}.{anim_name}: pick {p} but only "
                                             f"{len(comps)} components in {sname} {src['region']}")
                        out.append((sname, comps[p][:4], iso, tint))
        return out

    def build_unit(self, unit_name):
        ucfg = self.cfg["units"][unit_name]
        manifest_path = os.path.join(self.paths["manifests"], unit_name + ".json")
        old_overrides = {}
        if os.path.exists(manifest_path):
            with open(manifest_path, "r", encoding="utf-8") as f:
                old = json.load(f)
            for an in old.get("animations", {}).values():
                for fr in an.get("frames", []):
                    if fr.get("override"):
                        old_overrides[fr["id"]] = fr["override"]

        anims = {}
        unique = {}  # (sheet, rect) -> index into crops
        crops = []
        pad_src = self.cfg.get("frame_pad", 2)
        for anim_name, spec in ucfg["animations"].items():
            if "derive" in spec:
                continue
            frames = self.resolve_frames(unit_name, anim_name, spec)
            if not frames:
                raise SystemExit(f"[atlas_prep] {unit_name}.{anim_name}: no frames resolved")
            anchor = spec.get("anchor", ucfg.get("anchor", "feet"))
            entries = []
            for sname, r, iso, tint in frames:
                sh = self.sheet(sname)
                r = (max(0, r[0] - pad_src), max(0, r[1] - pad_src), min(sh.w, r[2] + pad_src), min(sh.h, r[3] + pad_src))
                key = (sname, r, iso, tuple(tint) if tint else None)
                if key not in unique:
                    iso_flag, low_sat = iso if isinstance(iso, tuple) else (iso, 0)
                    crop = self.make_crop(sname, r, iso_flag, tint, low_sat)
                    unique[key] = len(crops)
                    crops.append(crop)
                ci = unique[key]
                ox, oy = pivot_for(crops[ci][..., 3], anchor)
                is_luma = sh.region_luma(r)
                entries.append({"crop": ci, "sheet": sname, "src": list(r), "ox": ox, "oy": oy, "luma": is_luma})
            anims[anim_name] = (spec, entries)

        # Unify pivot within an animation: frames share the median foot height
        # offset relative to their own box, so per-frame jitter comes only from art.
        sizes = [(c.shape[1], c.shape[0]) for c in crops]
        pos, aw, ah = shelf_pack(sizes, self.cfg.get("atlas_max_width", 2048))
        atlas = np.zeros((ah, aw, 4), np.uint8)
        for ci, c in enumerate(crops):
            x, y = pos[ci]
            atlas[y:y + c.shape[0], x:x + c.shape[1]] = c

        os.makedirs(self.paths["atlases"], exist_ok=True)
        os.makedirs(self.paths["manifests"], exist_ok=True)
        atlas_file = os.path.join(self.paths["atlases"], unit_name + ".png")
        Image.fromarray(atlas, "RGBA").save(atlas_file, optimize=True)

        used_sheets = []
        out_anims = {}
        for anim_name, spec in ucfg["animations"].items():
            if "derive" in spec:
                continue
            spec, entries = anims[anim_name]
            fps = spec.get("fps", ucfg.get("fps", 10))
            frames_json = []
            for i, e in enumerate(entries):
                c = crops[e["crop"]]
                x, y = pos[e["crop"]]
                fid = f"{anim_name}:{i}:{e['sheet']}@{e['src'][0]},{e['src'][1]}"
                frames_json.append({
                    "id": fid, "x": x, "y": y, "w": int(c.shape[1]), "h": int(c.shape[0]),
                    "ox": e["ox"], "oy": e["oy"],
                    "override": old_overrides.get(fid),
                    "sheet": e["sheet"], "src": e["src"],
                })
                if e["sheet"] not in used_sheets:
                    used_sheets.append(e["sheet"])
            if spec.get("reverse"):
                frames_json.reverse()
            n = len(frames_json)
            durations = spec.get("durations") or [round(1.0 / fps, 4)] * n
            if len(durations) != n:
                raise SystemExit(f"[atlas_prep] {unit_name}.{anim_name}: {len(durations)} durations for {n} frames")
            blend = spec.get("blend", "add" if all(e["luma"] for e in entries) else "mix")
            a = {"frames": frames_json, "durations": durations, "loop": spec.get("loop", False), "fps": fps,
                 "blend": blend, "anchor": spec.get("anchor", ucfg.get("anchor", "feet"))}
            for k in ("events", "note", "procedural"):
                if k in spec:
                    a[k] = spec[k]
            out_anims[anim_name] = a

        # Derived animations: reuse frames of another animation (subset / reverse /
        # hold) and describe procedural treatment (flash, squash, tint) for runtime.
        for anim_name, spec in ucfg["animations"].items():
            if "derive" not in spec:
                continue
            d = spec["derive"]
            base = out_anims[d["from"]]
            idx = d.get("frames", list(range(len(base["frames"]))))
            frames_json = [dict(base["frames"][i]) for i in idx]
            if d.get("reverse"):
                frames_json.reverse()
            fps = spec.get("fps", base["fps"])
            n = len(frames_json)
            durations = spec.get("durations") or [round(1.0 / fps, 4)] * n
            a = {"frames": frames_json, "durations": durations, "loop": spec.get("loop", False), "fps": fps,
                 "blend": spec.get("blend", base["blend"]), "anchor": base["anchor"],
                 "faked": spec.get("note", f"derived from '{d['from']}'")}
            for k in ("events", "procedural"):
                if k in spec:
                    a[k] = spec[k]
            out_anims[anim_name] = a

        manifest = {
            "version": 1,
            "unit": unit_name,
            "atlas": "res://" + os.path.relpath(atlas_file, BASE_DIR).replace("\\", "/"),
            "atlas_size": [aw, ah],
            "scale": ucfg.get("scale", 1.0),
            "foot_offset": ucfg.get("foot_offset", 0),
            "collision": ucfg.get("collision", None),
            "notes": ucfg.get("notes", ""),
            "sources": {s: self.cfg["sheets"][s].get("file", s + ".jpg") for s in used_sheets},
            "erased_regions": [e for s in used_sheets for e in self.sheet(s).erased],
            "animations": out_anims,
        }
        with open(manifest_path, "w", encoding="utf-8") as f:
            json.dump(manifest, f, indent=1)
        nfr = sum(len(a["frames"]) for a in out_anims.values())
        print(f"[atlas_prep] {unit_name}: {len(out_anims)} anims, {nfr} frames, {len(crops)} unique crops, atlas {aw}x{ah}")
        self.debug_unit(unit_name, manifest, atlas)
        return manifest

    def debug_unit(self, unit_name, manifest, atlas):
        """Contact sheet: every animation row on black and on mid-grey, with pivots."""
        dbg = self.paths["debug"]
        os.makedirs(dbg, exist_ok=True)
        rows = []
        for name, a in manifest["animations"].items():
            cells = []
            for fr in a["frames"]:
                c = atlas[fr["y"]:fr["y"] + fr["h"], fr["x"]:fr["x"] + fr["w"]]
                cells.append((c, fr["ox"], fr["oy"]))
            rows.append((name, cells))
        cell_h = max((c.shape[0] for _, cs in rows for c, _, _ in cs), default=10)
        width = max((sum(c.shape[1] + 8 for c, _, _ in cs) for _, cs in rows), default=10) + 160
        for bg_name, bg_col in (("black", (0, 0, 0)), ("grey", (128, 128, 128))):
            img = Image.new("RGB", (width, (cell_h + 20) * len(rows) + 10), bg_col)
            draw = ImageDraw.Draw(img)
            yy = 5
            for name, cells in rows:
                draw.text((4, yy + 4), name, fill=(255, 255, 255) if bg_name == "black" else (0, 0, 0))
                xx = 156
                for c, ox, oy in cells:
                    tile = Image.fromarray(c, "RGBA")
                    oyy = yy + cell_h - c.shape[0]
                    img.paste(tile, (xx, oyy), tile)
                    draw.line([(xx + ox - 4, oyy + oy), (xx + ox + 4, oyy + oy)], fill=(0, 255, 255))
                    draw.line([(xx + ox, oyy + oy - 4), (xx + ox, oyy + oy + 4)], fill=(0, 255, 255))
                    xx += c.shape[1] + 8
                yy += cell_h + 20
            img.save(os.path.join(dbg, f"{unit_name}_{bg_name}.png"))

    def inspect(self, sheet_name, region=None, join=6, min_area=150, scale=0.5):
        sh = self.sheet(sheet_name)
        region = region or (0, 0, sh.w, sh.h)
        comps = find_components(sh, region, join, min_area)
        dbg = self.paths["debug"]
        os.makedirs(dbg, exist_ok=True)
        grey = Image.new("RGBA", (sh.w, sh.h), (128, 128, 128, 255))
        keyed = Image.fromarray(sh.rgba, "RGBA")
        grey.alpha_composite(keyed)
        draw = ImageDraw.Draw(grey)
        for e in sh.erased:
            draw.rectangle(e["rect"], outline=(0, 0, 255, 255), width=3)
        for i, (x0, y0, x1, y1, area) in enumerate(comps):
            draw.rectangle((x0, y0, x1 - 1, y1 - 1), outline=(0, 255, 0, 255), width=2)
            draw.text((x0 + 2, y0 + 2), str(i), fill=(255, 255, 0, 255))
        texts = []
        for i, c in enumerate(comps):
            if self.text_like(sh, c):
                texts.append(i)
                draw.rectangle((c[0], c[1], c[2] - 1, c[3] - 1), outline=(255, 0, 255, 255), width=3)
        out = grey.crop(region).convert("RGB")
        out = out.resize((int(out.width * scale), int(out.height * scale)), Image.LANCZOS)
        p = os.path.join(dbg, f"inspect_{sheet_name}.png")
        out.save(p)
        print(f"[atlas_prep] {len(comps)} components in {sheet_name} {region} -> {p}")
        for i, c in enumerate(comps):
            flag = "  TEXT?" if i in texts else ""
            print(f"  {i:3d}: rect=({c[0]},{c[1]},{c[2]},{c[3]}) size={c[2]-c[0]}x{c[3]-c[1]} area={c[4]}{flag}")
        if self.propose_text:
            print(json.dumps([{"rect": [comps[i][0] - 3, comps[i][1] - 3, comps[i][2] + 3, comps[i][3] + 3],
                               "reason": "text label"} for i in texts]))

    propose_text = False

    @staticmethod
    def text_like(sh, c):
        """Short, sparse, mostly white/grey low-saturation component = baked label."""
        x0, y0, x1, y1, area = c
        h = y1 - y0
        if h > 42 or h < 12:
            return False
        sub = sh.rgba[y0:y1, x0:x1].astype(np.int32)
        op = sub[..., 3] > 128
        if op.sum() == 0:
            return False
        mx = sub[..., :3].max(2)
        sat = mx - sub[..., :3].min(2)
        white = op & (sat < 50) & (mx > 150)
        return white.sum() / op.sum() > 0.5 and op.sum() / float((x1 - x0) * h) < 0.5


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--unit", action="append")
    ap.add_argument("--inspect")
    ap.add_argument("--region", type=int, nargs=4)
    ap.add_argument("--join", type=int, default=6)
    ap.add_argument("--min-area", type=int, default=150)
    ap.add_argument("--scale", type=float, default=0.5)
    ap.add_argument("--propose-text", action="store_true",
                    help="with --inspect: print erase entries for text-like components")
    args = ap.parse_args()
    with open(CONFIG_PATH, "r", encoding="utf-8") as f:
        cfg = json.load(f)
    b = Builder(cfg)
    b.propose_text = args.propose_text
    if args.inspect:
        b.inspect(args.inspect, args.region, args.join, args.min_area, args.scale)
        return
    units = args.unit or list(cfg["units"].keys())
    for u in units:
        b.build_unit(u)


if __name__ == "__main__":
    main()
