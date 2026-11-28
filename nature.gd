extends RefCounted

# Escenario natural: arboles frondosos, arbustos, rocas, montanas e islas.
# Los elementos pequenos se agrupan en MultiMesh (muy barato para el movil).

const Tex = preload("res://textures.gd")

static var _b: Dictionary = {}
static var _meshes: Dictionary = {}
static var _mats: Dictionary = {}


static func _mesh(k: String) -> Mesh:
	if _meshes.has(k):
		return _meshes[k]
	var m: Mesh = null
	if k == "blob":
		var s := SphereMesh.new()
		s.radius = 1.0
		s.height = 2.0
		s.radial_segments = 8
		s.rings = 4
		m = s
	elif k == "rock":
		var s2 := SphereMesh.new()
		s2.radius = 1.0
		s2.height = 2.0
		s2.radial_segments = 6
		s2.rings = 3
		m = s2
	elif k == "cone":
		var c := CylinderMesh.new()
		c.top_radius = 0.0
		c.bottom_radius = 1.0
		c.height = 1.0
		c.radial_segments = 7
		c.rings = 1
		m = c
	elif k == "cyl":
		var c2 := CylinderMesh.new()
		c2.top_radius = 0.7
		c2.bottom_radius = 1.0
		c2.height = 1.0
		c2.radial_segments = 6
		c2.rings = 1
		m = c2
	elif k == "leaf":
		var b := BoxMesh.new()
		b.size = Vector3(1.0, 0.04, 0.3)
		m = b
	else:
		var b2 := BoxMesh.new()
		b2.size = Vector3(1, 1, 1)
		m = b2
	_meshes[k] = m
	return m


static func _bmat(k: String) -> Material:
	if _mats.has(k):
		return _mats[k]
	var m: StandardMaterial3D
	if k == "rock":
		m = Tex.mat("rock", Color(1, 1, 1), 3.0).duplicate() as StandardMaterial3D
	elif k == "cyl":
		m = Tex.mat("bark", Color(1, 1, 1), 1.5).duplicate() as StandardMaterial3D
	else:
		m = StandardMaterial3D.new()
		m.roughness = 0.9
	m.vertex_color_use_as_albedo = true
	_mats[k] = m
	return m


static func add(k: String, pos: Vector3, sc: Vector3, rot: Vector3, col: Color) -> void:
	if not _b.has(k):
		_b[k] = [[], []]
	var e := Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z))
	var bs: Basis = Basis.from_euler(e) * Basis.from_scale(sc)
	_b[k][0].append(Transform3D(bs, pos))
	_b[k][1].append(col)


static func flush(root: Node3D) -> void:
	for k in _b.keys():
		var xs: Array = _b[k][0]
		var cs: Array = _b[k][1]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = _mesh(k)
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i])
			mm.set_instance_color(i, cs[i])
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = _bmat(k)
		if k == "rock" or k == "cyl":
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		else:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
	_b.clear()


static func collider(root: Node3D, pos: Vector3, radius: float, height: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, height * 0.5, 0)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	body.add_child(cs)
	root.add_child(body)


static func green(rng: RandomNumberGenerator, bright: float = 0.0) -> Color:
	var t: float = rng.randf()
	var a := Color(0.1, 0.36, 0.14)
	var b := Color(0.3, 0.6, 0.18)
	var c: Color = a.lerp(b, t)
	return Color(minf(c.r + bright, 1.0), minf(c.g + bright, 1.0), minf(c.b + bright * 0.5, 1.0))


# ---------- Vegetacion pequena ----------

static func bush(pos: Vector3, rng: RandomNumberGenerator, r: float = 1.0) -> void:
	var n: int = rng.randi_range(2, 3)
	for i in n:
		var o := Vector3(rng.randf_range(-0.7, 0.7) * r, 0, rng.randf_range(-0.7, 0.7) * r)
		var s: float = r * rng.randf_range(0.6, 1.0)
		add("blob", pos + o + Vector3(0, s * 0.5, 0), Vector3(s, s * 0.8, s), Vector3(0, rng.randf() * 360.0, 0), green(rng))


static func fern(pos: Vector3, rng: RandomNumberGenerator, s: float = 1.0) -> void:
	var col: Color = green(rng, 0.08)
	for i in 6:
		var yaw: float = float(i) * 60.0 + rng.randf_range(-12.0, 12.0)
		var dir := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
		add("leaf", pos + Vector3(0, 0.22 * s, 0) + dir * 0.5 * s, Vector3(1.2 * s, 1.0, 1.4 * s), Vector3(0, yaw, 28.0), col)


