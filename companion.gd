extends RefCounted


static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, emission: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


static func _sphere(r: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	return sm


static func _cyl(r: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	return cm


static func _cone(r: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	return cm


# Amaltea: cabrita juvenil. Mira hacia -Z.
static func build() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.name = "Body"
	root.add_child(body)
	var cream := Color(0.98, 0.95, 0.88)
	var tan := Color(0.86, 0.76, 0.6)
	var gold := Color(1.0, 0.8, 0.25)
	var cap := CapsuleMesh.new()
	cap.radius = 0.3
	cap.height = 1.0
	_part(body, cap, Vector3(0, 0.58, 0.05), cream, Vector3(90, 0, 0))
	_part(body, _sphere(0.3), Vector3(0, 0.95, -0.5), cream)
	_part(body, _sphere(0.12), Vector3(0, 0.84, -0.76), Color(0.96, 0.78, 0.72))
	_part(body, _sphere(0.05), Vector3(-0.13, 1.0, -0.72), Color(0.05, 0.05, 0.05))
	_part(body, _sphere(0.05), Vector3(0.13, 1.0, -0.72), Color(0.05, 0.05, 0.05))
	var ear_mesh := BoxMesh.new()
	ear_mesh.size = Vector3(0.3, 0.05, 0.16)
	_part(body, ear_mesh, Vector3(-0.32, 0.98, -0.48), tan, Vector3(0, 0, 35))
	_part(body, ear_mesh, Vector3(0.32, 0.98, -0.48), tan, Vector3(0, 0, -35))
	_part(body, _cone(0.06, 0.34), Vector3(-0.12, 1.3, -0.5), gold, Vector3(0, 0, 18), 0.6)
	_part(body, _cone(0.06, 0.26), Vector3(0.12, 1.26, -0.5), gold, Vector3(0, 0, -18), 0.6)
	_part(body, _sphere(0.045), Vector3(-0.2, 1.46, -0.5), Color(1.0, 0.9, 0.5), Vector3.ZERO, 3.0)
	for lx in [-0.16, 0.16]:
		for lz in [-0.22, 0.34]:
			_part(body, _cyl(0.05, 0.42), Vector3(lx, 0.21, lz), tan)
	_part(body, _sphere(0.09), Vector3(0, 0.7, 0.6), cream)
	var tag := Label3D.new()
	tag.text = "Amaltea"
	tag.font_size = 40
	tag.pixel_size = 0.01
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.0, 0)
	root.add_child(tag)
	return root
