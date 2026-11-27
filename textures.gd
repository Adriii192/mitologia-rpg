extends RefCounted

# Texturas generadas por codigo: color + relieve (normal map) + brillo.
# La primera vez se generan y se guardan en el movil; despues se cargan al instante.

const VERSION := "t3"
const N := 128

static var _tex: Dictionary = {}
static var _mats: Dictionary = {}
static var _hb: PackedFloat32Array = PackedFloat32Array()
static var _hv: float = 0.5


static func _h(x: int, y: int, s: int) -> float:
	var n: int = x * 374761393 + y * 668265263 + s * 1442695041
	n = (n ^ (n >> 13)) * 1274126177
	n = n ^ (n >> 16)
	return float(n & 0xFFFF) / 65535.0


# Ruido de valor periodico (sin costuras). cx, cy = celdas en cada eje.
static func _pn(x: int, y: int, cx: int, cy: int, s: int) -> float:
	var u: float = float(x) / float(N) * float(cx)
	var v: float = float(y) / float(N) * float(cy)
	var xi: int = floori(u)
	var yi: int = floori(v)
	var fx: float = u - float(xi)
	var fy: float = v - float(yi)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var x0: int = posmod(xi, cx)
	var x1: int = posmod(xi + 1, cx)
	var y0: int = posmod(yi, cy)
	var y1: int = posmod(yi + 1, cy)
	return lerpf(lerpf(_h(x0, y0, s), _h(x1, y0, s), fx), lerpf(_h(x0, y1, s), _h(x1, y1, s), fx), fy)


static func _fb(x: int, y: int, c: int, s: int) -> float:
	return _pn(x, y, c, c, s) * 0.55 + _pn(x, y, c * 2, c * 2, s + 1) * 0.3 + _pn(x, y, c * 4, c * 4, s + 2) * 0.15


static func _c(r: float, g: float, b: float, v: float) -> Color:
	return Color(clampf(r * v, 0.0, 1.0), clampf(g * v, 0.0, 1.0), clampf(b * v, 0.0, 1.0))