static func tuft(pos: Vector3, rng: RandomNumberGenerator, s: float = 1.0) -> void:
	var col := Color(0.35, 0.6, 0.22).lerp(Color(0.6, 0.72, 0.3), rng.randf())
	for i in 4:
		var o := Vector3(rng.randf_range(-0.25, 0.25), 0, rng.randf_range(-0.25, 0.25))
		add("cone", pos + o + Vector3(0, 0.35 * s, 0), Vector3(0.1 * s, 0.75 * s, 0.1 * s), Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12)), col)


static func flowers(pos: Vector3, rng: RandomNumberGenerator) -> void:
	var cols: Array = [Color(0.95, 0.85, 0.2), Color(0.95, 0.95, 0.95), Color(0.9, 0.3, 0.35), Color(0.7, 0.4, 0.9), Color(0.98, 0.55, 0.2)]
	var col: Color = cols[rng.randi() % cols.size()]
	for i in 5:
		var o := Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
		add("cone", pos + o + Vector3(0, 0.15, 0), Vector3(0.03, 0.3, 0.03), Vector3.ZERO, Color(0.2, 0.5, 0.2))
		add("blob", pos + o + Vector3(0, 0.33, 0), Vector3(0.1, 0.07, 0.1), Vector3.ZERO, col)


static func grass_patch(pos: Vector3, rng: RandomNumberGenerator, r: float) -> void:
	var col := Color(0.28, 0.5, 0.2).lerp(Color(0.4, 0.6, 0.25), rng.randf())
	add("blob", pos + Vector3(0, -0.02, 0), Vector3(r, 0.07, r * rng.randf_range(0.6, 1.0)), Vector3(0, rng.randf() * 180.0, 0), col)


# ---------- Rocas ----------

static func rock(root: Node3D, pos: Vector3, size: Vector3, rng: RandomNumberGenerator, collide: bool = true) -> void:
	var t: float = rng.randf_range(0.75, 1.05)
	var col := Color(t, t * 0.97, t * 0.93)
	add("rock", pos + Vector3(0, size.y * 0.35, 0), size, Vector3(rng.randf_range(-12, 12), rng.randf() * 360.0, rng.randf_range(-12, 12)), col)
	if collide and size.x > 0.9:
		var body := StaticBody3D.new()
		body.position = pos + Vector3(0, size.y * 0.4, 0)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(size.x * 1.5, size.y * 1.2, size.z * 1.5)
		cs.shape = sh
		body.add_child(cs)
		root.add_child(body)


static func boulders(root: Node3D, pos: Vector3, count: int, spread: float, smin: float, smax: float, rng: RandomNumberGenerator, collide: bool = true) -> void:
	for i in count:
		var o := Vector3(rng.randf_range(-spread, spread), 0, rng.randf_range(-spread, spread))
		var s: float = rng.randf_range(smin, smax)
		rock(root, pos + o, Vector3(s, s * rng.randf_range(0.7, 1.1), s * rng.randf_range(0.8, 1.2)), rng, collide)


# ---------- Arboles ----------

static func palm(root: Node3D, pos: Vector3, lean: float, h: float, rng: RandomNumberGenerator, collide: bool = true) -> void:
	var p: Vector3 = pos
	var seg: float = h / 4.0
	var bark := Color(0.8, 0.7, 0.6)
	for i in 4:
		var a: float = deg_to_rad(lean * float(i + 1) / 4.0)
		var up := Vector3(sin(a), cos(a), 0)
		var w: float = 0.3 - 0.03 * float(i)
		add("cyl", p + up * seg * 0.5, Vector3(w, seg * 1.05, w), Vector3(0, 0, -rad_to_deg(a)), bark)
		p += up * seg
	for i in 9:
		var yaw: float = float(i) * 40.0 + rng.randf_range(-10.0, 10.0)
		var dir := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw)))
		var c: Color = green(rng, 0.1)
		add("leaf", p + dir * 1.4 + Vector3(0, 0.1, 0), Vector3(3.2, 1.0, 2.2), Vector3(0, yaw, -22.0), c)
	for i in 3:
		add("blob", p + Vector3(rng.randf_range(-0.3, 0.3), -0.3, rng.randf_range(-0.3, 0.3)), Vector3(0.22, 0.22, 0.22), Vector3.ZERO, Color(0.4, 0.28, 0.14))
	if collide:
		collider(root, pos, 0.4, 2.5)


