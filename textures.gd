extends RefCounted

# Texturas generadas por codigo (sin imagenes externas).

static var _tex: Dictionary = {}
static var _mats: Dictionary = {}


static func _h(x: int, y: int, s: int) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 1442695041
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


static func _vn(x: float, y: float, s: int) -> float:
	var xi: int = floori(x)
	var yi: int = floori(y)
	var fx: float = x - float(xi)
	var fy: float = y - float(yi)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a: float = _h(xi, yi, s)
	var b: float = _h(xi + 1, yi, s)
	var c: float = _h(xi, yi + 1, s)
	var d: float = _h(xi + 1, yi + 1, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func _px(name: String, x: int, y: int, n: int) -> Color:
	if name == "wood":
		var plank: int = y / 16
		var py: int = y % 16
		var j: int = int(_h(plank, 0, 3) * float(n))
		var piece: int = ((x + j) % n) / 64
		var tone: float = 0.82 + 0.3 * _h(plank, piece, 5)
		var grain: float = (_vn(float(x) * 0.12, float(y) * 1.1 + float(plank) * 7.0, 9) - 0.5) * 0.18
		var v: float = tone + grain
		if py == 0 or x == j or x == (j + 64) % n:
			v *= 0.55
		return Color(0.66 * v, 0.46 * v, 0.28 * v)
	if name == "plaster":
		var v2: float = 0.95 + (_vn(float(x) * 0.4, float(y) * 0.4, 1) - 0.5) * 0.07 + (_h(x, y, 2) - 0.5) * 0.025
		return Color(v2, v2, v2)
	if name == "siding":
		var py2: int = y % 16
		var v3: float = 0.97 + (_vn(float(x) * 0.05, float(y) * 0.9, 11) - 0.5) * 0.06
		if py2 < 2:
			v3 *= 0.72
		return Color(v3, v3, v3)
	if name == "carpet":
		var v4: float = 0.8 + _h(x, y, 4) * 0.2
		return Color(v4, v4, v4)
	if name == "tile":
		var gx: int = x % 32
		var gy: int = y % 32
		if gx < 2 or gy < 2:
			return Color(0.5, 0.5, 0.52)
		var v5: float = 0.95
		if ((x / 32) + (y / 32)) % 2 == 1:
			v5 = 0.82
		v5 += (_h(x, y, 6) - 0.5) * 0.03
		return Color(v5, v5, v5)
	if name == "grass":
		var g: float = _vn(float(x) * 0.18, float(y) * 0.18, 6) * 0.35 + _h(x, y, 7) * 0.15
		return Color(0.25 + g * 0.3, 0.5 + g * 0.4, 0.2 + g * 0.15)
	if name == "roof":
		var row: int = y / 16
		var py3: int = y % 16
		var shift: int = (row % 2) * 16
		var idx: int = (x + shift) / 32
		var tone2: float = 0.72 + 0.3 * _h(idx, row, 8)
		var v6: float = tone2
		if py3 < 2 or (x + shift) % 32 < 2:
			v6 *= 0.6
		return Color(0.46 * v6, 0.34 * v6, 0.32 * v6)
	# concrete
	var v7: float = 0.72 + (_vn(float(x) * 0.3, float(y) * 0.3, 12) - 0.5) * 0.2 + (_h(x, y, 13) - 0.5) * 0.06
	return Color(v7, v7, v7)


static func tex(name: String) -> ImageTexture:
	if _tex.has(name):
		return _tex[name]
	var n: int = 128
	var img := Image.create(n, n, false, Image.FORMAT_RGB8)
	for y in n:
		for x in n:
			img.set_pixel(x, y, _px(name, x, y, n))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_tex[name] = t
	return t


# tile = metros que mide una repeticion de la textura
static func mat(name: String, tint: Color = Color(1, 1, 1), tile: float = 2.0) -> StandardMaterial3D:
	var key: String = "%s|%s|%s" % [name, tint.to_html(), str(tile)]
	if _mats.has(key):
		return _mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex(name)
	m.albedo_color = tint
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	var s: float = 1.0 / tile
	m.uv1_scale = Vector3(s, s, s)
	_mats[key] = m
	return m