# Devuelve el color y deja la altura (relieve) en _hv
static func _px(name: String, x: int, y: int) -> Color:
	_hv = 0.5
	if name == "wood":
		var row: int = y / 32
		var py: int = y % 32
		var j: int = int(_h(row, 0, 3) * float(N))
		var xx: int = (x + j) % N
		var piece: int = xx / 64
		var tone: float = 0.8 + 0.35 * _h(row, piece, 5)
		var mix: float = _h(row, piece, 6)
		var grain: float = _pn(x, y, 3, 20, 9)
		var fine: float = _pn(x, y, 8, 64, 10)
		var ring: float = 0.5 + 0.5 * sin((float(y) * 0.45 + grain * 9.0 + float(row) * 3.0))
		var v: float = tone * (0.82 + 0.22 * grain + 0.1 * fine + 0.07 * ring)
		_hv = 0.55 + 0.2 * grain + 0.1 * fine
		if py == 0 or xx == 0 or xx == 64:
			v *= 0.42
			_hv = 0.0
		elif py == 1 or xx == 1 or xx == 65:
			v *= 0.78
			_hv = 0.3
		return _c(lerpf(0.55, 0.74, mix), lerpf(0.36, 0.52, mix), lerpf(0.2, 0.3, mix), v)
	if name == "plaster":
		var f: float = _fb(x, y, 4, 1)
		var sp: float = _h(x, y, 2)
		var v2: float = 0.93 + (f - 0.5) * 0.12 + (sp - 0.5) * 0.04
		_hv = f * 0.6 + sp * 0.25
		return Color(v2, v2, v2)
	if name == "siding":
		var py2: int = y % 16
		var gr: float = _pn(x, y, 2, 36, 11)
		var v3: float = 0.95 + (gr - 0.5) * 0.14 + (_fb(x, y, 3, 12) - 0.5) * 0.06
		_hv = float(py2) / 16.0
		if py2 < 2:
			v3 *= 0.55
			_hv = 0.0
		elif py2 > 13:
			v3 *= 0.85
		return Color(v3, v3, v3)
	if name == "carpet":
		var fib: float = _h(x, y, 4)
		var low: float = _fb(x, y, 6, 5)
		var v4: float = 0.74 + fib * 0.16 + (low - 0.5) * 0.14
		_hv = fib * 0.7 + low * 0.3
		return Color(v4, v4, v4)
	if name == "tile":
		var gx: int = x % 32
		var gy: int = y % 32
		var tidx: int = (x / 32) * 7 + (y / 32) * 13
		if gx < 2 or gy < 2:
			_hv = 0.0
			return Color(0.45, 0.45, 0.48)
		var vein: float = absf(sin(float(x + y) * 0.09 + _fb(x, y, 4, 20) * 7.0))
		var v5: float = 0.9 + (_h(tidx, 1, 6) - 0.5) * 0.12 - 0.12 * pow(1.0 - vein, 6.0)
		if ((x / 32) + (y / 32)) % 2 == 1:
			v5 *= 0.9
		_hv = 0.8
		if gx < 4 or gy < 4:
			_hv = 0.5
			v5 *= 0.93
		return Color(v5, v5 * 0.99, v5 * 0.98)
	if name == "grass":
		var patch: float = _fb(x, y, 3, 6)
		var blades: float = _pn(x, y, 48, 5, 7)
		var tips: float = _h(x, y, 8)
		var v6: float = 0.7 + patch * 0.5 + (blades - 0.5) * 0.35 + (tips - 0.5) * 0.12
		_hv = blades * 0.7 + tips * 0.3
		return _c(lerpf(0.2, 0.42, patch), lerpf(0.42, 0.62, patch), lerpf(0.12, 0.16, patch), v6)
	if name == "roof":
		var row2: int = y / 16
		var py3: int = y % 16
		var shift: int = (row2 % 2) * 16
		var xs: int = (x + shift) % N
		var idx: int = xs / 32
		var sx: int = xs % 32
		var tone2: float = 0.7 + 0.35 * _h(idx, row2, 8)
		var moss: float = _fb(x, y, 3, 30)
		var v7: float = tone2 * (0.9 + (_h(x, y, 31) - 0.5) * 0.12)
		_hv = float(py3) / 16.0
		var edge: float = minf(float(sx), float(31 - sx))
		if py3 < 2 or sx < 2:
			v7 *= 0.5
			_hv = 0.0
		elif py3 > 12:
			v7 *= 0.82
		if edge < 3.0:
			v7 *= 0.85
		var r: float = 0.46
		var g: float = 0.34
		var b: float = 0.32
		if moss > 0.66:
			r = 0.32
			g = 0.42
			b = 0.26
		return _c(r, g, b, v7)
	if name == "concrete":
		var f2: float = _fb(x, y, 5, 12)
		var crack: float = absf(_fb(x, y, 4, 20) - 0.5)
		var v8: float = 0.68 + f2 * 0.2 + (_h(x, y, 13) - 0.5) * 0.14
		_hv = f2 * 0.5 + _h(x, y, 14) * 0.3
		if crack < 0.012:
			v8 *= 0.5
			_hv = 0.0
		return Color(v8, v8, v8 * 1.02)
	if name == "sand":
		var f3: float = _fb(x, y, 4, 40)
		var rip: float = 0.5 + 0.5 * sin(float(y) * 0.35 + f3 * 9.0)
		var spk: float = _h(x, y, 41)
		var v9: float = 0.88 + f3 * 0.14 + rip * 0.07 + (spk - 0.5) * 0.1
		_hv = rip * 0.5 + spk * 0.3
		return _c(0.92, 0.8, 0.58, v9)
	if name == "rock":
		var f4: float = _fb(x, y, 4, 50)
		var f5: float = _fb(x, y, 8, 53)
		var crack2: float = absf(_fb(x, y, 5, 60) - 0.5)
		var v10: float = 0.55 + f4 * 0.4 + (f5 - 0.5) * 0.2
		_hv = f4 * 0.7 + f5 * 0.3
		if crack2 < 0.02:
			v10 *= 0.55
			_hv = 0.0
		return _c(0.62, 0.58, 0.54, v10)
	if name == "bark":
		var st: float = _pn(x, y, 9, 3, 70)
		var st2: float = _pn(x, y, 18, 6, 72)
		var v11: float = 0.45 + st * 0.45 + (st2 - 0.5) * 0.2
		_hv = st * 0.7 + st2 * 0.3
		if st < 0.3:
			v11 *= 0.5
		return _c(0.42, 0.29, 0.18, v11)
	if name == "dirt":
		var f6: float = _fb(x, y, 4, 80)
		var peb: float = _h(x / 3, y / 3, 83)
		var v12: float = 0.75 + f6 * 0.3
		_hv = f6 * 0.6
		if peb > 0.93:
			v12 *= 1.25
			_hv = 1.0
		return _c(0.5, 0.36, 0.24, v12)
	return Color(0.7, 0.7, 0.7)