static func lush_tree(root: Node3D, pos: Vector3, rng: RandomNumberGenerator, collide: bool = true, scale_mul: float = 1.0) -> void:
	var kind: float = rng.randf()
	var h: float = rng.randf_range(5.0, 9.0) * scale_mul
	if kind < 0.14:
		# Cipres
		add("cyl", pos + Vector3(0, 0.5, 0), Vector3(0.32, 1.0, 0.32), Vector3.ZERO, Color(0.8, 0.7, 0.6))
		add("cone", pos + Vector3(0, h * 0.55, 0), Vector3(1.3 * scale_mul, h * 1.1, 1.3 * scale_mul), Vector3.ZERO, Color(0.07, 0.28, 0.13))
		add("cone", pos + Vector3(0, h * 0.3, 0), Vector3(1.8 * scale_mul, h * 0.6, 1.8 * scale_mul), Vector3.ZERO, Color(0.09, 0.32, 0.15))
		if collide:
			collider(root, pos, 0.45, 2.5)
		return
	var olive: bool = kind < 0.34
	var ht: float = h * 0.58
	var r: float = 0.4 * scale_mul
	add("cyl", pos + Vector3(0, ht * 0.5, 0), Vector3(r, ht, r), Vector3(0, rng.randf() * 360.0, rng.randf_range(-6, 6) if olive else 0.0), Color(0.85, 0.8, 0.75))
	var n: int = rng.randi_range(4, 6)
	for i in n:
		var ang: float = rng.randf() * TAU
		var off: float = rng.randf_range(0.2, 1.6) * scale_mul
		var rb: float = rng.randf_range(1.7, 2.8) * scale_mul
		var c: Color = green(rng)
		if olive:
			c = Color(0.38, 0.5, 0.3).lerp(Color(0.5, 0.58, 0.38), rng.randf())
		add("blob", pos + Vector3(cos(ang) * off, ht + rng.randf_range(-0.3, 1.8) * scale_mul, sin(ang) * off), Vector3(rb, rb * 0.78, rb), Vector3(0, rng.randf() * 360.0, 0), c)
	add("blob", pos + Vector3(0, ht + 1.2 * scale_mul, 0), Vector3(2.3 * scale_mul, 1.9 * scale_mul, 2.3 * scale_mul), Vector3.ZERO, green(rng, 0.05))
	if rng.randf() < 0.6:
		bush(pos + Vector3(rng.randf_range(-1.4, 1.4), 0, rng.randf_range(-1.4, 1.4)), rng, 0.9)
	if collide:
		collider(root, pos, r + 0.1, 2.5)


# ---------- Montanas ----------

static func _cyl_mesh(rt: float, rb: float, h: float, seg: int) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = seg
	c.rings = 1
	return c


static func mountain(root: Node3D, c: Vector3, rb: float, h: float, rng: RandomNumberGenerator, veg: float = 1.0, collide: bool = true) -> void:
	var tiers: int = 5
	var th: float = h / float(tiers)
	var r: float = rb
	var y: float = c.y
	var cx: float = c.x
	var cz: float = c.z
	for i in tiers:
		var step: float = th * 0.72
		var rt: float = r - step
		if i == tiers - 1:
			rt = 0.6
		var mi := MeshInstance3D.new()
		mi.mesh = _cyl_mesh(rt, r, th * 1.02, 10)
		if i == 0:
			mi.material_override = Tex.mat("rock", Color(0.78, 0.72, 0.66), 5.0)
		elif i == 1:
			mi.material_override = Tex.mat("rock", Color(0.85, 0.8, 0.72), 5.0)
		elif i == 2 or i == 3:
			mi.material_override = Tex.mat("grass", Color(0.8, 1.0, 0.7), 7.0)
		else:
			mi.material_override = Tex.mat("rock", Color(0.95, 0.92, 0.88), 5.0)
		var body := StaticBody3D.new()
		body.position = Vector3(cx, y + th * 0.5, cz)
		body.rotation.y = rng.randf() * TAU
		body.add_child(mi)
		if collide:
			var cs := CollisionShape3D.new()
			cs.shape = mi.mesh.create_convex_shape(true, false)
			body.add_child(cs)
		root.add_child(body)
		# Vegetacion en la ladera y en la cornisa
		if i >= 0 and i <= 3 and veg > 0.0:
			var ym: float = y + th * 0.5
			var rm: float = (r + rt) * 0.5
			var cnt: int = int(rm * 0.9 * veg)
			for k in cnt:
				var a: float = rng.randf() * TAU
				var yy: float = y + th * rng.randf_range(0.1, 0.95)
				var rr: float = lerpf(r, rt, (yy - y) / th) + 0.3
				var bs: float = rng.randf_range(1.2, 2.6)
				var col: Color = green(rng, 0.0)
				if i == 0 and rng.randf() < 0.5:
					col = Color(0.35, 0.4, 0.22)
				add("blob", Vector3(cx + cos(a) * rr, yy, cz + sin(a) * rr), Vector3(bs, bs * 0.7, bs), Vector3(0, rng.randf() * 360.0, 0), col)
			if i >= 1:
				var nt: int = int(rt * 0.7 * veg)
				for k2 in nt:
					var a2: float = rng.randf() * TAU
					var rr2: float = rt * rng.randf_range(0.55, 0.95)
					lush_tree(root, Vector3(cx + cos(a2) * rr2, y + th, cz + sin(a2) * rr2), rng, false, 0.7)
			var _unused: float = ym
		y += th
		r = rt
		cx += rng.randf_range(-1.0, 1.0)
		cz += rng.randf_range(-1.0, 1.0)


