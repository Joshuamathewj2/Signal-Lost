class_name RevealTextureFactory
extends RefCounted

static var _cached_texture: ImageTexture = null

static func get_texture() -> ImageTexture:
	if _cached_texture != null:
		return _cached_texture

	var size: int = 512
	var half: float = float(size) * 0.5
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)

	for y in range(size):
		var dy: float = (float(y) + 0.5 - half)
		for x in range(size):
			var dx: float = (float(x) + 0.5 - half)
			var dist: float = sqrt(dx * dx + dy * dy)
			var d: float = dist / half

			var v: float = 0.0
			if d <= 0.82:
				v = 1.0
			elif d <= 1.0:
				v = 1.0 - smoothstep(0.82, 1.0, d)
			else:
				v = 0.0

			# Subtle 4% darker 2px band around d = 0.80 (2px out of 256px is delta ≈ 0.008)
			if absf(d - 0.80) <= 0.008:
				v *= 0.96

			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, v))

	_cached_texture = ImageTexture.create_from_image(img)
	return _cached_texture
