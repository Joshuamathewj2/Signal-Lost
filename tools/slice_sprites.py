#!/usr/bin/env python3
"""
SIGNAL LOST - Sprite Slicing & Resource Generation Pipeline
Auto-detects and extracts frames from:
  1. White_Ninja_Samurai_Sprite_Sheet.png (HERO)
  2. Samurai_Enemy_Sprite_Sheet.png (ENEMIES & FX)
  3. Dark_Trap_Sprite_Atlas.png (TRAPS & PROJECTILES)

Exports individual transparent PNGs, JSON manifest, contact sheet preview,
and Godot SpriteFrames resources (.tres).
"""

import os
import json
from PIL import Image, ImageDraw, ImageFont
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HERO_SHEET = os.path.join(BASE_DIR, "assets", "sprites", "hero", "White_Ninja_Samurai_Sprite_Sheet.png")
ENEMY_SHEET = os.path.join(BASE_DIR, "assets", "sprites", "enemies", "Samurai_Enemy_Sprite_Sheet.png")
TRAP_SHEET = os.path.join(BASE_DIR, "assets", "sprites", "traps", "Dark_Trap_Sprite_Atlas.png")

OUT_HERO = os.path.join(BASE_DIR, "assets", "sprites", "hero")
OUT_ENEMIES = os.path.join(BASE_DIR, "assets", "sprites", "enemies")
OUT_TRAPS = os.path.join(BASE_DIR, "assets", "sprites", "traps")
OUT_FX = os.path.join(BASE_DIR, "assets", "sprites", "fx")
DOCS_DIR = os.path.join(BASE_DIR, "docs")
RES_SPRITES_DIR = os.path.join(BASE_DIR, "resources", "sprites")

