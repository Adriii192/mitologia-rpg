extends RefCounted

# Casa de Aris: dos plantas, estilo americano. Todo se construye por codigo.
# Planta: x de -14 a 14, z de -14 (fondo) a 14 (fachada). Porche por delante.

const Tex = preload("res://textures.gd")
const Companion = preload("res://companion.gd")
const Zones = preload("res://zones.gd")

const H1 := 4.6    # suelo de la planta alta
const TOP := 8.6   # techo de la planta alta
const WT := 0.3    # grosor de paredes
const DOOR_H := 3.2


static func _bm(size: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = m
	return mi


static func solid(root: Node3D, pos: Vector3, size: Vector3, m: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	body.add_child(_bm(size, m))
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	root.add_child(body)
	return body


static func deco(root: Node3D, pos: Vector3, size: Vector3, m: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := _bm(size, m)
	mi.position = pos
	mi.rotation_degrees = rot
	root.add_child(mi)
	return mi


static func fab(c: Color) -> StandardMaterial3D:
	return Tex.mat("carpet", c, 0.6)


static func col(c: Color, emission: float = 0.0) -> StandardMaterial3D:
	return Zones.mat(c, emission)


# Mueble: caja con la base en y0.
static func fb(root: Node3D, x: float, z: float, w: float, d: float, h: float, m: Material, y0: float = 0.0) -> StaticBody3D:
	return solid(root, Vector3(x, y0 + h * 0.5, z), Vector3(w, h, d), m)


static func _seg(root: Node3D, fixed: float, a: float, b: float, y0: float, y1: float, m: Material, along_z: bool) -> void:
	var mid: float = (a + b) * 0.5
	var ln: float = b - a
	var h: float = y1 - y0
	if along_z:
		solid(root, Vector3(fixed, y0 + h * 0.5, mid), Vector3(WT, h, ln), m)
	else:
		solid(root, Vector3(mid, y0 + h * 0.5, fixed), Vector3(ln, h, WT), m)


# gaps: [centro, ancho, alto(opcional)]
static func _wall(root: Node3D, fixed: float, a: float, b: float, y0: float, y1: float, gaps: Array, m: Material, along_z: bool) -> void:
	var items: Array = gaps.duplicate()
	items.sort_custom(func(p, q): return p[0] < q[0])
	var cursor: float = a
	for g in items:
		var c: float = g[0]
		var w: float = g[1]
		var gh: float = DOOR_H
		if g.size() > 2:
			gh = g[2]
		var lo: float = c - w * 0.5
		var hi: float = c + w * 0.5
		if lo > cursor + 0.01:
			_seg(root, fixed, cursor, lo, y0, y1, m, along_z)
		if y1 - y0 > gh + 0.05:
			_seg(root, fixed, lo, hi, y0 + gh, y1, m, along_z)
		cursor = hi
	if b > cursor + 0.01:
		_seg(root, fixed, cursor, b, y0, y1, m, along_z)


static func wall_z(root: Node3D, x: float, z0: float, z1: float, y0: float, y1: float, gaps: Array, m: Material) -> void:
	_wall(root, x, z0, z1, y0, y1, gaps, m, true)


static func wall_x(root: Node3D, z: float, x0: float, x1: float, y0: float, y1: float, gaps: Array, m: Material) -> void:
	_wall(root, z, x0, x1, y0, y1, gaps, m, false)


static func pad(root: Node3D, x0: float, x1: float, z0: float, z1: float, y: float, m: Material) -> void:
	deco(root, Vector3((x0 + x1) * 0.5, y + 0.02, (z0 + z1) * 0.5), Vector3(x1 - x0, 0.04, z1 - z0), m)


static func win(root: Node3D, x: float, y: float, z: float, along_x: bool, w: float, h: float) -> void:
	var pane: StandardMaterial3D = col(Color(0.55, 0.7, 0.95), 0.9)
	var frame: StandardMaterial3D = col(Color(0.95, 0.95, 0.92))
	if along_x:
		deco(root, Vector3(x, y, z), Vector3(w + 0.3, h + 0.3, 0.34), frame)
		deco(root, Vector3(x, y, z), Vector3(w, h, 0.4), pane)
	else:
		deco(root, Vector3(x, y, z), Vector3(0.34, h + 0.3, w + 0.3), frame)
		deco(root, Vector3(x, y, z), Vector3(0.4, h, w), pane)


static func lamp(root: Node3D, pos: Vector3, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = Color(1.0, 0.85, 0.62)
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	root.add_child(l)
	deco(root, pos + Vector3(0, 0.45, 0), Vector3(0.7, 0.08, 0.7), col(Color(1.0, 0.92, 0.7), 1.5))


static func chair(root: Node3D, x: float, z: float, dx: float, dz: float, y0: float = 0.0) -> void:
	var wood: StandardMaterial3D = Tex.mat("wood", Color(0.8, 0.6, 0.45), 2.4)
	fb(root, x, z, 0.5, 0.5, 0.5, wood, y0)
	if absf(dx) > 0.5:
		fb(root, x - dx * 0.21, z, 0.08, 0.5, 0.9, wood, y0 + 0.5)
	else:
		fb(root, x, z - dz * 0.21, 0.5, 0.08, 0.9, wood, y0 + 0.5)


static func table(root: Node3D, x: float, z: float, w: float, d: float, h: float, m: Material, y0: float = 0.0) -> void:
	fb(root, x, z, w, d, 0.1, m, y0 + h - 0.1)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			fb(root, x + sx * (w * 0.5 - 0.12), z + sz * (d * 0.5 - 0.12), 0.12, 0.12, h - 0.1, m, y0)


static func bed(root: Node3D, x: float, z: float, w: float, d: float, y0: float, blanket: Color, along_x: bool = true, head: float = 1.0) -> void:
	var wood: StandardMaterial3D = Tex.mat("wood", Color(0.75, 0.55, 0.4), 2.4)
	if along_x:
		fb(root, x, z, w, d, 0.45, wood, y0)
		fb(root, x, z, w - 0.2, d - 0.15, 0.22, fab(blanket), y0 + 0.45)
		fb(root, x + head * (w * 0.5 - 0.1), z, 0.15, d + 0.1, 1.1, wood, y0)
		fb(root, x + head * (w * 0.5 - 0.45), z, 0.5, d * 0.7, 0.16, col(Color(0.95, 0.95, 0.95)), y0 + 0.67)
	else:
		fb(root, x, z, w, d, 0.45, wood, y0)
		fb(root, x, z, w - 0.15, d - 0.2, 0.22, fab(blanket), y0 + 0.45)


static func bookshelf(root: Node3D, cx: float, z: float, wdt: float, y0: float, special: bool) -> Node3D:
	var wood: StandardMaterial3D = Tex.mat("wood", Color(0.7, 0.5, 0.35), 2.4)
	var hgt: float = 2.6
	fb(root, cx - wdt * 0.5, z, 0.08, 0.45, hgt, wood, y0)
	fb(root, cx + wdt * 0.5, z, 0.08, 0.45, hgt, wood, y0)
	for k in 4:
		fb(root, cx, z, wdt, 0.45, 0.06, wood, y0 + float(k) * 0.85)
	deco(root, Vector3(cx, y0 + hgt * 0.5, z - 0.2), Vector3(wdt, hgt, 0.05), col(Color(0.3, 0.2, 0.12)))
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var colors: Array = [Color(0.7, 0.2, 0.2), Color(0.2, 0.4, 0.7), Color(0.3, 0.6, 0.35), Color(0.8, 0.65, 0.2), Color(0.5, 0.3, 0.6), Color(0.85, 0.85, 0.8), Color(0.25, 0.25, 0.3)]
	var sp: Node3D = null
	for level in 3:
		var cursor: float = cx - wdt * 0.5 + 0.18
		var base: float = y0 + 0.08 + float(level) * 0.85
		while cursor < cx + wdt * 0.5 - 0.3:
			var bw: float = rng.randf_range(0.14, 0.26)
			var bh: float = rng.randf_range(0.45, 0.7)
			var c: Color = colors[rng.randi() % colors.size()]
			if special and level == 1 and sp == null and cursor > cx + 0.2:
				sp = Node3D.new()
				sp.name = "SpecialBook"
				sp.position = Vector3(cursor + 0.15, base + 0.37, z + 0.02)
				var bk := _bm(Vector3(0.3, 0.74, 0.32), col(Color(0.08, 0.45, 0.5), 0.5))
				sp.add_child(bk)
				var gl := _bm(Vector3(0.32, 0.12, 0.34), col(Color(1.0, 0.85, 0.35), 2.0))
				gl.position = Vector3(0, 0.1, 0)
				sp.add_child(gl)
				root.add_child(sp)
				cursor += 0.34
				continue
			deco(root, Vector3(cursor + bw * 0.5, base + bh * 0.5, z + 0.02), Vector3(bw, bh, 0.32), col(c))
			cursor += bw + 0.02
	return sp


static func person_with_talk(root: Node3D, c: Color, label: String, id: String, pos: Vector3, yaw: float) -> Node3D:
	var p: Node3D = Companion.person(c, label)
	p.position = pos
	p.rotation.y = yaw
	root.add_child(p)
	var n := Node3D.new()
	n.add_to_group("portals")
	n.set_meta("action", "talk")
	n.set_meta("id", id)
	n.set_meta("button", "HABLAR")
	n.position = Vector3(0, 0.4, 0)
	p.add_child(n)
	return p


static func _carp(root: Node3D, pos: Vector3, size: Vector3, c: Color, emission: float = 0.0, metal: bool = false) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = emission
	if metal:
		m.metallic = 0.6
		m.roughness = 0.3
	var mi := _bm(size, m)
	mi.position = pos
	root.add_child(mi)


# Coche rojo (frente hacia +X)
static func car(root: Node3D, pos: Vector3) -> void:
	var c := Node3D.new()
	c.position = pos
	root.add_child(c)
	var paint: Color = Color(0.75, 0.1, 0.12)
	var glass: Color = Color(0.12, 0.18, 0.28)
	_carp(c, Vector3(0, 0.62, 0), Vector3(4.6, 0.55, 1.9), paint, 0.0, true)
	_carp(c, Vector3(1.65, 0.97, 0), Vector3(1.3, 0.16, 1.8), paint, 0.0, true)
	_carp(c, Vector3(-1.75, 0.97, 0), Vector3(1.1, 0.16, 1.8), paint, 0.0, true)
	_carp(c, Vector3(-0.15, 1.3, 0), Vector3(2.0, 0.6, 1.7), paint, 0.0, true)
	_carp(c, Vector3(-0.15, 1.34, 0), Vector3(1.8, 0.4, 1.74), glass, 0.15)
	_carp(c, Vector3(-0.15, 1.64, 0), Vector3(1.7, 0.08, 1.74), paint, 0.0, true)
	var ws := _bm(Vector3(0.08, 0.55, 1.6), col(glass, 0.15))
	ws.position = Vector3(0.95, 1.3, 0)
	ws.rotation_degrees = Vector3(0, 0, 35)
	c.add_child(ws)
	var rw := _bm(Vector3(0.08, 0.55, 1.6), col(glass, 0.15))
	rw.position = Vector3(-1.25, 1.3, 0)
	rw.rotation_degrees = Vector3(0, 0, -35)
	c.add_child(rw)
	# pilares
	for pz in [-0.88, 0.88]:
		_carp(c, Vector3(-0.15, 1.35, pz), Vector3(0.12, 0.42, 0.06), paint, 0.0, true)
	_carp(c, Vector3(-0.15, 1.35, 0), Vector3(0.1, 0.42, 1.76), paint, 0.0, true)
	# parachoques, faros, rejilla, retrovisores
	_carp(c, Vector3(2.32, 0.5, 0), Vector3(0.16, 0.22, 1.95), Color(0.2, 0.2, 0.22))
	_carp(c, Vector3(-2.32, 0.5, 0), Vector3(0.16, 0.22, 1.95), Color(0.2, 0.2, 0.22))
	for fz in [-0.65, 0.65]:
		_carp(c, Vector3(2.32, 0.78, fz), Vector3(0.08, 0.15, 0.36), Color(1.0, 0.95, 0.7), 2.0)
		_carp(c, Vector3(-2.32, 0.8, fz), Vector3(0.08, 0.15, 0.36), Color(1.0, 0.1, 0.1), 1.5)
	_carp(c, Vector3(2.32, 0.68, 0), Vector3(0.06, 0.18, 0.8), Color(0.08, 0.08, 0.1))
	for mz in [-1.0, 1.0]:
		_carp(c, Vector3(0.75, 1.12, mz), Vector3(0.14, 0.1, 0.2), paint)
	# rayas de las puertas
	for dz in [-0.96, 0.96]:
		_carp(c, Vector3(-0.15, 0.7, dz), Vector3(0.04, 0.3, 0.02), Color(0.4, 0.05, 0.06))
		_carp(c, Vector3(0.85, 0.62, dz), Vector3(0.02, 0.5, 0.02), Color(0.4, 0.05, 0.06))
	# ruedas con llanta
	for wx in [-1.5, 1.5]:
		for wz in [-1.0, 1.0]:
			var tire := MeshInstance3D.new()
			var tm := CylinderMesh.new()
			tm.top_radius = 0.4
			tm.bottom_radius = 0.4
			tm.height = 0.3
			tire.mesh = tm
			tire.material_override = col(Color(0.06, 0.06, 0.07))
			tire.rotation_degrees = Vector3(90, 0, 0)
			tire.position = Vector3(wx, 0.4, wz)
			c.add_child(tire)
			var rim := MeshInstance3D.new()
			var rm := CylinderMesh.new()
			rm.top_radius = 0.22
			rm.bottom_radius = 0.22
			rm.height = 0.32
			rim.mesh = rm
			rim.material_override = col(Color(0.75, 0.75, 0.8))
			rim.rotation_degrees = Vector3(90, 0, 0)
			rim.position = Vector3(wx, 0.4, wz)
			c.add_child(rim)
	var body := StaticBody3D.new()
	body.position = Vector3(0, 0.85, 0)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(4.6, 1.5, 2.0)
	cs.shape = bs
	body.add_child(cs)
	c.add_child(body)


static func build(root: Node3D) -> Dictionary:
	# ---------- Entorno: atardecer ----------
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.32, 0.6)
	sky_mat.sky_horizon_color = Color(0.98, 0.62, 0.42)
	sky_mat.ground_horizon_color = Color(0.5, 0.4, 0.4)
	sky_mat.ground_bottom_color = Color(0.2, 0.22, 0.2)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.68, 0.7)
	env.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-18, 160, 0)
	sun.light_energy = 0.7
	sun.light_color = Color(1.0, 0.7, 0.5)
	sun.shadow_enabled = false
	root.add_child(sun)

	# ---------- Materiales ----------
	var m_floor: StandardMaterial3D = Tex.mat("wood", Color(1, 1, 1), 2.5)
	var m_plaster: StandardMaterial3D = Tex.mat("plaster", Color(0.94, 0.88, 0.78), 3.0)
	var m_white: StandardMaterial3D = Tex.mat("plaster", Color(0.97, 0.97, 0.95), 3.0)
	var m_ship: StandardMaterial3D = Tex.mat("siding", Color(0.86, 0.9, 0.95), 2.0)
	var m_carpet_a: StandardMaterial3D = Tex.mat("carpet", Color(0.5, 0.62, 0.82), 2.0)
	var m_carpet_b: StandardMaterial3D = Tex.mat("carpet", Color(0.88, 0.8, 0.68), 2.0)
	var m_carpet_c: StandardMaterial3D = Tex.mat("carpet", Color(0.62, 0.62, 0.66), 2.0)
	var m_tile: StandardMaterial3D = Tex.mat("tile", Color(0.92, 0.94, 0.97), 1.6)
	var m_roof: StandardMaterial3D = Tex.mat("roof", Color(1, 1, 1), 2.0)
	var m_grass: StandardMaterial3D = Tex.mat("grass", Color(1, 1, 1), 4.0)
	var m_conc: StandardMaterial3D = Tex.mat("concrete", Color(0.85, 0.85, 0.85), 2.0)
	var wood_dark: StandardMaterial3D = Tex.mat("wood", Color(0.55, 0.4, 0.3), 2.4)
	var wood_mid: StandardMaterial3D = Tex.mat("wood", Color(0.95, 0.8, 0.62), 2.4)

	# ---------- Exterior ----------
	solid(root, Vector3(0, -0.55, 0), Vector3(140, 1, 140), m_grass)
	deco(root, Vector3(0, -0.04, 29.5), Vector3(3.2, 0.02, 21), m_conc)
	deco(root, Vector3(0, -0.03, 47), Vector3(140, 0.02, 12), Tex.mat("concrete", Color(0.35, 0.35, 0.38), 3.0))
	for tp in [Vector3(-22, 0, 28), Vector3(24, 0, 31), Vector3(-30, 0, 8), Vector3(30, 0, -8), Vector3(-26, 0, -22), Vector3(26, 0, -24), Vector3(0, 0, -32)]:
		Zones.tree(root, tp)
	# Porche
	solid(root, Vector3(0, -0.15, 16.6), Vector3(10, 0.3, 5.2), m_floor)
	solid(root, Vector3(0, -0.1, 19.6), Vector3(4, 0.2, 1.0), m_floor)
	for sx in [-4.6, 4.6]:
		var post := MeshInstance3D.new()
		var pm := CylinderMesh.new()
		pm.top_radius = 0.22
		pm.bottom_radius = 0.22
		pm.height = 4.2
		post.mesh = pm
		post.material_override = col(Color(0.96, 0.96, 0.94))
		post.position = Vector3(sx, 2.1, 18.7)
		root.add_child(post)
	deco(root, Vector3(0, 4.35, 16.6), Vector3(10.8, 0.3, 5.6), wood_dark)
	solid(root, Vector3(-3.3, 0.45, 18.8), Vector3(3.0, 0.9, 0.12), col(Color(0.96, 0.96, 0.94)))
	solid(root, Vector3(3.3, 0.45, 18.8), Vector3(3.0, 0.9, 0.12), col(Color(0.96, 0.96, 0.94)))
	lamp(root, Vector3(1.9, 3.2, 14.6), 0.8, 7.0)

	# Muros exteriores (cada planta)
	for lvl in 2:
		var y0: float = 0.0
		var y1: float = 4.2
		if lvl == 1:
			y0 = H1
			y1 = TOP
		var fg: Array = []
		if lvl == 0:
			fg = [[0.0, 2.6, 3.4]]
		wall_x(root, 14.0, -14.15, 14.15, y0, y1, fg, m_ship)
		wall_x(root, -14.0, -14.15, 14.15, y0, y1, [], m_ship)
		wall_z(root, -14.0, -13.85, 13.85, y0, y1, [], m_ship)
		wall_z(root, 14.0, -13.85, 13.85, y0, y1, [], m_ship)

	# Suelo de planta baja y forjado
	solid(root, Vector3(0, -0.5, 0), Vector3(28.3, 1, 28.3), m_floor)
	solid(root, Vector3(-6.375, 4.4, 0), Vector3(15.55, 0.4, 28.3), m_white)
	solid(root, Vector3(9.025, 4.4, 0), Vector3(10.25, 0.4, 28.3), m_white)
	solid(root, Vector3(2.65, 4.4, -9.175), Vector3(2.5, 0.4, 9.95), m_white)
	solid(root, Vector3(2.65, 4.4, 9.825), Vector3(2.5, 0.4, 8.65), m_white)
	# Techo de la planta alta
	solid(root, Vector3(0, 8.8, 0), Vector3(28.3, 0.4, 28.3), m_white)
	# Tejado a dos aguas
	deco(root, Vector3(7.5, 12.95, 0), Vector3(17.0, 0.4, 31.0), m_roof, Vector3(0, 0, -28))
	deco(root, Vector3(-7.5, 12.95, 0), Vector3(17.0, 0.4, 31.0), m_roof, Vector3(0, 0, 28))
	for gz in [-14.15, 14.15]:
		var gable := MeshInstance3D.new()
		var pr := PrismMesh.new()
		pr.size = Vector3(28.6, 7.4, 0.3)
		gable.mesh = pr
		gable.material_override = m_ship
		gable.position = Vector3(0, 12.7, gz)
		root.add_child(gable)

	# ---------- Paredes interiores: planta baja ----------
	wall_z(root, -4.0, -13.85, 13.85, 0.0, 4.2, [[10.0, 5.0, 3.6], [-3.5, 1.8], [-10.5, 2.4]], m_plaster)
	wall_z(root, 4.0, -13.85, 13.85, 0.0, 4.2, [[10.0, 5.0, 3.6], [-9.0, 2.2]], m_plaster)
	wall_x(root, 0.0, -13.85, -4.15, 0.0, 4.2, [[-8.0, 2.0]], m_plaster)
	wall_x(root, -7.0, -13.85, -4.15, 0.0, 4.2, [], m_plaster)
	wall_x(root, 2.0, 4.15, 13.85, 0.0, 4.2, [[9.0, 6.0, 3.4]], m_plaster)
	# ---------- Paredes interiores: planta alta ----------
	wall_z(root, -4.0, -13.85, 13.85, H1, TOP, [[9.0, 2.0]], m_plaster)
	wall_z(root, 4.0, -13.85, 13.85, H1, TOP, [[8.0, 1.9], [-6.0, 1.9], [-10.5, 1.9]], m_plaster)
	wall_x(root, 0.0, -13.85, -4.15, H1, TOP, [[-9.0, 1.8]], m_plaster)
	wall_x(root, -7.0, -13.85, -4.15, H1, TOP, [[-9.0, 1.8]], m_plaster)
	wall_x(root, 0.0, 4.15, 13.85, H1, TOP, [], m_plaster)
	wall_x(root, -7.0, 4.15, 13.85, H1, TOP, [], m_plaster)

	# ---------- Suelos ----------
	pad(root, -4, 4, 4, 14, 0.0, m_tile)            # vestibulo
	pad(root, 4, 14, -14, 2, 0.0, m_tile)           # cocina
	pad(root, -14, -4, -14, -7, 0.0, m_conc)        # garaje
	pad(root, -14, -4, -7, 0, 0.0, m_carpet_c)      # despacho
	pad(root, -4, 1.4, -14, 14, H1, m_floor)        # pasillo alto
	pad(root, 1.4, 4, -14, -4.2, H1, m_floor)
	pad(root, 1.4, 4, 5.5, 14, H1, m_floor)
	pad(root, -14, -4, 0, 14, H1, m_carpet_b)       # padres
	pad(root, -14, -4, -7, 0, H1, m_carpet_b)       # vestidor
	pad(root, -14, -4, -14, -7, H1, m_tile)         # bano padres
	pad(root, 4, 14, 0, 14, H1, m_carpet_a)         # Aris
	pad(root, 4, 14, -7, 0, H1, m_carpet_c)         # invitados
	pad(root, 4, 14, -14, -7, H1, m_tile)           # bano 2

	# ---------- Ventanas ----------
	for wx in [-10.0, -6.0, 6.0, 10.0]:
		win(root, wx, 2.3, 14.0, true, 2.4, 2.0)
		win(root, wx, H1 + 2.3, 14.0, true, 2.4, 2.0)
	win(root, 0.0, H1 + 2.2, 14.0, true, 3.2, 2.6)
	win(root, 8.0, 2.4, -14.0, true, 2.6, 1.6)
	win(root, 0.0, H1 + 2.2, -14.0, true, 3.0, 2.4)
	win(root, 9.0, H1 + 2.4, -14.0, true, 1.6, 1.2)
	win(root, -9.0, H1 + 2.4, -14.0, true, 1.6, 1.2)
	win(root, -14.0, 2.3, 7.0, false, 2.6, 2.0)
	win(root, -14.0, 2.3, -3.5, false, 2.2, 1.8)
	win(root, -14.0, H1 + 2.3, 7.0, false, 2.6, 2.0)
	win(root, 14.0, 2.3, 8.0, false, 2.6, 2.0)
	win(root, 14.0, 2.3, -6.0, false, 2.6, 1.6)
	win(root, 14.0, H1 + 2.3, 7.0, false, 2.6, 2.0)
	win(root, 14.0, H1 + 2.3, -3.5, false, 2.2, 1.8)

	# ---------- Escalera ----------
	var ramp := StaticBody3D.new()
	ramp.position = Vector3(2.7, 2.169, -0.1)
	ramp.rotation_degrees = Vector3(29.3, 0, 0)
	var rcs := CollisionShape3D.new()
	var rbs := BoxShape3D.new()
	rbs.size = Vector3(2.1, 0.3, 9.402)
	rcs.shape = rbs
	ramp.add_child(rcs)
	root.add_child(ramp)
	for i in 10:
		var zc: float = 4.0 - 0.82 * (float(i) + 0.5)
		var th: float = 0.46 * (float(i) + 0.5)
		deco(root, Vector3(2.7, th * 0.5, zc), Vector3(2.1, th, 0.82), wood_mid)
		if i > 0:
			var ch: float = 0.46 * float(i)
			var blk := StaticBody3D.new()
			blk.position = Vector3(2.7, ch * 0.5, zc)
			var bcs := CollisionShape3D.new()
			var bbs := BoxShape3D.new()
			bbs.size = Vector3(2.1, ch, 0.82)
			bcs.shape = bbs
			blk.add_child(bcs)
			root.add_child(blk)
		var rh: float = 0.46 * (float(i) + 1.0) + 1.0
		solid(root, Vector3(1.55, rh * 0.5, zc), Vector3(0.1, rh, 0.82), wood_dark)
	# Barandillas del hueco
	solid(root, Vector3(1.4, H1 + 0.55, 0.65), Vector3(0.1, 1.1, 9.7), wood_dark)
	solid(root, Vector3(2.65, H1 + 0.55, 5.5), Vector3(2.5, 1.1, 0.1), wood_dark)

	# ---------- Vestibulo ----------
	fb(root, -2.8, 13.4, 1.8, 0.5, 0.9, wood_dark)
	deco(root, Vector3(-2.8, 2.0, 13.78), Vector3(1.2, 1.2, 0.04), col(Color(0.75, 0.85, 0.9), 0.4))
	deco(root, Vector3(0, 0.05, 9.0), Vector3(3.0, 0.03, 4.0), fab(Color(0.62, 0.2, 0.2)))
	lamp(root, Vector3(0, 3.5, 9.0), 1.2, 11.0)
	lamp(root, Vector3(0, 3.5, -5.0), 1.1, 11.0)

	# ---------- Salon ----------
	fb(root, -8.4, 5.2, 1.1, 3.4, 0.5, fab(Color(0.3, 0.38, 0.6)))
	fb(root, -7.7, 5.2, 0.3, 3.4, 0.55, fab(Color(0.26, 0.33, 0.55)), 0.5)
	fb(root, -8.4, 10.2, 1.1, 2.0, 0.5, fab(Color(0.3, 0.38, 0.6)))
	fb(root, -7.7, 10.2, 0.3, 2.0, 0.55, fab(Color(0.26, 0.33, 0.55)), 0.5)
	table(root, -10.7, 7.4, 1.2, 2.4, 0.45, wood_dark)
	fb(root, -13.5, 7.4, 0.6, 3.0, 0.6, wood_dark)
	deco(root, Vector3(-13.6, 1.35, 7.4), Vector3(0.12, 1.1, 1.9), col(Color(0.2, 0.45, 0.8), 1.1))
	fb(root, -9.6, 2.0, 1.1, 1.1, 0.5, fab(Color(0.55, 0.3, 0.25)))
	fb(root, -9.2, 1.5, 0.3, 1.0, 0.5, fab(Color(0.5, 0.26, 0.22)), 0.5)
	deco(root, Vector3(-10.6, 0.05, 7.4), Vector3(5.5, 0.03, 6.5), fab(Color(0.75, 0.62, 0.45)))
	bookshelf(root, -11.0, 13.4, 3.6, 0.0, false)
	lamp(root, Vector3(-9.0, 3.4, 7.0), 1.3, 12.0)
	fb(root, -5.0, 13.0, 0.5, 0.5, 0.5, col(Color(0.55, 0.35, 0.2)))
	deco(root, Vector3(-5.0, 1.1, 13.0), Vector3(0.7, 0.9, 0.7), col(Color(0.2, 0.55, 0.25)))
	var papa: Node3D = person_with_talk(root, Color(0.25, 0.5, 0.55), "Papá", "papa", Vector3(-8.4, -0.4, 5.2), -PI * 0.5)

	# ---------- Comedor ----------
	table(root, 9.0, 8.5, 4.4, 1.9, 0.95, wood_mid)
	chair(root, 6.0, 8.5, 1, 0)
	chair(root, 12.0, 8.5, -1, 0)
	chair(root, 9.0, 10.4, 0, -1)
	chair(root, 10.6, 10.4, 0, -1)
	chair(root, 8.0, 6.6, 0, 1)
	chair(root, 10.0, 6.6, 0, 1)
	for px in [7.6, 8.8, 10.0]:
		for pz in [7.8, 9.2]:
			deco(root, Vector3(px, 0.97, pz), Vector3(0.45, 0.03, 0.45), col(Color(0.96, 0.96, 0.94)))
	deco(root, Vector3(9.0, 1.1, 8.5), Vector3(0.6, 0.3, 0.6), col(Color(0.85, 0.35, 0.25)))
	fb(root, 13.5, 8.0, 0.8, 3.5, 1.0, wood_dark)
	lamp(root, Vector3(9.0, 3.3, 8.5), 1.3, 11.0)
	deco(root, Vector3(9.0, 0.05, 8.5), Vector3(6.4, 0.03, 4.0), fab(Color(0.5, 0.33, 0.28)))

	# ---------- Cocina ----------
	fb(root, 8.25, -13.4, 7.5, 1.0, 1.0, col(Color(0.82, 0.82, 0.84)))
	deco(root, Vector3(8.25, 2.7, -13.7), Vector3(7.5, 1.0, 0.6), col(Color(0.9, 0.88, 0.82)))
	deco(root, Vector3(6.5, 1.03, -13.4), Vector3(1.0, 0.06, 0.8), col(Color(0.15, 0.15, 0.17)))
	fb(root, 13.2, -13.2, 1.2, 1.2, 2.0, col(Color(0.88, 0.88, 0.9)))
	fb(root, 13.4, -7.0, 1.0, 6.0, 1.0, col(Color(0.82, 0.82, 0.84)))
	fb(root, 9.0, -6.0, 4.0, 1.6, 1.0, col(Color(0.72, 0.55, 0.4)))
	for sx in [7.9, 9.0, 10.1]:
		fb(root, sx, -4.6, 0.45, 0.45, 0.7, col(Color(0.35, 0.25, 0.2)))
	lamp(root, Vector3(9.0, 3.4, -6.0), 1.3, 12.0)
	deco(root, Vector3(8.25, 0.05, -11.8), Vector3(4.0, 0.03, 1.0), fab(Color(0.2, 0.45, 0.5)))
	deco(root, Vector3(9.0, 0.05, -2.5), Vector3(3.0, 0.03, 1.4), fab(Color(0.7, 0.5, 0.2)))
	var mama: Node3D = person_with_talk(root, Color(0.7, 0.35, 0.55), "Mamá", "mama", Vector3(6.5, 0, -12.2), PI)

	# ---------- Despacho (sala extra) ----------
	table(root, -13.0, -3.5, 1.2, 3.0, 0.8, wood_dark)
	chair(root, -11.7, -3.5, -1, 0)
	bookshelf(root, -8.0, -6.6, 3.6, 0.0, false)
	fb(root, -6.0, -1.5, 1.2, 0.9, 0.5, fab(Color(0.3, 0.38, 0.6)))
	deco(root, Vector3(-13.0, 0.88, -3.5), Vector3(0.5, 0.04, 0.7), col(Color(0.15, 0.15, 0.18)))
	lamp(root, Vector3(-9.0, 3.4, -3.5), 1.0, 9.0)
	deco(root, Vector3(-9.0, 0.05, -3.5), Vector3(4.2, 0.03, 3.6), fab(Color(0.4, 0.25, 0.3)))

	# ---------- Garaje ----------
	car(root, Vector3(-9.0, 0.0, -10.5))
	fb(root, -9.0, -13.5, 6.0, 0.5, 2.0, wood_dark)
	lamp(root, Vector3(-9.0, 3.4, -10.5), 0.9, 10.0)

	# ---------- Planta alta: pasillo ----------
	lamp(root, Vector3(0, H1 + 3.4, 0), 1.1, 12.0)
	lamp(root, Vector3(0, H1 + 3.4, -9.0), 0.9, 10.0)
	fb(root, -3.4, 12.0, 0.5, 2.0, 0.8, wood_dark, H1)
	deco(root, Vector3(-3.4, H1 + 1.3, 12.0), Vector3(0.6, 0.9, 0.6), col(Color(0.2, 0.55, 0.25)))
	deco(root, Vector3(-1.5, H1 + 0.05, 0), Vector3(2.0, 0.03, 20.0), fab(Color(0.55, 0.25, 0.25)))

	# ---------- Habitacion de los padres ----------
	bed(root, -11.9, 7.0, 3.0, 2.4, H1, Color(0.85, 0.82, 0.75), true, -1.0)
	fb(root, -13.2, 5.4, 0.5, 0.5, 0.6, wood_dark, H1)
	fb(root, -13.2, 8.6, 0.5, 0.5, 0.6, wood_dark, H1)
	fb(root, -9.0, 0.6, 2.4, 0.6, 0.9, wood_dark, H1)
	fb(root, -6.0, 12.5, 1.0, 1.0, 0.5, fab(Color(0.5, 0.3, 0.3)), H1)
	deco(root, Vector3(-9.0, H1 + 0.05, 7.0), Vector3(4.5, 0.03, 5.0), fab(Color(0.55, 0.45, 0.4)))
	lamp(root, Vector3(-9.0, H1 + 3.4, 7.0), 1.2, 12.0)
	# Vestidor
	deco(root, Vector3(-9.0, H1 + 0.05, -3.5), Vector3(2.0, 0.03, 5.0), fab(Color(0.6, 0.25, 0.3)))
	fb(root, -13.4, -3.5, 0.6, 6.0, 2.4, wood_dark, H1)
	for k in 8:
		deco(root, Vector3(-13.0, H1 + 1.6, -6.2 + float(k) * 0.65), Vector3(0.1, 1.2, 0.4), col(Color(0.3 + 0.08 * float(k % 4), 0.35, 0.5 - 0.05 * float(k % 3))))
	lamp(root, Vector3(-9.0, H1 + 3.4, -3.5), 0.9, 9.0)
	# Bano de los padres
	fb(root, -12.5, -12.9, 2.2, 1.1, 0.7, col(Color(0.96, 0.96, 0.98)), H1)
	fb(root, -9.5, -13.3, 0.6, 0.8, 0.5, col(Color(0.96, 0.96, 0.98)), H1)
	fb(root, -6.5, -13.5, 2.0, 0.6, 0.9, col(Color(0.9, 0.9, 0.92)), H1)
	deco(root, Vector3(-6.5, H1 + 1.8, -13.8), Vector3(1.6, 1.0, 0.05), col(Color(0.75, 0.85, 0.9), 0.4))
	lamp(root, Vector3(-9.0, H1 + 3.4, -10.5), 0.9, 9.0)
	deco(root, Vector3(-9.5, H1 + 0.05, -11.0), Vector3(1.8, 0.03, 1.1), fab(Color(0.3, 0.55, 0.65)))

	# ---------- Habitacion de Aris ----------
	bed(root, 12.2, 11.8, 2.3, 1.2, H1, Color(0.3, 0.45, 0.8))
	var book: Node3D = bookshelf(root, 9.0, 0.4, 4.0, H1, true)
	fb(root, 4.7, 3.2, 0.8, 2.6, 2.6, wood_dark, H1)
	table(root, 12.8, 0.9, 2.0, 1.0, 0.8, wood_mid, H1)
	chair(root, 12.8, 2.1, 0, -1, H1)
	deco(root, Vector3(12.8, H1 + 0.92, 0.8), Vector3(0.6, 0.04, 0.4), col(Color(0.15, 0.15, 0.18)))
	deco(root, Vector3(9.0, H1 + 0.05, 7.0), Vector3(4.0, 0.03, 5.0), fab(Color(0.2, 0.3, 0.45)))
	lamp(root, Vector3(9.0, H1 + 3.4, 7.0), 1.2, 12.0)
	lamp(root, Vector3(11.5, H1 + 1.6, 12.8), 0.6, 5.0)

	# ---------- Habitacion de invitados ----------
	bed(root, 11.9, -3.5, 2.3, 1.6, H1, Color(0.7, 0.55, 0.4), true)
	fb(root, 13.3, -5.0, 0.5, 0.5, 0.6, wood_dark, H1)
	fb(root, 13.3, -2.0, 0.5, 0.5, 0.6, wood_dark, H1)
	fb(root, 5.0, -2.0, 0.8, 2.0, 2.4, wood_dark, H1)
	lamp(root, Vector3(9.0, H1 + 3.4, -3.5), 0.9, 10.0)
	deco(root, Vector3(9.0, H1 + 0.05, -3.5), Vector3(5.5, 0.03, 4.4), fab(Color(0.4, 0.5, 0.4)))
	table(root, 6.6, -6.2, 1.6, 0.7, 0.75, wood_mid, H1)
	chair(root, 6.6, -5.3, 0, -1, H1)
	# ---------- Bano 2 ----------
	fb(root, 12.5, -12.9, 2.2, 1.1, 0.7, col(Color(0.96, 0.96, 0.98)), H1)
	fb(root, 9.5, -13.3, 0.6, 0.8, 0.5, col(Color(0.96, 0.96, 0.98)), H1)
	fb(root, 6.5, -13.5, 2.0, 0.6, 0.9, col(Color(0.9, 0.9, 0.92)), H1)
	lamp(root, Vector3(9.0, H1 + 3.4, -10.5), 0.9, 9.0)
	deco(root, Vector3(9.5, H1 + 0.05, -11.0), Vector3(1.8, 0.03, 1.1), fab(Color(0.3, 0.55, 0.65)))

	# ---------- Puerta de entrada (se cierra tras la llegada) ----------
	var door := Node3D.new()
	door.name = "FrontDoor"
	door.position = Vector3(0, 1.7, 14.0)
	door.visible = false
	var body := StaticBody3D.new()
	body.name = "Body"
	body.add_child(_bm(Vector3(2.6, 3.4, 0.15), col(Color(0.35, 0.22, 0.14))))
	var dcs := CollisionShape3D.new()
	dcs.name = "Col"
	var dbs := BoxShape3D.new()
	dbs.size = Vector3(2.6, 3.4, 0.15)
	dcs.shape = dbs
	dcs.disabled = true
	body.add_child(dcs)
	door.add_child(body)
	root.add_child(door)

	return {"spawn": Vector3(0, 1.0, 31), "env": env, "sky": sky_mat, "sun": sun, "papa": papa, "mama": mama, "door": door, "book": book}