# ---------- Islas y mar ----------

static func island(root: Node3D, c: Vector3, r: float, h: float, rng: RandomNumberGenerator) -> void:
	var base := MeshInstance3D.new()
	base.mesh = _cyl_mesh(r * 0.88, r, 1.4, 12)
	base.material_override = Tex.mat("sand", Color(1, 1, 1), 8.0)
	base.position = Vector3(c.x, -0.4, c.z)
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(base)
	var hill := MeshInstance3D.new()
	hill.mesh = _cyl_mesh(r * 0.12, r * 0.74, h, 10)
	hill.material_override = Tex.mat("grass", Color(0.75, 0.95, 0.6), 9.0)
	hill.position = Vector3(c.x, 0.3 + h * 0.5, c.z)
	hill.rotation.y = rng.randf() * TAU
	hill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(hill)
	if h > 6.0:
		var peak := MeshInstance3D.new()
		peak.mesh = _cyl_mesh(0.0, r * 0.2, h * 0.35, 8)
		peak.material_override = Tex.mat("rock", Color(0.9, 0.86, 0.8), 6.0)
		peak.position = Vector3(c.x, 0.3 + h + h * 0.1, c.z)
		peak.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(peak)
	var n: int = int(r * 1.6)
	for i in n:
		var a: float = rng.randf() * TAU
		var f: float = rng.randf_range(0.0, 0.7)
		var rr: float = r * (0.7 - f * 0.6)
		var yy: float = 0.3 + h * f
		var bs: float = rng.randf_range(1.5, 3.2)
		add("blob", Vector3(c.x + cos(a) * rr, yy + 0.6, c.z + sin(a) * rr), Vector3(bs, bs * 0.75, bs), Vector3(0, rng.randf() * 360.0, 0), green(rng))
	for i2 in int(r * 0.35) + 2:
		var a2: float = rng.randf() * TAU
		var rr2: float = r * rng.randf_range(0.7, 0.9)
		palm(root, Vector3(c.x + cos(a2) * rr2, 0.2, c.z + sin(a2) * rr2), rng.randf_range(-12, 12), rng.randf_range(5.0, 8.0), rng, false)
	for i3 in int(r * 0.5):
		var a3: float = rng.randf() * TAU
		var rr3: float = r * rng.randf_range(0.95, 1.1)
		var s3: float = rng.randf_range(1.0, 2.4)
		add("rock", Vector3(c.x + cos(a3) * rr3, 0.0, c.z + sin(a3) * rr3), Vector3(s3, s3 * 0.8, s3), Vector3(0, rng.randf() * 360.0, 0), Color(0.85, 0.82, 0.78))


static func sea_stack(root: Node3D, c: Vector3, r: float, h: float, rng: RandomNumberGenerator, collide: bool = false) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _cyl_mesh(r * 0.55, r, h, 7)
	mi.material_override = Tex.mat("rock", Color(0.85, 0.8, 0.74), 4.0)
	var body := StaticBody3D.new()
	body.position = Vector3(c.x, h * 0.5 - 0.8, c.z)
	body.rotation.y = rng.randf() * TAU
	body.add_child(mi)
	if collide:
		var cs := CollisionShape3D.new()
		cs.shape = mi.mesh.create_convex_shape(true, false)
		body.add_child(cs)
	root.add_child(body)
	add("blob", Vector3(c.x, h - 0.6, c.z), Vector3(r * 0.7, r * 0.35, r * 0.7), Vector3.ZERO, green(rng))
	add("blob", Vector3(c.x + r * 0.2, h - 0.5, c.z - r * 0.1), Vector3(r * 0.4, r * 0.25, r * 0.4), Vector3.ZERO, green(rng, 0.05))


static func clouds(rng: RandomNumberGenerator, count: int) -> void:
	for i in count:
		var a: float = rng.randf() * TAU
		var d: float = rng.randf_range(120.0, 380.0)
		var s: float = rng.randf_range(10.0, 26.0)
		var p := Vector3(cos(a) * d, rng.randf_range(70.0, 130.0), sin(a) * d - 80.0)
		for k in 3:
			var o := Vector3(rng.randf_range(-1.0, 1.0) * s, rng.randf_range(-1.0, 1.0), rng.randf_range(-0.6, 0.6) * s)
			add("blob", p + o, Vector3(s * rng.randf_range(0.5, 0.9), s * 0.18, s * 0.45), Vector3(0, rng.randf() * 60.0, 0), Color(1, 1, 1))