# Region definition table: (sheet_key, category, subfolder, anim_name, frame_index, (x0, y0, x1, y1), align_mode)
# align_mode: 'bottom' (feet), 'center' (projectiles/fx), 'top' (ceiling)
REGIONS = [
    # ================= HERO =================
    ("hero", "hero", "", "idle", 0, (40, 85, 245, 245), "bottom"),
    ("hero", "hero", "", "run", 0, (250, 100, 420, 245), "bottom"),
    ("hero", "hero", "", "run", 1, (505, 100, 680, 245), "bottom"),
    ("hero", "hero", "", "jump", 0, (745, 75, 1000, 240), "bottom"),
    ("hero", "hero", "", "attack_heavy", 0, (35, 280, 200, 455), "bottom"),
    ("hero", "hero", "", "attack_thrust", 0, (240, 325, 515, 455), "bottom"),
    ("hero", "hero", "", "crouch", 0, (520, 350, 695, 455), "bottom"),
    ("hero", "hero", "", "hurt", 0, (750, 305, 1005, 455), "bottom"),

    # ================= SWORD (RONIN) =================
    ("enemy", "ronin", "ronin", "idle", 0, (20, 20, 85, 110), "bottom"),
    ("enemy", "ronin", "ronin", "walk", 0, (125, 20, 215, 110), "bottom"),
    ("enemy", "ronin", "ronin", "run", 0, (220, 20, 315, 110), "bottom"),
    ("enemy", "ronin", "ronin", "attack1", 0, (350, 20, 450, 110), "bottom"),
    ("enemy", "ronin", "ronin", "attack2", 0, (460, 20, 570, 110), "bottom"),
    ("enemy", "ronin", "ronin", "attack3", 0, (570, 20, 735, 110), "bottom"),
    ("enemy", "ronin", "ronin", "hurt", 0, (755, 20, 840, 110), "bottom"),
    ("enemy", "ronin", "ronin", "die", 0, (840, 20, 1015, 110), "bottom"),

    # ================= ARCHER =================
    ("enemy", "archer", "archer", "idle", 0, (25, 130, 95, 228), "bottom"),
    ("enemy", "archer", "archer", "walk", 0, (130, 130, 205, 228), "bottom"),
    ("enemy", "archer", "archer", "run", 0, (240, 130, 325, 228), "bottom"),
    ("enemy", "archer", "archer", "aim", 0, (370, 130, 450, 228), "bottom"),
    ("enemy", "archer", "archer", "shoot", 0, (470, 130, 560, 228), "bottom"),
    ("enemy", "archer", "archer", "shoot_release", 0, (590, 130, 675, 228), "bottom"),
    ("enemy", "archer", "archer", "arrow_in_flight", 0, (675, 160, 765, 210), "center"),
    ("enemy", "archer", "archer", "hurt", 0, (785, 130, 860, 228), "bottom"),
    ("enemy", "archer", "archer", "die", 0, (865, 130, 1015, 228), "bottom"),

    # ================= SPEAR =================
    ("enemy", "spear", "spear", "idle", 0, (15, 260, 80, 360), "bottom"),
    ("enemy", "spear", "spear", "walk", 0, (105, 260, 215, 360), "bottom"),
    ("enemy", "spear", "spear", "run", 0, (230, 260, 340, 360), "bottom"),
    ("enemy", "spear", "spear", "thrust", 0, (360, 260, 540, 360), "bottom"),
    ("enemy", "spear", "spear", "sweep", 0, (545, 260, 730, 360), "bottom"),
    ("enemy", "spear", "spear", "hurt", 0, (755, 260, 840, 360), "bottom"),
    ("enemy", "spear", "spear", "die", 0, (845, 260, 1015, 360), "bottom"),

    # ================= HEAVY (BRUTE) =================
    ("enemy", "brute", "brute", "idle", 0, (10, 380, 105, 510), "bottom"),
    ("enemy", "brute", "brute", "walk", 0, (130, 380, 240, 510), "bottom"),
    ("enemy", "brute", "brute", "run", 0, (265, 380, 360, 510), "bottom"),
    ("enemy", "brute", "brute", "smash", 0, (395, 380, 540, 510), "bottom"),
    ("enemy", "brute", "brute", "swing", 0, (550, 380, 735, 510), "bottom"),
    ("enemy", "brute", "brute", "hurt", 0, (750, 380, 835, 510), "bottom"),
    ("enemy", "brute", "brute", "die", 0, (845, 380, 1015, 510), "bottom"),

    # ================= FX & EXTRA =================
    ("enemy", "fx", "fx", "arrow", 0, (20, 560, 95, 620), "center"),
    ("enemy", "fx", "fx", "arrow_trail", 0, (110, 560, 180, 620), "center"),
    ("enemy", "fx", "fx", "slash1", 0, (195, 545, 315, 620), "center"),
    ("enemy", "fx", "fx", "slash2", 0, (335, 550, 410, 620), "center"),
    ("enemy", "fx", "fx", "spear_trail", 0, (420, 560, 535, 620), "center"),
    ("enemy", "fx", "fx", "smash_impact", 0, (550, 540, 685, 625), "bottom"),
    ("enemy", "fx", "fx", "hit_spark", 0, (735, 540, 795, 620), "center"),
    ("enemy", "fx", "fx", "blood_splat", 0, (810, 540, 895, 620), "center"),
    ("enemy", "fx", "fx", "dust", 0, (910, 560, 1015, 620), "bottom"),

    # ================= TRAPS =================
    # Floor Spikes
    ("trap", "floor_spikes", "floor_spikes", "idle", 0, (15, 25, 80, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "trigger", 0, (85, 25, 152, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "rising", 0, (158, 25, 225, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "rising", 1, (230, 25, 296, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "full", 0, (300, 25, 370, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "reset", 0, (378, 25, 446, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "reset", 1, (450, 25, 516, 95), "bottom"),
    ("trap", "floor_spikes", "floor_spikes", "hidden", 0, (520, 25, 588, 95), "bottom"),

    # Ceiling Spikes
    ("trap", "ceiling_spikes", "ceiling_spikes", "idle", 0, (600, 25, 680, 95), "top"),
    ("trap", "ceiling_spikes", "ceiling_spikes", "drop", 0, (682, 25, 760, 95), "top"),
    ("trap", "ceiling_spikes", "ceiling_spikes", "drop", 1, (764, 25, 842, 95), "top"),
    ("trap", "ceiling_spikes", "ceiling_spikes", "full", 0, (846, 25, 926, 95), "top"),
    ("trap", "ceiling_spikes", "ceiling_spikes", "reset", 0, (930, 25, 1010, 95), "top"),

    # Swinging Blade
    ("trap", "swinging_blade", "swinging_blade", "idle", 0, (15, 138, 85, 235), "top"),
    ("trap", "swinging_blade", "swinging_blade", "swing_left", 0, (100, 138, 185, 235), "top"),
    ("trap", "swinging_blade", "swinging_blade", "swing_center", 0, (200, 138, 275, 235), "top"),
    ("trap", "swinging_blade", "swinging_blade", "swing_right", 0, (295, 138, 380, 235), "top"),
    ("trap", "swinging_blade", "swinging_blade", "back_left", 0, (388, 138, 470, 235), "top"),

    # Horizontal Wall Blade
    ("trap", "wall_blade", "wall_blade", "idle", 0, (500, 138, 560, 235), "center"),
    ("trap", "wall_blade", "wall_blade", "extend", 0, (570, 138, 635, 235), "center"),
    ("trap", "wall_blade", "wall_blade", "extend", 1, (640, 138, 700, 235), "center"),
    ("trap", "wall_blade", "wall_blade", "attack", 0, (705, 138, 800, 235), "center"),
    ("trap", "wall_blade", "wall_blade", "retract", 0, (805, 138, 870, 235), "center"),
    ("trap", "wall_blade", "wall_blade", "retract", 1, (880, 138, 945, 235), "center"),
    ("trap", "wall_blade", "wall_blade", "hidden", 0, (955, 138, 1015, 235), "center"),

    # Arrow Trap
    ("trap", "arrow_trap", "arrow_trap", "idle", 0, (15, 275, 80, 350), "center"),
    ("trap", "arrow_trap", "arrow_trap", "aim", 0, (100, 275, 175, 350), "center"),
    ("trap", "arrow_trap", "arrow_trap", "shoot", 0, (190, 275, 265, 350), "center"),
    ("trap", "arrow_trap", "arrow_trap", "arrow_proj", 0, (280, 275, 375, 350), "center"),
    ("trap", "arrow_trap", "arrow_trap", "retract", 0, (390, 275, 460, 350), "center"),

    # Spear Launcher
    ("trap", "spear_launcher", "spear_launcher", "idle", 0, (485, 275, 575, 350), "center"),
    ("trap", "spear_launcher", "spear_launcher", "charge", 0, (585, 275, 685, 350), "center"),
    ("trap", "spear_launcher", "spear_launcher", "launch", 0, (695, 275, 795, 350), "center"),
    ("trap", "spear_launcher", "spear_launcher", "spear_proj", 0, (805, 275, 925, 350), "center"),
    ("trap", "spear_launcher", "spear_launcher", "retract", 0, (935, 275, 1010, 350), "center"),

    # Falling Rock
    ("trap", "falling_rock", "falling_rock", "idle", 0, (15, 388, 80, 495), "top"),
    ("trap", "falling_rock", "falling_rock", "crack", 0, (88, 388, 155, 495), "top"),
    ("trap", "falling_rock", "falling_rock", "fall", 0, (162, 388, 230, 495), "top"),
    ("trap", "falling_rock", "falling_rock", "fall", 1, (235, 388, 300, 495), "top"),
    ("trap", "falling_rock", "falling_rock", "impact", 0, (302, 388, 380, 495), "bottom"),
    ("trap", "falling_rock", "falling_rock", "reset", 0, (382, 388, 450, 495), "top"),

    # Rolling Boulder
    ("trap", "rolling_boulder", "rolling_boulder", "idle", 0, (480, 388, 585, 495), "bottom"),
    ("trap", "rolling_boulder", "rolling_boulder", "roll", 0, (588, 388, 690, 495), "bottom"),
    ("trap", "rolling_boulder", "rolling_boulder", "roll", 1, (693, 388, 795, 495), "bottom"),
    ("trap", "rolling_boulder", "rolling_boulder", "roll", 2, (798, 388, 900, 495), "bottom"),
    ("trap", "rolling_boulder", "rolling_boulder", "roll", 3, (903, 388, 1005, 495), "bottom"),

    # Guillotine
    ("trap", "guillotine", "guillotine", "idle", 0, (15, 535, 80, 650), "top"),
    ("trap", "guillotine", "guillotine", "drop", 0, (85, 535, 145, 650), "top"),
    ("trap", "guillotine", "guillotine", "drop", 1, (150, 535, 210, 650), "top"),
    ("trap", "guillotine", "guillotine", "full", 0, (218, 535, 272, 650), "top"),
    ("trap", "guillotine", "guillotine", "reset", 0, (280, 535, 340, 650), "top"),

    # Fire Trap
    ("trap", "fire_trap", "fire_trap", "idle", 0, (360, 535, 422, 650), "center"),
    ("trap", "fire_trap", "fire_trap", "charge", 0, (425, 535, 480, 650), "center"),
    ("trap", "fire_trap", "fire_trap", "flame", 0, (485, 535, 538, 650), "bottom"),
    ("trap", "fire_trap", "fire_trap", "flame", 1, (545, 535, 598, 650), "bottom"),
    ("trap", "fire_trap", "fire_trap", "off", 0, (602, 535, 645, 650), "center"),

    # Extra Projectiles
    ("trap", "projectiles", "extra", "knife", 0, (660, 535, 708, 645), "center"),
    ("trap", "projectiles", "extra", "spear", 0, (715, 535, 750, 645), "center"),
    ("trap", "projectiles", "extra", "fireball", 0, (755, 535, 825, 645), "center"),
    ("trap", "projectiles", "extra", "dart", 0, (830, 535, 865, 645), "center"),
    ("trap", "projectiles", "extra", "spike_ball", 0, (870, 535, 922, 645), "center"),
    ("trap", "projectiles", "extra", "chain_blade", 0, (928, 535, 1005, 645), "center"),
]

def remove_black_background(img_crop):
    """Converts pure/near black pixels to true transparent alpha with edge smoothing."""
    arr = np.array(img_crop.convert("RGBA"), dtype=np.float32)
    rgb = arr[:, :, :3]
    # Max channel brightness
    max_b = np.max(rgb, axis=2)
    
    # Below 12 is transparent, between 12 and 36 ramp alpha, above 36 full
    alpha = np.zeros_like(max_b)
    low_thresh = 12.0
    high_thresh = 36.0
    
    ramp_mask = (max_b >= low_thresh) & (max_b < high_thresh)
    alpha[ramp_mask] = ((max_b[ramp_mask] - low_thresh) / (high_thresh - low_thresh)) * 255.0
    alpha[max_b >= high_thresh] = 255.0
    
    arr[:, :, 3] = alpha
    return Image.fromarray(np.uint8(arr))

def trim_transparent(img, padding=2):
    """Trims transparent borders, leaving a tiny padding."""
    arr = np.array(img)
    alpha = arr[:, :, 3] > 10
    if not np.any(alpha):
        return img, (0, 0, img.width, img.height)
    ys, xs = np.where(alpha)
    y0 = max(0, int(ys.min()) - padding)
    y1 = min(img.height, int(ys.max()) + 1 + padding)
    x0 = max(0, int(xs.min()) - padding)
    x1 = min(img.width, int(xs.max()) + 1 + padding)
    trimmed = img.crop((x0, y0, x1, y1))
    return trimmed, (x0, y0, x1, y1)

def main():
    sheets = {
        "hero": Image.open(HERO_SHEET),
        "enemy": Image.open(ENEMY_SHEET),
        "trap": Image.open(TRAP_SHEET),
    }

    manifest = {"sprites": []}
    preview_items = []

    print(f"Loaded sheets: Hero={sheets['hero'].size}, Enemy={sheets['enemy'].size}, Trap={sheets['trap'].size}")

    for entry in REGIONS:
        sheet_key, category, subfolder, anim_name, frame_idx, bbox, align_mode = entry
        sheet = sheets[sheet_key]
        x0, y0, x1, y1 = bbox
        crop = sheet.crop((x0, y0, x1, y1))

        if sheet_key in ("enemy", "trap"):
            processed = remove_black_background(crop)
        else:
            # Hero is already RGBA with transparent bg
            processed = crop.convert("RGBA")

        trimmed, trim_box = trim_transparent(processed, padding=2)

        # Output folder logic
        if category == "hero":
            out_dir = OUT_HERO
            file_name = f"hero_{anim_name}_{frame_idx}.png"
        elif category in ("ronin", "archer", "spear", "brute"):
            out_dir = os.path.join(OUT_ENEMIES, subfolder)
            file_name = f"{category}_{anim_name}_{frame_idx}.png"
        elif category == "fx":
            out_dir = OUT_FX
            file_name = f"fx_{anim_name}_{frame_idx}.png"
        else:
            out_dir = os.path.join(OUT_TRAPS, subfolder)
            file_name = f"{category}_{anim_name}_{frame_idx}.png"

        os.makedirs(out_dir, exist_ok=True)
        file_path = os.path.join(out_dir, file_name)
        trimmed.save(file_path, "PNG")

        rel_path = os.path.relpath(file_path, BASE_DIR).replace("\\", "/")

        # Calculate pivot
        w, h = trimmed.size
        if align_mode == "bottom":
            pivot = (w // 2, h)
        elif align_mode == "top":
            pivot = (w // 2, 0)
        else:
            pivot = (w // 2, h // 2)

        meta = {
            "name": f"{category}_{anim_name}_{frame_idx}",
            "file": rel_path,
            "category": category,
            "animation": anim_name,
            "frame": frame_idx,
            "sheet": sheet_key,
            "source_rect": list(bbox),
            "size": [w, h],
            "pivot": list(pivot),
            "alignment": align_mode
        }
        manifest["sprites"].append(meta)
        preview_items.append((meta["name"], trimmed))

    # Save manifest
    manifest_path = os.path.join(BASE_DIR, "assets", "sprites", "sprite_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)
    print(f"Manifest written with {len(manifest['sprites'])} sprites: {manifest_path}")

    # Generate Contact Sheet Preview PNG
    # Grid of sprites: e.g. 10 columns, with labels
    cols = 8
    cell_w = 130
    cell_h = 130
    rows = (len(preview_items) + cols - 1) // cols
    sheet_w = cols * cell_w
    sheet_h = rows * cell_h

    # Dark checkered background
    preview_img = Image.new("RGBA", (sheet_w, sheet_h), (18, 18, 22, 255))
    draw = ImageDraw.Draw(preview_img)

    # Checker pattern
    for cy in range(0, sheet_h, 16):
        for cx in range(0, sheet_w, 16):
            if (cx // 16 + cy // 16) % 2 == 1:
                draw.rectangle([cx, cy, cx+15, cy+15], fill=(26, 26, 32, 255))

    try:
        font = ImageFont.load_default()
    except Exception:
        font = None

    for i, (name, sprite_img) in enumerate(preview_items):
        c = i % cols
        r = i // cols
        cx = c * cell_w
        cy = r * cell_h

        # Draw cell outline
        draw.rectangle([cx, cy, cx + cell_w - 1, cy + cell_h - 1], outline=(50, 50, 60, 255))

        # Center sprite in cell upper area (height 95)
        sw, sh = sprite_img.size
        scale = min(1.0, 90.0 / max(sw, sh))
        if scale < 1.0:
            target_size = (max(1, int(sw * scale)), max(1, int(sh * scale)))
            display_sprite = sprite_img.resize(target_size, Image.Resampling.LANCZOS)
        else:
            display_sprite = sprite_img

        dw, dh = display_sprite.size
        px = cx + (cell_w - dw) // 2
        py = cy + 10 + (85 - dh) // 2

        # Paste sprite with alpha mask
        preview_img.paste(display_sprite, (px, py), display_sprite)

        # Label at bottom
        display_name = name
        if len(display_name) > 18:
            display_name = display_name[:17] + ".."
        draw.text((cx + 6, cy + cell_h - 22), display_name, fill=(220, 220, 220, 255), font=font)
        draw.text((cx + 6, cy + cell_h - 11), f"{sw}x{sh}", fill=(140, 140, 150, 255), font=font)

    contact_path = os.path.join(DOCS_DIR, "contact_sheet_preview.png")
    preview_img.save(contact_path, "PNG")
    print(f"Contact sheet preview saved: {contact_path}")

if __name__ == "__main__":
    main()
