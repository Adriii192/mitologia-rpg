extends RefCounted

# Personaje humano low-poly. Mira hacia -Z. Pies en y=0, altura ~1.8.


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	return m


static func _box(parent: Node3D, pos: Vector3, size: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.material_override = _mat(c)
	mi.position = pos
	parent.add_child(mi)
	return mi


static func _sph(parent: Node3D, pos: Vector3, r: float, c: Color, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	mi.mesh = s
	mi.material_override = _mat(c)
	mi.position = pos
	mi.scale = sc
	parent.add_child(mi)
	return mi


# hair_style: "short", "messy", "long", "bun"
static func build(shirt: Color, pants: Color, skin: Color, hair: Color, hair_style: String = "short", hood: bool = false, shoes: Color = Color(0.93, 0.93, 0.95)) -> Node3D:
	var root := Node3D.new()
	root.name = "Char"
	var body := Node3D.new()
	body.name = "Body"
	body.scale = Vector3(0.88, 0.88, 0.88)
	root.add_child(body)
	# Piernas (pivote en la cadera)
	for sx in [-1.0, 1.0]:
		var leg := Node3D.new()
		leg.name = "LegL" if sx < 0.0 else "LegR"
		leg.position = Vector3(sx * 0.16, 0.84, 0)
		body.add_child(leg)
		_box(leg, Vector3(0, -0.4, 0), Vector3(0.23, 0.8, 0.26), pants)
		_box(leg, Vector3(0, -0.78, -0.07), Vector3(0.26, 0.14, 0.42), shoes)
	# Torso y cinturon
	_box(body, Vector3(0, 1.22, 0), Vector3(0.64, 0.76, 0.36), shirt)
	_box(body, Vector3(0, 0.88, 0), Vector3(0.66, 0.08, 0.38), pants.darkened(0.35))
	# Brazos (pivote en el hombro)
	for sx2 in [-1.0, 1.0]:
		var arm := Node3D.new()
		arm.name = "ArmL" if sx2 < 0.0 else "ArmR"
		arm.position = Vector3(sx2 * 0.42, 1.52, 0)
		body.add_child(arm)
		_box(arm, Vector3(0, -0.3, 0), Vector3(0.18, 0.62, 0.22), shirt)
		_sph(arm, Vector3(0, -0.68, 0), 0.1, skin)
	# Cabeza
	_box(body, Vector3(0, 1.64, 0), Vector3(0.14, 0.12, 0.14), skin)
	_sph(body, Vector3(0, 1.8, 0), 0.27, skin, Vector3(1, 1.05, 1))
	_sph(body, Vector3(-0.1, 1.82, -0.24), 0.04, Color(0.05, 0.05, 0.08))
	_sph(body, Vector3(0.1, 1.82, -0.24), 0.04, Color(0.05, 0.05, 0.08))
	_box(body, Vector3(-0.1, 1.9, -0.26), Vector3(0.12, 0.025, 0.03), hair.darkened(0.2))
	_box(body, Vector3(0.1, 1.9, -0.26), Vector3(0.12, 0.025, 0.03), hair.darkened(0.2))
	_box(body, Vector3(0, 1.7, -0.265), Vector3(0.1, 0.02, 0.02), Color(0.65, 0.3, 0.3))
	# Pelo
	_sph(body, Vector3(0, 1.9, 0.04), 0.29, hair, Vector3(1.0, 0.82, 1.0))
	_box(body, Vector3(0, 2.0, -0.2), Vector3(0.52, 0.1, 0.14), hair)
	if hair_style == "messy":
		for k in 4:
			var tuft := _box(body, Vector3(-0.18 + 0.12 * float(k), 2.12, -0.02 + 0.03 * float(k % 2)), Vector3(0.1, 0.16, 0.1), hair)
			tuft.rotation_degrees = Vector3(0, 0, -20.0 + 13.0 * float(k))
	elif hair_style == "long":
		_box(body, Vector3(0, 1.55, 0.2), Vector3(0.56, 0.75, 0.14), hair)
		_box(body, Vector3(-0.29, 1.75, 0.02), Vector3(0.08, 0.4, 0.3), hair)
		_box(body, Vector3(0.29, 1.75, 0.02), Vector3(0.08, 0.4, 0.3), hair)
	elif hair_style == "bun":
		_sph(body, Vector3(0, 2.15, 0.1), 0.13, hair)
	if hood:
		_sph(body, Vector3(0, 1.62, 0.2), 0.24, shirt, Vector3(1.2, 0.8, 0.8))
	return root


# Anima piernas y brazos. speed: 0 (quieto) a 1 (corriendo)
static func animate(model: Node3D, t: float, speed: float) -> void:
	var body: Node3D = model.get_node_or_null("Body")
	if body == null:
		return
	var s: float = sin(t) * 0.75 * speed
	(body.get_node("LegL") as Node3D).rotation.x = lerpf((body.get_node("LegL") as Node3D).rotation.x, s, 0.5)
	(body.get_node("LegR") as Node3D).rotation.x = lerpf((body.get_node("LegR") as Node3D).rotation.x, -s, 0.5)
	(body.get_node("ArmL") as Node3D).rotation.x = lerpf((body.get_node("ArmL") as Node3D).rotation.x, -s * 0.9, 0.5)
	(body.get_node("ArmR") as Node3D).rotation.x = lerpf((body.get_node("ArmR") as Node3D).rotation.x, s * 0.9, 0.5)
	body.position.y = absf(sin(t)) * 0.05 * speed
