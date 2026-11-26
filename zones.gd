extends RefCounted

const Companion = preload("res://companion.gd")


static func mat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	return m


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


static func environment(root: Node3D, bg: Color, ambient: Color, ambient_energy: float, sun_energy: float, sun_color: Color) -> void:
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
		box(root, v - Vector3(0, 0.3, 0), Vector3(3, 0.6, 3), color)


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
	cylinder(root, pos + Vector3(0, 1.0, 0), 0.4, 2.0, Color(0.35, 0.22, 0.12))
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
	environment(root, Color(0.58, 0.8, 0.96), Color(0.7, 0.75, 0.85), 0.55, 0.8, Color(1.0, 0.96, 0.88))
	# Arena
	box(root, Vector3(0, -0.5, 26), Vector3(120, 1, 70), Color(0.76, 0.64, 0.4))
	# Mar (solo visual) y espuma animada
	deco_box(root, Vector3(0, -0.9, -50), Vector3(240, 1, 90), Color(0.15, 0.45, 0.75))
	var foam := deco_box(root, Vector3(0, 0.03, -6.5), Vector3(120, 0.05, 1.0), Color(1, 1, 1, 1))
	var tw := foam.create_tween().set_loops()
	tw.tween_property(foam, "position:z", -4.8, 2.4).set_trans(Tween.TRANS_SINE)
	tw.tween_property(foam, "position:z", -6.8, 2.4).set_trans(Tween.TRANS_SINE)
	# Paredes invisibles
	wall(root, Vector3(0, 1.5, -7.6), Vector3(120, 3, 0.6))
	wall(root, Vector3(-59.5, 1.5, 26), Vector3(0.6, 3, 70))
	wall(root, Vector3(59.5, 1.5, 26), Vector3(0.6, 3, 70))
	wall(root, Vector3(0, 1.5, 60.5), Vector3(120, 3, 0.6))
	# Palmeras
	palm(root, Vector3(-16, 0, 4), 6.0)
	palm(root, Vector3(18, 0, 10), -7.0)
	palm(root, Vector3(-22, 0, 24), 5.0)
	palm(root, Vector3(25, 0, 28), -5.0)
	palm(root, Vector3(-9, 0, 40), 4.0)
	palm(root, Vector3(12, 0, 44), -4.0)
	# Restos del naufragio
	deco_box(root, Vector3(-13, 0.9, 13), Vector3(0.5, 2.0, 8.0), Color(0.42, 0.28, 0.16), Vector3(0, 18, 12))
	deco_box(root, Vector3(-10.5, 0.6, 11.5), Vector3(0.5, 1.4, 6.0), Color(0.48, 0.32, 0.18), Vector3(0, 28, -15))
	deco_box(root, Vector3(-15.5, 3.0, 15), Vector3(0.35, 6.0, 0.35), Color(0.4, 0.27, 0.15), Vector3(18, 0, 22))
	deco_box(root, Vector3(-14.4, 3.6, 15.2), Vector3(0.05, 2.8, 2.2), Color(0.95, 0.93, 0.88), Vector3(18, 0, 22))
	box(root, Vector3(-6, 0.45, 9), Vector3(1.0, 0.9, 1.0), Color(0.5, 0.33, 0.18))
	box(root, Vector3(-7.1, 0.35, 10.2), Vector3(0.8, 0.7, 0.8), Color(0.45, 0.3, 0.17))
	box(root, Vector3(8, 0.3, 17), Vector3(2.0, 0.6, 1.4), Color(0.55, 0.52, 0.48))
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
	portal(root, Vector3(0, 0, 36), "world", "Adentrarse en la isla", Color(0.3, 0.6, 1.0))
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
