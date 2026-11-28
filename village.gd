extends RefCounted

# Aldea de Melisia: casas blancas de puertas azules entre olivos, con plaza y pozo.

const Zones = preload("res://zones.gd")
const Nature = preload("res://nature.gd")
const Tex = preload("res://textures.gd")
const Companion = preload("res://companion.gd")


static func _prism(parent: Node3D, pos: Vector3, size: Vector3, col: Color, tex_name: String) -> void:
	var mi := MeshInstance3D.new()
	var pm := PrismMesh.new()
	pm.size = size
	mi.mesh = pm
	if tex_name != "":
		mi.material_override = Tex.mat(tex_name, col, 2.0)
	else:
		mi.material_override = Zones.mat(col)
	mi.position = pos
	parent.add_child(mi)


static func house(root: Node3D, pos: Vector3, w: float, d: float, h: float, wallc: Color, roofc: Color, doorc: Color) -> void:
	var g := Node3D.new()
	g.position = pos
	var dir := Vector3(-pos.x, 0, -pos.z)
	g.rotation.y = atan2(dir.x, dir.z)
	root.add_child(g)
	Zones.tbox(g, Vector3(0, h * 0.5, 0), Vector3(w, h, d), "plaster", wallc, 2.5)
	Zones.tdeco(g, Vector3(0, 0.3, 0), Vector3(w + 0.12, 0.6, d + 0.12), "rock", Color(0.9, 0.88, 0.85), 2.0)
	_prism(g, Vector3(0, h + 0.9, 0), Vector3(w + 1.0, 1.8, d + 1.0), roofc, "roof")
	Zones.deco_box(g, Vector3(0, 1.1, d * 0.5 + 0.05), Vector3(1.3, 2.2, 0.12), doorc)
	Zones.deco_box(g, Vector3(0, 2.28, d * 0.5 + 0.04), Vector3(1.6, 0.16, 0.14), Color(0.95, 0.95, 0.92))
	Zones.deco_box(g, Vector3(0, 0.05, d * 0.5 + 0.5), Vector3(1.8, 0.1, 1.0), Color(0.7, 0.68, 0.64))
	for sx in [-1.0, 1.0]:
		var s: float = sx
		var wx: float = s * w * 0.3
		Zones.deco_box(g, Vector3(wx, 1.9, d * 0.5 + 0.05), Vector3(0.9, 0.9, 0.08), Color(0.55, 0.75, 0.9), Vector3.ZERO, 0.35)
		Zones.deco_box(g, Vector3(wx - 0.62, 1.9, d * 0.5 + 0.09), Vector3(0.34, 0.95, 0.06), doorc)
		Zones.deco_box(g, Vector3(wx + 0.62, 1.9, d * 0.5 + 0.09), Vector3(0.34, 0.95, 0.06), doorc)
		Zones.deco_box(g, Vector3(wx, 1.3, d * 0.5 + 0.2), Vector3(1.0, 0.25, 0.3), Color(0.45, 0.3, 0.18))
	Zones.deco_box(g, Vector3(w * 0.3, h + 1.6, -d * 0.2), Vector3(0.6, 1.2, 0.6), Color(0.92, 0.9, 0.85))


static func well(root: Node3D, pos: Vector3) -> void:
	Zones.cylinder(root, pos + Vector3(0, 0.5, 0), 1.35, 1.0, Color(0.66, 0.63, 0.58))
	var water := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 1.05
	cm.bottom_radius = 1.05
	cm.height = 0.05
	water.mesh = cm
	water.material_override = Zones.mat(Color(0.12, 0.35, 0.55))
	water.position = pos + Vector3(0, 0.9, 0)
	root.add_child(water)
	for sx in [-1.2, 1.2]:
		var s: float = sx
		Zones.deco_box(root, pos + Vector3(s, 1.9, 0), Vector3(0.16, 2.0, 0.16), Color(0.45, 0.3, 0.18))
	Zones.deco_box(root, pos + Vector3(0, 2.85, 0), Vector3(2.8, 0.14, 0.2), Color(0.4, 0.27, 0.16))
	_prism(root, pos + Vector3(0, 3.3, 0), Vector3(3.2, 0.9, 1.8), Color(0.62, 0.3, 0.22), "roof")
	Zones.deco_box(root, pos + Vector3(0, 2.1, 0), Vector3(0.04, 1.4, 0.04), Color(0.3, 0.2, 0.12))
	Zones.deco_box(root, pos + Vector3(0, 1.4, 0), Vector3(0.35, 0.3, 0.35), Color(0.5, 0.35, 0.2))


