extends RefCounted

# Modelos de monstruos para el mundo (miran hacia -Z).


static func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.85
	return m


static func _part(parent: Node3D, mesh: Mesh, pos: Vector3, c: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _mat(c)
	mi.position = pos
	mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


static func _sph(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 10
	s.rings = 5
	return s


static func _cap(r: float, h: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = r
	c.height = h
	c.radial_segments = 10
	c.rings = 3
	return c


static func _cone(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = 0.0
	c.bottom_radius = r
	c.height = h
	c.radial_segments = 8
	return c


static func _cyl(rt: float, rb: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = rt
	c.bottom_radius = rb
	c.height = h
	c.radial_segments = 8
	return c


static func _box(x: float, y: float, z: float) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = Vector3(x, y, z)
	return b


static func build(kind: String, col: Color) -> Node3D:
	var root := Node3D.new()
	if kind == "satiro":
		var fur: Color = Color(0.45, 0.28, 0.17)
		var skin: Color = Color(0.82, 0.6, 0.42)
		for sx in [-1.0, 1.0]:
			var s: float = sx
			_part(root, _cyl(0.1, 0.15, 0.85), Vector3(s * 0.22, 0.5, 0.05), fur, Vector3(-8, 0, 0))
			_part(root, _box(0.2, 0.12, 0.3), Vector3(s * 0.22, 0.06, -0.02), Color(0.15, 0.1, 0.08))
			_part(root, _cap(0.11, 0.7), Vector3(s * 0.52, 1.35, -0.05), skin, Vector3(0, 0, s * 18.0))
		_part(root, _cap(0.38, 1.1), Vector3(0, 1.3, 0), skin)
		_part(root, _sph(0.4), Vector3(0, 0.95, 0.05), col)
		_part(root, _sph(0.3), Vector3(0, 2.05, 0), skin)
		_part(root, _cone(0.14, 0.4), Vector3(0, 1.78, -0.24), fur, Vector3(180, 0, 0))
		for sx2 in [-1.0, 1.0]:
			var s2: float = sx2
			_part(root, _cone(0.08, 0.5), Vector3(s2 * 0.2, 2.45, 0.02), Color(0.92, 0.88, 0.75), Vector3(0, 0, -s2 * 22.0))
			_part(root, _cone(0.07, 0.3), Vector3(s2 * 0.34, 2.08, 0.03), skin, Vector3(0, 0, -s2 * 80.0))
			_part(root, _sph(0.045), Vector3(s2 * 0.12, 2.1, -0.26), Color(1.0, 0.2, 0.1))
		_part(root, _cone(0.08, 0.3), Vector3(0, 0.9, 0.42), fur, Vector3(-60, 0, 0))
		return root
	# Arpia (y Aelo): cuerpo con plumas, alas y garras. Vuela un poco por encima del suelo.
	var fly := Node3D.new()
	fly.name = "Fly"
	fly.position = Vector3(0, 0.9, 0)
	root.add_child(fly)
	var dark: Color = col.darkened(0.3)
	var light: Color = col.lightened(0.3)
	_part(fly, _cap(0.32, 1.3), Vector3(0, 1.0, 0), col)
	_part(fly, _sph(0.34), Vector3(0, 0.75, -0.08), light)
	_part(fly, _sph(0.26), Vector3(0, 1.85, 0), Color(0.86, 0.66, 0.52))
	_part(fly, _cone(0.09, 0.3), Vector3(0, 1.8, -0.3), Color(0.95, 0.8, 0.3), Vector3(-90, 0, 0))
	for sx3 in [-1.0, 1.0]:
		var s3: float = sx3
		_part(fly, _sph(0.045), Vector3(s3 * 0.1, 1.9, -0.22), Color(1.0, 0.15, 0.1))
		_part(fly, _cone(0.1, 0.5), Vector3(s3 * 0.14, 2.2, 0.05), dark, Vector3(0, 0, -s3 * 25.0))
		_part(fly, _cone(0.06, 0.4), Vector3(s3 * 0.14, 0.35, -0.08), Color(0.9, 0.75, 0.3), Vector3(180, 0, 0))
		var wing := Node3D.new()
		wing.name = "Wing" + ("L" if s3 < 0.0 else "R")
		wing.position = Vector3(s3 * 0.3, 1.45, 0.05)
		fly.add_child(wing)
		_part(wing, _box(1.3, 0.05, 0.75), Vector3(s3 * 0.65, 0.0, 0.0), dark)
		for k in 4:
			_part(wing, _cone(0.09, 0.55), Vector3(s3 * (0.4 + float(k) * 0.3), -0.02, 0.5), light, Vector3(90, 0, 0))
	_part(fly, _cone(0.18, 0.7), Vector3(0, 0.35, 0.32), dark, Vector3(-150, 0, 0))
	return root