static func _path(name: String, kind: String) -> String:
	return "user://tex_%s_%s_%s.png" % [VERSION, name, kind]


static func _to_tex(img: Image) -> ImageTexture:
	if not img.has_mipmaps():
		img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# Devuelve [color, normal]
static func tex(name: String) -> Array:
	if _tex.has(name):
		return _tex[name]
	var res: Array = []
	var cp: String = _path(name, "c")
	var np: String = _path(name, "n")
	if FileAccess.file_exists(cp) and FileAccess.file_exists(np):
		var ci: Image = Image.load_from_file(cp)
		var ni: Image = Image.load_from_file(np)
		if ci != null and ni != null and ci.get_width() == N and ni.get_width() == N:
			res = [_to_tex(ci), _to_tex(ni)]
	if res.is_empty():
		var img := Image.create(N, N, false, Image.FORMAT_RGB8)
		_hb.resize(N * N)
		for y in N:
			for x in N:
				img.set_pixel(x, y, _px(name, x, y))
				_hb[y * N + x] = _hv
		var nrm := Image.create(N, N, false, Image.FORMAT_RGB8)
		for y2 in N:
			for x2 in N:
				var dx: float = _hb[y2 * N + (x2 + 1) % N] - _hb[y2 * N + posmod(x2 - 1, N)]
				var dy: float = _hb[((y2 + 1) % N) * N + x2] - _hb[posmod(y2 - 1, N) * N + x2]
				var nv := Vector3(-dx * 2.2, dy * 2.2, 1.0).normalized()
				nrm.set_pixel(x2, y2, Color(nv.x * 0.5 + 0.5, nv.y * 0.5 + 0.5, nv.z * 0.5 + 0.5))
		img.save_png(cp)
		nrm.save_png(np)
		res = [_to_tex(img), _to_tex(nrm)]
	_tex[name] = res
	return res


static func _nscale(name: String) -> float:
	if name == "plaster":
		return 0.25
	if name == "carpet" or name == "concrete":
		return 0.5
	if name == "grass" or name == "siding" or name == "sand":
		return 0.6
	return 0.9


static func _rough(name: String) -> float:
	if name == "tile":
		return 0.3
	if name == "wood":
		return 0.55
	if name == "siding":
		return 0.75
	if name == "roof":
		return 0.8
	return 0.95


# tile = metros que mide una repeticion de la textura
static func mat(name: String, tint: Color = Color(1, 1, 1), tile: float = 2.0) -> StandardMaterial3D:
	var key: String = "%s|%s|%s" % [name, tint.to_html(), str(tile)]
	if _mats.has(key):
		return _mats[key]
	var t: Array = tex(name)
	var m := StandardMaterial3D.new()
	m.albedo_texture = t[0]
	m.albedo_color = tint
	m.normal_enabled = true
	m.normal_texture = t[1]
	m.normal_scale = _nscale(name)
	m.roughness = _rough(name)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	var s: float = 1.0 / tile
	m.uv1_scale = Vector3(s, s, s)
	_mats[key] = m
	return m