static func stall(root: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	Zones.box(root, pos + Vector3(0, 0.45, 0), Vector3(3.0, 0.9, 1.3), Color(0.5, 0.35, 0.2))
	for sx in [-1.4, 1.4]:
		var s: float = sx
		Zones.deco_box(root, pos + Vector3(s, 1.6, -0.55), Vector3(0.12, 3.0, 0.12), Color(0.4, 0.28, 0.16))
		Zones.deco_box(root, pos + Vector3(s, 1.4, 0.55), Vector3(0.12, 2.6, 0.12), Color(0.4, 0.28, 0.16))
	for k in 6:
		var c: Color = Color(0.85, 0.2, 0.2) if k % 2 == 0 else Color(0.95, 0.93, 0.88)
		Zones.deco_box(root, pos + Vector3(-1.25 + float(k) * 0.5, 3.0 - 0.1, 0.0), Vector3(0.5, 0.08, 1.9), c, Vector3(12, 0, 0))
	for i in 14:
		var fc: Color = [Color(0.9, 0.25, 0.2), Color(0.95, 0.6, 0.15), Color(0.5, 0.75, 0.25)][rng.randi() % 3]
		Nature.add("blob", pos + Vector3(rng.randf_range(-1.2, 1.2), 1.0, rng.randf_range(-0.4, 0.4)), Vector3(0.15, 0.15, 0.15), Vector3.ZERO, fc)


static func build(root: Node3D) -> Dictionary:
	var env: Environment = Zones.environment(root, Color(0.58, 0.8, 0.96), Color(0.75, 0.78, 0.82), 0.75, 0.9, Color(1.0, 0.95, 0.84))
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.52, 0.88)
	sky_mat.sky_horizon_color = Color(0.8, 0.9, 0.95)
	sky_mat.ground_horizon_color = Color(0.7, 0.82, 0.8)
	sky_mat.ground_bottom_color = Color(0.4, 0.55, 0.4)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_enabled = true
	env.fog_light_color = Color(0.78, 0.88, 0.9)
	env.fog_density = 0.006
	env.fog_sky_affect = 0.15
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	Zones.tbox(root, Vector3(0, -0.5, 0), Vector3(100, 1, 100), "grass", Color(0.9, 1.0, 0.8), 4.0)
	Zones.wall(root, Vector3(0, 3, 47.5), Vector3(100, 6, 1))
	Zones.wall(root, Vector3(0, 3, -47.5), Vector3(100, 6, 1))
	Zones.wall(root, Vector3(-47.5, 3, 0), Vector3(1, 6, 100))
	Zones.wall(root, Vector3(47.5, 3, 0), Vector3(1, 6, 100))
	# Plaza y caminos de tierra
	var plaza := MeshInstance3D.new()
	var pc := CylinderMesh.new()
	pc.top_radius = 10.0
	pc.bottom_radius = 10.0
	pc.height = 0.05
	pc.radial_segments = 20
	plaza.mesh = pc
	plaza.material_override = Tex.mat("dirt", Color(1.0, 0.95, 0.85), 2.0)
	plaza.position = Vector3(0, 0.025, 0)
	root.add_child(plaza)
	Zones.tdeco(root, Vector3(0, 0.03, 27), Vector3(4.0, 0.04, 36), "dirt", Color(1, 1, 1), 2.0)
	Zones.tdeco(root, Vector3(0, 0.03, -16), Vector3(3.2, 0.04, 14), "dirt", Color(1, 1, 1), 2.0)
	Zones.tdeco(root, Vector3(-17, 0.03, 0), Vector3(14, 0.04, 2.6), "dirt", Color(1, 1, 1), 2.0)
	Zones.tdeco(root, Vector3(17, 0.03, 0), Vector3(14, 0.04, 2.6), "dirt", Color(1, 1, 1), 2.0)
	well(root, Vector3(0, 0, 0))
	stall(root, Vector3(7.5, 0, 6.5), rng)
	# Casas
	var wall_c: Array = [Color(0.96, 0.95, 0.92), Color(0.98, 0.93, 0.85), Color(0.93, 0.95, 0.97)]
	var roof_c: Array = [Color(0.95, 0.65, 0.5), Color(0.9, 0.6, 0.48), Color(0.85, 0.55, 0.45)]
	var door_c: Array = [Color(0.15, 0.42, 0.78), Color(0.2, 0.5, 0.72), Color(0.12, 0.35, 0.65)]
	var spots: Array = [Vector3(-19, 0, -8), Vector3(-21, 0, 10), Vector3(19, 0, -10), Vector3(21, 0, 9), Vector3(-10, 0, -22), Vector3(11, 0, -23), Vector3(-12, 0, 20), Vector3(12, 0, 22)]
	var i: int = 0
	for sp in spots:
		var v: Vector3 = sp
		house(root, v, rng.randf_range(6.0, 8.0), rng.randf_range(5.5, 7.0), 3.3, wall_c[i % 3], roof_c[i % 3], door_c[i % 3])
		i += 1
	house(root, Vector3(0, 0, -31), 11.0, 7.5, 3.8, Color(0.98, 0.97, 0.94), Color(0.78, 0.45, 0.35), Color(0.1, 0.3, 0.62))
	Zones.tag(root, Vector3(0, 8.0, -31), "Casa del anciano")
	# Cantaros, cercas, flores y olivos
	for k in 18:
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(8.5, 22.0)
		var ap := Vector3(cos(a) * r, 0, sin(a) * r)
		Nature.add("blob", ap + Vector3(0, 0.5, 0), Vector3(0.38, 0.5, 0.38), Vector3.ZERO, Color(0.78, 0.42, 0.26))
		Nature.add("blob", ap + Vector3(0, 1.0, 0), Vector3(0.2, 0.18, 0.2), Vector3.ZERO, Color(0.7, 0.36, 0.22))
	for k in 40:
		var fx: float = rng.randf_range(-40.0, 40.0)
		var fz: float = rng.randf_range(-40.0, 44.0)
		if Vector2(fx, fz).length() < 12.0 or absf(fx) < 3.0:
			continue
		var rr: float = rng.randf()
		if rr < 0.4:
			Nature.flowers(Vector3(fx, 0, fz), rng)
		elif rr < 0.8:
			Nature.tuft(Vector3(fx, 0, fz), rng, 1.2)
		else:
			Nature.bush(Vector3(fx, 0, fz), rng, 1.0)
	var placed: int = 0
	var tries: int = 0
	while placed < 90 and tries < 600:
		tries += 1
		var tx: float = rng.randf_range(-45.0, 45.0)
		var tz: float = rng.randf_range(-45.0, 45.0)
		var p := Vector2(tx, tz)
		if p.length() < 14.0 or absf(tx) < 5.0 or (absf(tz) < 4.0 and absf(tx) < 30.0):
			continue
		var near: bool = false
		for sp2 in spots:
			var v2: Vector3 = sp2
			if Vector2(tx - v2.x, tz - v2.z).length() < 7.5:
				near = true
		if Vector2(tx, tz + 31.0).length() < 9.0:
			near = true
		if near:
			continue
		Nature.lush_tree(root, Vector3(tx, 0, tz), rng, true, 0.9)
		placed += 1
	# Montanas de fondo y nubes
	Nature.mountain(root, Vector3(-95, -2, 0), 40.0, 40.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(95, -2, 10), 40.0, 44.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(0, -2, -100), 48.0, 50.0, rng, 0.35, false)
	Nature.mountain(root, Vector3(10, -2, 100), 44.0, 40.0, rng, 0.35, false)
	Nature.clouds(rng, 10)
	# Luces
	var l1 := OmniLight3D.new()
	l1.light_color = Color(1.0, 0.9, 0.7)
	l1.light_energy = 0.5
	l1.omni_range = 16.0
	l1.position = Vector3(0, 5, 2)
	root.add_child(l1)
	# Aldeanos
	_npc(root, "Anciano", Color(0.85, 0.8, 0.7), Vector3(0, 0, -23.5), "anciano", 0.0)
	_npc(root, "Aldeana", Color(0.7, 0.3, 0.3), Vector3(-5.5, 0, 4.0), "aldeana", 70.0)
	_npc(root, "Pastor", Color(0.55, 0.5, 0.35), Vector3(14.0, 0, -4.0), "pastor", -80.0)
	_npc(root, "Aldeano", Color(0.35, 0.5, 0.7), Vector3(5.5, 0, 10.0), "aldeano", 190.0)
	_npc(root, "Niño", Color(0.9, 0.7, 0.2), Vector3(-4.0, 0, -6.0), "nino", 40.0)
	if State_has_nika(root):
		_npc(root, "Nika", Color(0.2, 0.6, 0.35), Vector3(-8.0, 0, -14.0), "nika", 30.0)
	Zones.portal(root, Vector3(0, 0, 45), "cap1", "Volver al bosque", Color(0.3, 0.6, 1.0))
	Nature.flush(root)
	return {"spawn": Vector3(0, 1.1, 38)}


static func State_has_nika(root: Node3D) -> bool:
	return bool(root.get_meta("has_nika", false))


static func _npc(root: Node3D, label: String, col: Color, pos: Vector3, id: String, yaw_deg: float) -> void:
	var n: Node3D = Companion.person(col, label)
	n.name = label
	n.position = pos
	n.rotation.y = deg_to_rad(yaw_deg)
	root.add_child(n)
	Zones.interact(root, pos, "talk", id, "HABLAR", "")
