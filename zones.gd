extends RefCounted

const Companion = preload("res://companion.gd")
const Tex = preload("res://textures.gd")
const State = preload("res://state.gd")
const Nature = preload("res://nature.gd")
const Forest = preload("res://forest.gd")


static func mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


static func tbox(root: Node3D, pos: Vector3, size: Vector3, tex_name: String, tint: Color = Color(1, 1, 1), tile: float = 2.5) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = Tex.mat(tex_name, tint, tile)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	root.add_child(body)


static func tdeco(root: Node3D, pos: Vector3, size: Vector3, tex_name: String, tint: Color = Color(1, 1, 1), tile: float = 2.5) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = Tex.mat(tex_name, tint, tile)
	mi.position = pos
	root.add_child(mi)
	return mi


static func box(root: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	root.add_child(body)


static func cylinder(root: Node3D, pos: Vector3, radius: float, height: float, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat(color)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	body.add_child(cs)
	root.add_child(body)


static func tag(root: Node3D, pos: Vector3, text: String) -> void:
	var l := Label3D.new()
	l.text = text
	l.font_size = 56
	l.pixel_size = 0.01
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	root.add_child(l)


static func environment(root: Node3D, bg: Color, ambient: Color, ambient_energy: float, sun_energy: float, sun_color: Color) -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient
	env.ambient_light_energy = ambient_energy
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.light_energy = sun_energy
	sun.light_color = sun_color
	sun.shadow_enabled = true
	root.add_child(sun)
	return env


static func portal(root: Node3D, pos: Vector3, target: String, label: String, color: Color) -> void:
	var p := Node3D.new()
	p.position = pos
	p.add_to_group("portals")
	p.set_meta("target", target)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.6
	cm.bottom_radius = 1.6
	cm.height = 0.1
	mi.mesh = cm
	mi.material_override = mat(color, 2.0)
	mi.position = Vector3(0, 0.05, 0)
	p.add_child(mi)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 1.5
	light.omni_range = 6.0
	light.position = Vector3(0, 1.0, 0)
	p.add_child(light)
	tag(p, Vector3(0, 2.6, 0), label)
	root.add_child(p)


static func _place(root: Node3D, pts: Array, color: Color) -> void:
	for p in pts:
		var v: Vector3 = p
		tbox(root, v - Vector3(0, 0.3, 0), Vector3(3, 0.6, 3), "rock", Color(1, 1, 1), 2.0)


static func build_world(root: Node3D) -> Dictionary:
	environment(root, Color(0.55, 0.75, 0.95), Color(0.7, 0.75, 0.85), 0.6, 1.0, Color(1, 1, 1))
	box(root, Vector3(0, -0.5, 0), Vector3(160, 1, 160), Color(0.35, 0.6, 0.3))
	box(root, Vector3(0, 0.4, -10), Vector3(4, 0.8, 4), Color(0.85, 0.82, 0.75))
	for i in 12:
		var a := TAU * i / 12.0
		cylinder(root, Vector3(cos(a) * 14.0, 3.0, sin(a) * 14.0), 0.6, 6.0, Color(0.9, 0.88, 0.8))
	portal(root, Vector3(0, 0, 2), "camp", "Campamento", Color(0.3, 0.6, 1.0))

	var rock := Color(0.55, 0.5, 0.45)
	tag(root, Vector3(20, 3.0, -11), "Prueba de rocas")
	# Ruta A (facil)
	_place(root, [Vector3(24, 1.0, -14), Vector3(28, 2.0, -16.5), Vector3(32, 3.0, -17), Vector3(36, 4.0, -15), Vector3(37.5, 5.0, -11)], rock)
	# Ruta B (dificil)
	_place(root, [Vector3(23, 1.2, -8.5), Vector3(26.5, 2.4, -6.5), Vector3(28.5, 3.6, -2.5), Vector3(32, 4.8, 1.0)], Color(0.5, 0.45, 0.42))
	# Rama lateral al tesoro
	_place(root, [Vector3(31, 2.6, -21), Vector3(35, 3.4, -22), Vector3(39.5, 4.2, -21)], Color(0.6, 0.55, 0.4))
	box(root, Vector3(39.5, 4.7, -21), Vector3(1, 1, 1), Color(1.0, 0.8, 0.2))
	tag(root, Vector3(39.5, 6.2, -21), "Tesoro")
	# Cima
	box(root, Vector3(33, 5.6, -6), Vector3(6, 0.8, 6), Color(0.5, 0.47, 0.43))
	box(root, Vector3(33, 6.5, -6), Vector3(1, 1, 1), Color(1.0, 0.8, 0.2))
	tag(root, Vector3(33, 8.2, -6), "Cima")
	return {"spawn": Vector3(0, 1.1, 8)}


static func flame(root: Node3D) -> void:
	var outer := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = 0.6
	cm.height = 1.4
	outer.mesh = cm
	outer.material_override = mat(Color(1.0, 0.45, 0.1), 3.0)
	outer.position = Vector3(0, 1.2, 0)
	root.add_child(outer)
	var inner := MeshInstance3D.new()
	var cm2 := CylinderMesh.new()
	cm2.top_radius = 0.0
	cm2.bottom_radius = 0.3
	cm2.height = 0.9
	inner.mesh = cm2
	inner.material_override = mat(Color(1.0, 0.85, 0.3), 4.0)
	inner.position = Vector3(0, 1.0, 0)
	root.add_child(inner)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.25)
	light.light_energy = 3.0
	light.omni_range = 18.0
	light.shadow_enabled = true
	light.position = Vector3(0, 1.8, 0)
	root.add_child(light)
	var tw := light.create_tween().set_loops()
	tw.tween_property(light, "light_energy", 2.2, 0.18)
	tw.tween_property(light, "light_energy", 3.3, 0.22)


static func log_seat(root: Node3D, pos: Vector3, yaw_deg: float) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	body.rotation_degrees = Vector3(0, yaw_deg, 0)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.28
	cm.height = 2.2
	mi.mesh = cm
	mi.rotation_degrees = Vector3(0, 0, 90)
	mi.material_override = mat(Color(0.4, 0.27, 0.15))
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.28
	shape.height = 2.2
	cs.shape = shape
	cs.rotation_degrees = Vector3(0, 0, 90)
	body.add_child(cs)
	root.add_child(body)


static func tree(root: Node3D, pos: Vector3) -> void:
	var trunk := StaticBody3D.new()
	trunk.position = pos + Vector3(0, 1.0, 0)
	var tmi := MeshInstance3D.new()
	var tcm := CylinderMesh.new()
	tcm.top_radius = 0.32
	tcm.bottom_radius = 0.45
	tcm.height = 2.0
	tmi.mesh = tcm
	tmi.material_override = Tex.mat("bark", Color(1, 1, 1), 1.2)
	trunk.add_child(tmi)
	var tcs := CollisionShape3D.new()
	var tsh := CylinderShape3D.new()
	tsh.radius = 0.4
	tsh.height = 2.0
	tcs.shape = tsh
	trunk.add_child(tcs)
	root.add_child(trunk)
	var c1 := MeshInstance3D.new()
	var m1 := CylinderMesh.new()
	m1.top_radius = 0.0
	m1.bottom_radius = 1.8
	m1.height = 4.5
	c1.mesh = m1
	c1.material_override = mat(Color(0.1, 0.35, 0.18))
	c1.position = pos + Vector3(0, 4.2, 0)
	root.add_child(c1)
	var c2 := MeshInstance3D.new()
	var m2 := CylinderMesh.new()
	m2.top_radius = 0.0
	m2.bottom_radius = 1.3
	m2.height = 3.0
	c2.mesh = m2
	c2.material_override = mat(Color(0.12, 0.4, 0.2))
	c2.position = pos + Vector3(0, 6.0, 0)
	root.add_child(c2)


static func build_camp(root: Node3D) -> Dictionary:
	environment(root, Color(0.04, 0.06, 0.14), Color(0.3, 0.35, 0.55), 0.5, 0.35, Color(0.6, 0.7, 1.0))
	box(root, Vector3(0, -0.5, 0), Vector3(70, 1, 70), Color(0.2, 0.32, 0.18))
	box(root, Vector3(0, 0.25, 0), Vector3(1.8, 0.5, 1.8), Color(0.3, 0.3, 0.32))
	flame(root)
	log_seat(root, Vector3(-3.6, 0.28, 1.5), 50.0)
	log_seat(root, Vector3(3.6, 0.28, 1.5), -50.0)
	log_seat(root, Vector3(0, 0.28, -3.8), 0.0)

	# Tienda
	var tent := StaticBody3D.new()
	tent.position = Vector3(-8, 1.5, -6)
	var pm := PrismMesh.new()
	pm.size = Vector3(4, 3, 5)
	var tmi := MeshInstance3D.new()
	tmi.mesh = pm
	tmi.material_override = mat(Color(0.75, 0.6, 0.35))
	tent.add_child(tmi)
	var tcs := CollisionShape3D.new()
	tcs.shape = pm.create_convex_shape()
	tent.add_child(tcs)
	root.add_child(tent)
	tag(root, Vector3(-8, 4.0, -6), "Tienda")

	# Baul
	box(root, Vector3(8, 0.45, -6), Vector3(1.6, 0.9, 1.0), Color(0.45, 0.28, 0.14))
	box(root, Vector3(8, 0.95, -6), Vector3(1.7, 0.2, 1.1), Color(0.9, 0.7, 0.2))
	tag(root, Vector3(8, 2.2, -6), "Baúl")

	for i in 18:
		var a := TAU * i / 18.0
		tree(root, Vector3(cos(a) * 24.0, 0, sin(a) * 24.0))

	portal(root, Vector3(0, 0, 14), "return", "Volver", Color(1.0, 0.8, 0.3))
	return {"spawn": Vector3(0, 1.1, 8)}


# ---------- Playa del naufragio ----------

static func deco_box(root: Node3D, pos: Vector3, size: Vector3, color: Color, rot_deg: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color, emission)
	mi.position = pos
	mi.rotation_degrees = rot_deg
	root.add_child(mi)
	return mi


static func wall(root: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	root.add_child(body)


static func palm(root: Node3D, pos: Vector3, lean: float) -> void:
	var trunk := deco_box(root, pos + Vector3(0, 2.6, 0), Vector3(0.45, 5.2, 0.45), Color(0.5, 0.36, 0.2), Vector3(0, 0, lean))
	trunk.name = "Trunk"
	var top: Vector3 = pos + Vector3(-sin(deg_to_rad(lean)) * 2.6, 5.1, 0)
	for k in 5:
		var leaf := deco_box(root, top, Vector3(3.4, 0.08, 0.9), Color(0.15, 0.55, 0.22), Vector3(0, k * 72.0, 0))
		leaf.position = top + Vector3(0, -0.2, 0)
		leaf.rotation_degrees = Vector3(0, k * 72.0, -14)


static func build_beach(root: Node3D) -> Dictionary:
	var env: Environment = environment(root, Color(0.58, 0.8, 0.96), Color(0.7, 0.75, 0.85), 0.6, 0.85, Color(1.0, 0.96, 0.88))
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.5, 0.85)
	sky_mat.sky_horizon_color = Color(0.75, 0.88, 0.97)
	sky_mat.ground_horizon_color = Color(0.7, 0.85, 0.95)
	sky_mat.ground_bottom_color = Color(0.3, 0.5, 0.7)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_enabled = true
	env.fog_light_color = Color(0.74, 0.87, 0.96)
	env.fog_density = 0.0045
	env.fog_sky_affect = 0.15
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	# Arena
	tbox(root, Vector3(0, -0.5, 26), Vector3(120, 1, 70), "sand", Color(1, 1, 1), 3.0)
	# Orilla en pendiente (arena mojada) y mar
	tdeco(root, Vector3(0, -0.32, -12.5), Vector3(120, 0.3, 7.6), "sand", Color(0.78, 0.68, 0.52), 3.0).rotation_degrees = Vector3(-5, 0, 0)
	var sea := deco_box(root, Vector3(0, -0.95, -500), Vector3(1800, 1, 1000), Color(0.1, 0.42, 0.68))
	(sea.material_override as StandardMaterial3D).roughness = 0.12
	(sea.material_override as StandardMaterial3D).metallic_specular = 0.9
	deco_box(root, Vector3(0, -0.88, -22), Vector3(400, 0.1, 26), Color(0.2, 0.72, 0.76))
	var stw := sea.create_tween().set_loops()
	stw.tween_property(sea, "position:y", -0.88, 3.0).set_trans(Tween.TRANS_SINE)
	stw.tween_property(sea, "position:y", -0.97, 3.0).set_trans(Tween.TRANS_SINE)
	# Espuma (dos olas desfasadas)
	var foam := deco_box(root, Vector3(0, 0.03, -6.5), Vector3(120, 0.05, 1.0), Color(1, 1, 1, 1))
	var tw := foam.create_tween().set_loops()
	tw.tween_property(foam, "position:z", -4.8, 2.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(foam, "position:z", -6.8, 2.4).set_trans(Tween.TRANS_SINE)
	var foam2 := deco_box(root, Vector3(0, 0.02, -8.5), Vector3(120, 0.04, 0.6), Color(0.95, 0.98, 1.0))
	var tw2 := foam2.create_tween().set_loops()
	tw2.tween_property(foam2, "position:z", -6.4, 3.0).set_trans(Tween.TRANS_SINE)
	tw2.tween_property(foam2, "position:z", -9.0, 3.0).set_trans(Tween.TRANS_SINE)
	# Paredes invisibles
	wall(root, Vector3(0, 1.5, -7.6), Vector3(120, 3, 0.6))
	wall(root, Vector3(-59.5, 1.5, 26), Vector3(0.6, 3, 70))
	wall(root, Vector3(59.5, 1.5, 26), Vector3(0.6, 3, 70))
	wall(root, Vector3(0, 1.5, 60.5), Vector3(120, 3, 0.6))
	# Montanas laterales
	Nature.mountain(root, Vector3(-63, 0, 20), 30.0, 34.0, rng, 1.0)
	Nature.mountain(root, Vector3(66, 0, 30), 28.0, 28.0, rng, 1.0)
	# Cordillera lejana tras el bosque
	Nature.mountain(root, Vector3(-30, 0, 110), 44.0, 46.0, rng, 0.4, false)
	Nature.mountain(root, Vector3(40, 0, 120), 48.0, 52.0, rng, 0.4, false)
	Nature.mountain(root, Vector3(120, 0, 70), 36.0, 36.0, rng, 0.4, false)
	Nature.mountain(root, Vector3(-125, 0, 60), 36.0, 38.0, rng, 0.4, false)
	# Rocas grandes que cierran la playa (promontorios hacia el mar)
	for i in 7:
		var t: float = float(i) / 6.0
		Nature.boulders(root, Vector3(-34.0 - t * 12.0, 0, 2.0 - t * 30.0), 3, 2.5, 2.0, 4.6, rng)
		Nature.boulders(root, Vector3(36.0 + t * 12.0, 0, 6.0 - t * 34.0), 3, 2.5, 2.0, 4.6, rng)
	Nature.sea_stack(root, Vector3(-40, 0, -34), 4.0, 12.0, rng)
	Nature.sea_stack(root, Vector3(-52, 0, -24), 3.0, 8.0, rng)
	Nature.sea_stack(root, Vector3(46, 0, -36), 4.5, 14.0, rng)
	Nature.sea_stack(root, Vector3(58, 0, -22), 3.0, 9.0, rng)
	Nature.sea_stack(root, Vector3(-18, 0, -40), 2.2, 5.0, rng)
	Nature.sea_stack(root, Vector3(16, 0, -52), 2.6, 6.0, rng)
	# Rocas pequenas en el agua y la orilla
	for i in 14:
		var rx: float = rng.randf_range(-34.0, 34.0)
		var rz: float = rng.randf_range(-20.0, -9.0)
		var rs: float = rng.randf_range(0.6, 1.6)
		Nature.add("rock", Vector3(rx, -0.3, rz), Vector3(rs, rs * 0.7, rs), Vector3(0, rng.randf() * 360.0, 0), Color(0.8, 0.77, 0.72))
	# Islas del horizonte
	Nature.island(root, Vector3(-30, 0, -70), 10.0, 6.0, rng)
	Nature.island(root, Vector3(28, 0, -90), 14.0, 10.0, rng)
	Nature.island(root, Vector3(-80, 0, -120), 22.0, 16.0, rng)
	Nature.island(root, Vector3(75, 0, -150), 28.0, 22.0, rng)
	Nature.island(root, Vector3(0, 0, -200), 44.0, 34.0, rng)
	Nature.island(root, Vector3(-140, 0, -190), 34.0, 26.0, rng)
	Nature.island(root, Vector3(150, 0, -230), 40.0, 30.0, rng)
	Nature.clouds(rng, 16)
	# Palmeras
	var palms: Array = [Vector3(-16, 0, 4), Vector3(18, 0, 10), Vector3(-22, 0, 24), Vector3(25, 0, 28), Vector3(-9, 0, 40), Vector3(12, 0, 44), Vector3(-28, 0, 8), Vector3(30, 0, 14), Vector3(8, 0, 3), Vector3(-4, 0, 22), Vector3(14, 0, 30), Vector3(-30, 0, 38)]
	for pv in palms:
		var pp: Vector3 = pv
		Nature.palm(root, pp, rng.randf_range(-14.0, 14.0), rng.randf_range(5.0, 7.5), rng)
	# Restos del naufragio
	deco_box(root, Vector3(-13, 0.9, 13), Vector3(0.5, 2.0, 8.0), Color(0.42, 0.28, 0.16), Vector3(0, 18, 12))
	deco_box(root, Vector3(-10.5, 0.6, 11.5), Vector3(0.5, 1.4, 6.0), Color(0.48, 0.32, 0.18), Vector3(0, 28, -15))
	deco_box(root, Vector3(-15.5, 3.0, 15), Vector3(0.35, 6.0, 0.35), Color(0.4, 0.27, 0.15), Vector3(18, 0, 22))
	deco_box(root, Vector3(-14.4, 3.6, 15.2), Vector3(0.05, 2.8, 2.2), Color(0.95, 0.93, 0.88), Vector3(18, 0, 22))
	deco_box(root, Vector3(-12.2, 0.5, 8.4), Vector3(0.4, 1.0, 3.6), Color(0.38, 0.25, 0.14), Vector3(0, -12, 8))
	deco_box(root, Vector3(-14.8, 0.45, 17.6), Vector3(0.4, 0.9, 3.0), Color(0.45, 0.3, 0.17), Vector3(0, 40, -10))
	box(root, Vector3(-6, 0.45, 9), Vector3(1.0, 0.9, 1.0), Color(0.5, 0.33, 0.18))
	box(root, Vector3(-7.1, 0.35, 10.2), Vector3(0.8, 0.7, 0.8), Color(0.45, 0.3, 0.17))
	box(root, Vector3(8, 0.3, 17), Vector3(2.0, 0.6, 1.4), Color(0.55, 0.52, 0.48))
	for i in 9:
		var wx: float = rng.randf_range(-24.0, 14.0)
		var wz: float = rng.randf_range(2.0, 22.0)
		Nature.add("slab", Vector3(wx, 0.08, wz), Vector3(rng.randf_range(1.5, 3.2), 0.12, 0.3), Vector3(0, rng.randf() * 180.0, rng.randf_range(-6, 6)), Color(0.45, 0.32, 0.2))
	Nature.add("cyl", Vector3(-4.2, 0.45, 12.0), Vector3(0.5, 0.9, 0.5), Vector3.ZERO, Color(0.55, 0.38, 0.22))
	Nature.add("cyl", Vector3(-9.5, 0.3, 6.5), Vector3(0.5, 0.9, 0.5), Vector3(0, 0, 80), Color(0.5, 0.35, 0.2))
	# Conchas, estrellas de mar y algas en la orilla
	for i in 34:
		var sx: float = rng.randf_range(-36.0, 36.0)
		var sz: float = rng.randf_range(-6.5, 3.0)
		if rng.randf() < 0.5:
			Nature.add("blob", Vector3(sx, 0.03, sz), Vector3(0.16, 0.08, 0.12), Vector3(0, rng.randf() * 180.0, 0), Color(0.98, 0.9, 0.85))
		else:
			Nature.add("blob", Vector3(sx, 0.02, sz), Vector3(0.22, 0.03, 0.22), Vector3(0, rng.randf() * 180.0, 0), Color(0.95, 0.45, 0.3))
	for i in 18:
		var ax: float = rng.randf_range(-36.0, 36.0)
		Nature.add("blob", Vector3(ax, 0.02, rng.randf_range(-8.0, -5.5)), Vector3(0.7, 0.06, 0.4), Vector3(0, rng.randf() * 180.0, 0), Color(0.2, 0.35, 0.2))
	# Hierba, arbustos y flores al pie de las montanas y hacia el bosque
	for i in 70:
		var gx: float = rng.randf_range(-44.0, 44.0)
		var gz: float = rng.randf_range(16.0, 56.0)
		if absf(gx) < 4.0 and gz > 30.0:
			continue
		if gz < 34.0 and absf(gx) < 22.0:
			continue
		Nature.grass_patch(Vector3(gx, 0.02, gz), rng, rng.randf_range(2.0, 4.5))
	for i in 60:
		var tx: float = rng.randf_range(-40.0, 40.0)
		var tz: float = rng.randf_range(8.0, 56.0)
		if absf(tx) < 3.0 and tz > 30.0:
			continue
		Nature.tuft(Vector3(tx, 0, tz), rng, rng.randf_range(0.8, 1.6))
	for i in 24:
		var fx: float = rng.randf_range(-42.0, 42.0)
		var fz: float = rng.randf_range(20.0, 56.0)
		if absf(fx) < 3.5 and fz > 30.0:
			continue
		Nature.flowers(Vector3(fx, 0, fz), rng)
	for i in 26:
		var bx: float = rng.randf_range(-46.0, 46.0)
		var bz: float = rng.randf_range(14.0, 50.0)
		if absf(bx) < 6.0 or (absf(bx) < 24.0 and bz < 32.0):
			continue
		Nature.bush(Vector3(bx, 0, bz), rng, rng.randf_range(0.9, 1.5))
	# Bosque frondoso que cierra el fondo, con camino central
	var gz2: float = 36.0
	while gz2 < 61.0:
		var gx2: float = -58.0
		while gx2 < 58.0:
			var px: float = gx2 + rng.randf_range(-1.2, 1.2)
			var pz: float = gz2 + rng.randf_range(-1.2, 1.2)
			var dens: float = clampf((pz - 34.0) / 10.0, 0.12, 1.0)
			if absf(px) > 38.0:
				dens *= 0.6
			var onpath: bool = absf(px) < 4.6 and pz > 30.0
			if not onpath and rng.randf() < dens:
				Nature.lush_tree(root, Vector3(px, 0, pz), rng, absf(px) < 40.0)
				if rng.randf() < 0.55:
					Nature.fern(Vector3(px + rng.randf_range(-1.5, 1.5), 0, pz + rng.randf_range(-1.5, 1.5)), rng, rng.randf_range(0.9, 1.5))
			gx2 += 3.4
		gz2 += 3.4
	# Sotobosque junto al camino
	for i in 60:
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var ex: float = side * rng.randf_range(4.6, 8.0)
		var ez: float = rng.randf_range(34.0, 60.0)
		if rng.randf() < 0.5:
			Nature.fern(Vector3(ex, 0, ez), rng, rng.randf_range(1.0, 1.7))
		else:
			Nature.bush(Vector3(ex, 0, ez), rng, rng.randf_range(0.8, 1.4))
	for i in 12:
		var side2: float = -1.0 if rng.randf() < 0.5 else 1.0
		Nature.flowers(Vector3(side2 * rng.randf_range(3.2, 5.0), 0, rng.randf_range(34.0, 58.0)), rng)
	# Puerta verde: dos arboles gigantes unidos por las copas, enredaderas y tronco caido
	for sd in [-1.0, 1.0]:
		var sdf: float = sd
		tdeco(root, Vector3(sdf * 5.6, 4.5, 51.0), Vector3(1.4, 9.0, 1.4), "bark", Color(1, 1, 1), 1.2)
		Nature.collider(root, Vector3(sdf * 5.6, 0, 51.0), 0.8, 4.0)
		for k in 6:
			Nature.add("blob", Vector3(sdf * (4.2 - float(k) * 1.2), 9.0 + rng.randf_range(0.0, 1.2), 51.0 + rng.randf_range(-1.5, 1.5)), Vector3(3.2, 2.2, 3.4), Vector3(0, rng.randf() * 360.0, 0), Nature.green(rng))
		Nature.add("blob", Vector3(sdf * 5.6, 8.2, 51.0), Vector3(3.6, 2.8, 3.6), Vector3.ZERO, Nature.green(rng, 0.05))
		for k2 in 7:
			var vh: float = rng.randf_range(2.0, 5.5)
			Nature.add("cyl", Vector3(sdf * rng.randf_range(0.5, 5.0), 8.6 - vh * 0.5, 51.0 + rng.randf_range(-1.2, 1.2)), Vector3(0.05, vh, 0.05), Vector3.ZERO, Color(0.25, 0.45, 0.2))
		Nature.boulders(root, Vector3(sdf * 5.0, 0, 48.0), 3, 1.8, 0.8, 1.6, rng)
	Nature.add("slab", Vector3(2.5, 0.35, 45.0), Vector3(4.0, 0.7, 0.7), Vector3(0, 70, 0), Color(0.4, 0.3, 0.2))
	tdeco(root, Vector3(0, 0.015, 52.0), Vector3(120, 0.03, 18.0), "grass", Color(0.8, 0.95, 0.7), 3.5)
	# Camino de tierra hacia el bosque
	tdeco(root, Vector3(0, 0.025, 46.0), Vector3(4.2, 0.04, 30.0), "dirt", Color(1, 1, 1), 2.0)
	# Luz calida bajo la puerta verde
	var fl := OmniLight3D.new()
	fl.light_color = Color(1.0, 0.9, 0.6)
	fl.light_energy = 0.9
	fl.omni_range = 9.0
	fl.position = Vector3(0, 4.0, 49.0)
	root.add_child(fl)
	# El libro
	deco_box(root, Vector3(1.6, 0.08, 6.6), Vector3(0.8, 0.12, 0.6), Color(0.5, 0.2, 0.12), Vector3(0, 20, 0))
	deco_box(root, Vector3(1.6, 0.15, 6.6), Vector3(0.7, 0.06, 0.5), Color(1.0, 0.9, 0.5), Vector3(0, 20, 0), 1.6)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.85, 0.4)
	glow.light_energy = 1.2
	glow.omni_range = 5.0
	glow.position = Vector3(1.6, 0.8, 6.6)
	root.add_child(glow)
	tag(root, Vector3(1.6, 1.5, 6.6), "El libro")
	tag(root, Vector3(0, 6.5, 14), "Playa de Creta")
	portal(root, Vector3(0, 0, 54), "cap1", "Adentrarse en el bosque", Color(0.3, 0.6, 1.0))
	Nature.flush(root)
	return {"spawn": Vector3(0, 1.1, 6)}


# ---------- Casa del inicio ----------

static func interact(root: Node3D, pos: Vector3, action: String, id: String, button: String, label_text: String) -> void:
	var p := Node3D.new()
	p.position = pos
	p.add_to_group("portals")
	p.set_meta("action", action)
	p.set_meta("id", id)
	p.set_meta("button", button)
	if label_text != "":
		tag(p, Vector3(0, 2.2, 0), label_text)
	root.add_child(p)


static func _lamp(root: Node3D, pos: Vector3, color: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.position = pos
	root.add_child(l)


static func build_house(root: Node3D) -> Dictionary:
	environment(root, Color(0.03, 0.04, 0.1), Color(0.5, 0.5, 0.62), 0.45, 0.12, Color(0.6, 0.7, 1.0))
	var wallc := Color(0.9, 0.84, 0.72)
	var wood := Color(0.55, 0.38, 0.22)
	# Suelo exterior y planta baja
	box(root, Vector3(0, -1.5, 0), Vector3(80, 1, 80), Color(0.1, 0.2, 0.12))
	box(root, Vector3(0, -0.5, 0), Vector3(20, 1, 16), wood)
	# Muros exteriores
	box(root, Vector3(-10.15, 3.8, 0), Vector3(0.3, 7.6, 16.6), wallc)
	box(root, Vector3(10.15, 3.8, 0), Vector3(0.3, 7.6, 16.6), wallc)
	box(root, Vector3(0, 3.8, -8.15), Vector3(20.6, 7.6, 0.3), wallc)
	box(root, Vector3(0, 3.8, 8.15), Vector3(20.6, 7.6, 0.3), wallc)
	# Techo
	box(root, Vector3(0, 7.75, 0), Vector3(21, 0.3, 17), Color(0.35, 0.22, 0.2))
	# Segundo piso (con hueco para la escalera)
	box(root, Vector3(-1.7, 3.65, 0), Vector3(16.6, 0.3, 16), wood)
	box(root, Vector3(8.3, 3.65, -5.5), Vector3(3.4, 0.3, 5), wood)
	box(root, Vector3(8.3, 3.65, 6.75), Vector3(3.4, 0.3, 2.5), wood)
	# Rampa de la escalera (colision) + peldanos decorativos
	var ramp := StaticBody3D.new()
	ramp.position = Vector3(8.0, 1.734, 1.0)
	ramp.rotation_degrees = Vector3(25.4, 0, 0)
	var rcs := CollisionShape3D.new()
	var rbs := BoxShape3D.new()
	rbs.size = Vector3(2.4, 0.3, 8.857)
	rcs.shape = rbs
	ramp.add_child(rcs)
	var rmi := MeshInstance3D.new()
	var rbm := BoxMesh.new()
	rbm.size = Vector3(2.4, 0.3, 8.857)
	rmi.mesh = rbm
	rmi.material_override = mat(Color(0.62, 0.45, 0.28))
	ramp.add_child(rmi)
	root.add_child(ramp)
	for i in 8:
		var zz: float = 4.5 - float(i)
		var yy: float = (5.0 - zz) * 0.475 + 0.17
		deco_box(root, Vector3(8.0, yy, zz + 0.45), Vector3(2.4, 0.04, 0.1), Color(0.3, 0.2, 0.12))
	# Barandillas del hueco
	box(root, Vector3(6.6, 4.35, 1.25), Vector3(0.1, 1.1, 8.5), Color(0.4, 0.27, 0.15))
	box(root, Vector3(8.3, 4.35, 5.5), Vector3(3.4, 1.1, 0.1), Color(0.4, 0.27, 0.15))
	# Salon: sofa, tele, mesa de centro, comedor, cocina
	box(root, Vector3(-6.8, 0.4, 2.8), Vector3(1.3, 0.8, 3.4), Color(0.3, 0.38, 0.6))
	box(root, Vector3(-7.4, 0.9, 2.8), Vector3(0.3, 1.0, 3.4), Color(0.26, 0.33, 0.55))
	box(root, Vector3(-4.4, 0.25, 2.8), Vector3(1.0, 0.5, 1.7), Color(0.45, 0.3, 0.18))
	box(root, Vector3(-1.2, 0.35, 2.8), Vector3(0.7, 0.7, 2.2), Color(0.3, 0.2, 0.14))
	deco_box(root, Vector3(-0.78, 1.15, 2.8), Vector3(0.1, 1.0, 1.9), Color(0.2, 0.45, 0.8), Vector3.ZERO, 1.2)
	_lamp(root, Vector3(-0.2, 1.4, 2.8), Color(0.4, 0.6, 1.0), 0.8, 5.0)
	box(root, Vector3(-4.0, 0.4, -5.8), Vector3(3.0, 0.8, 1.4), Color(0.5, 0.33, 0.2))
	box(root, Vector3(3.0, 0.5, -7.3), Vector3(6.0, 1.0, 0.9), Color(0.8, 0.8, 0.82))
	# Padres
	var papa: Node3D = Companion.person(Color(0.25, 0.5, 0.55), "Papá")
	papa.position = Vector3(-5.8, 0, -3.5)
	root.add_child(papa)
	var mama: Node3D = Companion.person(Color(0.7, 0.35, 0.55), "Mamá")
	mama.position = Vector3(-2.2, 0, -3.5)
	root.add_child(mama)
	interact(root, Vector3(-5.8, 0, -3.5), "talk", "papa", "HABLAR", "")
	interact(root, Vector3(-2.2, 0, -3.5), "talk", "mama", "HABLAR", "")
	# Habitacion de Aris (arriba)
	box(root, Vector3(-7.5, 4.05, -6.2), Vector3(3.2, 0.5, 2.0), Color(0.75, 0.3, 0.3))
	box(root, Vector3(-9.2, 4.45, -6.2), Vector3(0.3, 1.3, 2.0), wood)
	deco_box(root, Vector3(-8.7, 4.4, -6.2), Vector3(0.7, 0.2, 1.2), Color(0.95, 0.95, 0.95))
	interact(root, Vector3(-5.5, 3.8, -5.2), "sleep", "cama", "DORMIR", "")
	box(root, Vector3(-1.5, 4.2, -7.2), Vector3(2.4, 0.8, 1.0), Color(0.5, 0.35, 0.2))
	deco_box(root, Vector3(-1.5, 4.64, -7.2), Vector3(0.6, 0.08, 0.45), Color(0.5, 0.2, 0.12), Vector3(0, 15, 0))
	deco_box(root, Vector3(-1.5, 4.7, -7.2), Vector3(0.5, 0.04, 0.36), Color(1.0, 0.9, 0.5), Vector3(0, 15, 0), 1.0)
	interact(root, Vector3(-1.5, 3.8, -6.2), "talk", "libro", "LEER", "")
	box(root, Vector3(-4.5, 4.2, 2.0), Vector3(0.6, 0.8, 5.0), Color(0.4, 0.3, 0.5))
	# Ventana con luna
	deco_box(root, Vector3(3.0, 5.4, -7.97), Vector3(3.0, 1.6, 0.05), Color(0.35, 0.5, 0.9), Vector3.ZERO, 0.8)
	# Luces
	_lamp(root, Vector3(-4, 3.0, 0), Color(1.0, 0.85, 0.6), 1.3, 12.0)
	_lamp(root, Vector3(3, 3.0, -2), Color(1.0, 0.85, 0.6), 0.9, 9.0)
	_lamp(root, Vector3(-3, 6.8, -3), Color(1.0, 0.85, 0.6), 1.3, 12.0)
	_lamp(root, Vector3(-7.5, 5.6, -5.5), Color(1.0, 0.75, 0.45), 0.9, 6.0)
	return {"spawn": Vector3(2, 1.1, 3)}


# ---------- Capitulo 1: el bosque de Creta ----------

static func cap1_enemies() -> Array:
	return [
		["c1", Vector3(6, 0, 29), ["satiro"]],
		["c2", Vector3(14, 0, 17), ["arpia", "satiro"]],
		["c3", Vector3(-19, 0, -1), ["satiro", "satiro"]],
		["c4", Vector3(27, 0, 27), ["arpia", "arpia"]],
		["c5", Vector3(-6, 0, 1), ["satiro", "arpia"]],
		["c6", Vector3(-12, 0, -16), ["arpia", "satiro"]],
		["c7", Vector3(-2, 0, -26), ["satiro", "arpia"]],
		["boss", Vector3(0, 0, -41), ["aelo"]],
	]


static func ground_y(x: float, z: float) -> float:
	return Forest.gy(x, z)


static func brazier(root: Node3D, pos: Vector3, id: String) -> void:
	var b := Node3D.new()
	b.name = "Brazier_" + id
	b.position = pos
	cylinder(b, Vector3(0, 0.6, 0), 0.7, 1.2, Color(0.45, 0.43, 0.4))
	var bowl := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.9
	cm.bottom_radius = 0.5
	cm.height = 0.4
	bowl.mesh = cm
	bowl.material_override = mat(Color(0.3, 0.28, 0.27))
	bowl.position = Vector3(0, 1.4, 0)
	b.add_child(bowl)
	var fire := Node3D.new()
	fire.name = "Fire"
	fire.visible = false
	b.add_child(fire)
	var f1 := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.0
	fm.bottom_radius = 0.5
	fm.height = 1.2
	f1.mesh = fm
	f1.material_override = mat(Color(1.0, 0.5, 0.12), 3.0)
	f1.position = Vector3(0, 2.1, 0)
	fire.add_child(f1)
	var li := OmniLight3D.new()
	li.light_color = Color(1.0, 0.6, 0.25)
	li.light_energy = 2.5
	li.omni_range = 9.0
	li.position = Vector3(0, 2.6, 0)
	fire.add_child(li)
	root.add_child(b)
	if State.flags.has(id):
		fire.visible = true
	else:
		interact(root, pos, "brazier", id, "ENCENDER", "Fuego antiguo")
		b.set_meta("unlit", true)


static func chest(root: Node3D, pos: Vector3, id: String) -> void:
	var c := Node3D.new()
	c.name = "Chest_" + id
	c.position = pos
	box(c, Vector3(0, 0.4, 0), Vector3(1.4, 0.8, 0.9), Color(0.45, 0.28, 0.14))
	var lid := deco_box(c, Vector3(0, 0.9, 0), Vector3(1.5, 0.2, 1.0), Color(0.9, 0.7, 0.2))
	lid.name = "Lid"
	if State.flags.has(id):
		lid.position = Vector3(0, 1.1, -0.5)
		lid.rotation_degrees = Vector3(-60, 0, 0)
	root.add_child(c)
	if not State.flags.has(id):
		interact(root, pos, "chest", id, "ABRIR", "Cofre")


static func refresh_cap1(root: Node3D) -> void:
	for i in 3:
		var id: String = "b" + str(i + 1)
		var b: Node = root.get_node_or_null("Brazier_" + id)
		if b != null:
			b.get_node("Fire").visible = State.flags.has(id)
		var s: Node = root.get_node_or_null("Gate/Sock" + str(i + 1))
		if s != null:
			(s as MeshInstance3D).material_override = mat(Color(1.0, 0.8, 0.25), 2.5) if State.flags.has(id) else mat(Color(0.2, 0.2, 0.22))
	var ch: Node = root.get_node_or_null("Chest_chest1/Lid")
	if ch != null and State.flags.has("chest1"):
		var lid := ch as Node3D
		lid.position = Vector3(0, 1.1, -0.5)
		lid.rotation_degrees = Vector3(-60, 0, 0)
	var gate: Node = root.get_node_or_null("Gate")
	if gate != null and State.flags.has("gate_open"):
		(gate.get_node("Col") as CollisionShape3D).disabled = true
		var g := gate as Node3D
		var tw := g.create_tween()
		tw.tween_property(g, "position:y", g.position.y - 8.0, 2.0)
		tw.tween_callback(g.queue_free)


static func _step_rocks(root: Node3D, start: Vector3, goal: Vector3, top_y: float) -> void:
	var base: float = Forest.gy(start.x, start.z)
	var n: int = int(ceil((top_y - base) / 1.1))
	for i in range(1, n + 1):
		var t: float = float(i) / float(n + 1)
		var p: Vector3 = start.lerp(goal, t)
		var top: float = base + (top_y - base) * t
		tbox(root, Vector3(p.x, top - 1.5, p.z), Vector3(3.0, 3.0, 3.0), "rock", Color(1, 1, 1), 2.0)


static func build_cap1(root: Node3D) -> Dictionary:
	var env: Environment = environment(root, Color(0.55, 0.78, 0.95), Color(0.7, 0.78, 0.8), 0.7, 0.85, Color(1.0, 0.95, 0.82))
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.52, 0.85)
	sky_mat.sky_horizon_color = Color(0.78, 0.9, 0.9)
	sky_mat.ground_horizon_color = Color(0.6, 0.78, 0.7)
	sky_mat.ground_bottom_color = Color(0.25, 0.4, 0.3)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_enabled = true
	env.fog_light_color = Color(0.66, 0.82, 0.78)
	env.fog_density = 0.011
	env.fog_sky_affect = 0.2
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	Forest.build_grid()
	Forest.terrain(root)
	# Limites invisibles
	wall(root, Vector3(0, 6, 49.5), Vector3(100, 12, 1))
	wall(root, Vector3(-49.5, 6, 0), Vector3(1, 12, 100))
	wall(root, Vector3(49.5, 6, 0), Vector3(1, 12, 100))
	wall(root, Vector3(0, 6, -49.5), Vector3(100, 12, 1))
	# Acantilado de la cueva (con puerta central)
	var rockc := Color(0.5, 0.47, 0.44)
	tbox(root, Vector3(-27.5, 5, -34), Vector3(43, 10, 3), "rock", Color(1, 1, 1), 3.0)
	tbox(root, Vector3(27.5, 5, -34), Vector3(43, 10, 3), "rock", Color(1, 1, 1), 3.0)
	tbox(root, Vector3(0, 8.5, -34), Vector3(12, 3, 3), "rock", Color(1, 1, 1), 3.0)
	# Paredes de la cueva
	tbox(root, Vector3(-16, 4, -42), Vector3(1, 8, 16), "rock", Color(0.6, 0.58, 0.62), 2.5)
	tbox(root, Vector3(16, 4, -42), Vector3(1, 8, 16), "rock", Color(0.6, 0.58, 0.62), 2.5)
	tbox(root, Vector3(0, 4, -49.5), Vector3(32, 8, 1), "rock", Color(0.6, 0.58, 0.62), 2.5)
	deco_box(root, Vector3(0, 0.02, -42), Vector3(30, 0.04, 14), Color(0.4, 0.37, 0.34))
	var cave_light := OmniLight3D.new()
	cave_light.light_color = Color(1.0, 0.8, 0.5)
	cave_light.light_energy = 1.6
	cave_light.omni_range = 22.0
	cave_light.position = Vector3(0, 6, -42)
	root.add_child(cave_light)
	# Puerta de piedra
	var gate := StaticBody3D.new()
	gate.name = "Gate"
	gate.position = Vector3(0, 3.5, -34)
	var gm := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(12, 7, 3)
	gm.mesh = gb
	gm.material_override = Tex.mat("rock", Color(0.62, 0.62, 0.68), 2.0)
	gate.add_child(gm)
	var gcs := CollisionShape3D.new()
	gcs.name = "Col"
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(12, 7, 3)
	gcs.shape = gbs
	gate.add_child(gcs)
	for i in 3:
		var s := MeshInstance3D.new()
		var sb := BoxMesh.new()
		sb.size = Vector3(1.0, 1.0, 0.2)
		s.mesh = sb
		s.name = "Sock" + str(i + 1)
		s.position = Vector3(-3.0 + 3.0 * i, 1.2, 1.6)
		s.material_override = mat(Color(0.2, 0.2, 0.22))
		gate.add_child(s)
	root.add_child(gate)
	tag(root, Vector3(0, 8.5, -31), "Cueva del monte")
	# Fuegos antiguos: oeste (sendero), este (sendero) y alto (colina con rocas)
	var b1y: float = Forest.gy(-27, -4)
	brazier(root, Vector3(-27, b1y, -4), "b1")
	var b2y: float = Forest.gy(34, 25)
	brazier(root, Vector3(34, b2y, 25), "b2")
	_step_rocks(root, Vector3(-19, 0, -13), Vector3(-28, 0, -18), 6.5)
	brazier(root, Vector3(-31, 6.5, -19), "b3")
	_step_rocks(root, Vector3(22, 0, -7), Vector3(28.5, 0, -12), 5.5)
	chest(root, Vector3(31, 5.5, -14), "chest1")
	# Curete
	var cur: Node3D = Companion.person(Color(0.72, 0.55, 0.2), "Curete")
	cur.name = "Curete"
	cur.position = Vector3(5.5, Forest.gy(5.5, 36), 36)
	cur.rotation.y = deg_to_rad(40)
	root.add_child(cur)
	interact(root, cur.position, "talk", "curete", "HABLAR", "")
	# Bosque frondoso sobre el terreno
	var keep: Array = [Vector3(-27, 0, -4), Vector3(34, 0, 25), Vector3(-31, 0, -19), Vector3(31, 0, -14), Vector3(5.5, 0, 36)]
	var zz: float = -46.0
	while zz < 47.0:
		var xx: float = -46.0
		while xx < 47.0:
			var px: float = xx + rng.randf_range(-1.4, 1.4)
			var pz: float = zz + rng.randf_range(-1.4, 1.4)
			xx += 3.6
			var dist: float = Forest.gd(px, pz)
			if dist < 3.4 or rng.randf() > 0.68:
				continue
			if pz < -30.0 and absf(px) < 26.0:
				continue
			var near_keep: bool = false
			for k in keep:
				var kv: Vector3 = k
				if Vector2(px - kv.x, pz - kv.z).length() < 4.0:
					near_keep = true
			if near_keep or Forest.slope(px, pz) > 1.1:
				continue
			Nature.lush_tree(root, Vector3(px, Forest.gy(px, pz) - 0.15, pz), rng, dist < 14.0)
		zz += 3.6
	# Sotobosque: helechos, arbustos, hierba, flores y rocas
	for i in 330:
		var fx: float = rng.randf_range(-46.0, 46.0)
		var fz: float = rng.randf_range(-30.0, 48.0)
		var fd: float = Forest.gd(fx, fz)
		if fd < 2.6:
			continue
		var fy: float = Forest.gy(fx, fz)
		var r: float = rng.randf()
		if r < 0.45:
			Nature.fern(Vector3(fx, fy, fz), rng, rng.randf_range(0.9, 1.6))
		elif r < 0.7:
			Nature.bush(Vector3(fx, fy, fz), rng, rng.randf_range(0.8, 1.5))
		elif r < 0.9:
			Nature.tuft(Vector3(fx, fy, fz), rng, rng.randf_range(0.9, 1.7))
		else:
			Nature.flowers(Vector3(fx, fy, fz), rng)
	for i in 120:
		var tx: float = rng.randf_range(-40.0, 40.0)
		var tz: float = rng.randf_range(-28.0, 46.0)
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var pp: Vector3 = Forest.main_pts[rng.randi() % Forest.main_pts.size()]
		tx = pp.x + side * rng.randf_range(2.9, 4.4)
		tz = pp.z + rng.randf_range(-1.0, 1.0)
		if rng.randf() < 0.5:
			Nature.tuft(Vector3(tx, Forest.gy(tx, tz), tz), rng, 1.0)
		else:
			Nature.flowers(Vector3(tx, Forest.gy(tx, tz), tz), rng)
	for i in 55:
		var rx: float = rng.randf_range(-44.0, 44.0)
		var rz: float = rng.randf_range(-28.0, 46.0)
		if Forest.gd(rx, rz) < 3.2:
			continue
		var rs: float = rng.randf_range(0.7, 2.2)
		Nature.rock(root, Vector3(rx, Forest.gy(rx, rz) - 0.2, rz), Vector3(rs, rs * 0.8, rs), rng, rs > 1.4)
	# Montanas lejanas que rodean el bosque
	Nature.mountain(root, Vector3(-95, -4, 20), 40.0, 44.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(100, -4, -10), 40.0, 48.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(10, -4, 105), 44.0, 46.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(-75, -4, -85), 40.0, 44.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(75, -4, -90), 40.0, 44.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(0, -4, -110), 50.0, 56.0, rng, 0.35, false)
	tag(root, Vector3(0, 6.0, 44), "Bosque de Creta")
	Nature.flush(root)
	refresh_cap1(root)
	return {"spawn": Vector3(0, 1.1, 44)}
