extends RefCounted

# Terreno del bosque de Creta: mapa de alturas con camino serpenteante,
# senderos laterales, claros y colinas. Todo generado por codigo.

const Tex = preload("res://textures.gd")

const GN := 51
const GC := 2.0
const GO := -50.0

const MAIN := [
	Vector3(0, 0.0, 52), Vector3(0, 0.0, 40), Vector3(0, 0.3, 32), Vector3(10, 1.0, 25),
	Vector3(14, 2.2, 14), Vector3(6, 3.4, 4), Vector3(-8, 3.4, -2), Vector3(-15, 2.4, -12),
	Vector3(-9, 1.2, -21), Vector3(-1, 0.3, -28), Vector3(0, 0.0, -33),
]
const BR_W := [Vector3(-8, 3.4, -2), Vector3(-15, 3.2, 0), Vector3(-22, 2.9, -3), Vector3(-27, 2.8, -4)]
const BR_V := [Vector3(0, 0.3, 32), Vector3(-9, 0.3, 31), Vector3(-18, 0.5, 34), Vector3(-27, 0.7, 38), Vector3(-36, 0.8, 40), Vector3(-44, 0.8, 40)]
const BR_E := [Vector3(10, 1.0, 25), Vector3(20, 0.95, 28), Vector3(28, 1.0, 27), Vector3(34, 1.0, 25)]
# centro (con altura), radio plano, ancho de transicion
const CLEAR := [
	[Vector3(-27, 2.8, -4), 5.0, 4.0],
	[Vector3(34, 1.0, 25), 5.0, 4.0],
	[Vector3(-31, 6.5, -19), 4.5, 3.5],
	[Vector3(31, 5.5, -14), 4.5, 3.5],
]

static var hg: PackedFloat32Array = PackedFloat32Array()
static var dg: PackedFloat32Array = PackedFloat32Array()
static var main_pts: Array = []
static var br_pts: Array = []
static var built: bool = false


static func _sample(pts: Array, step: float) -> Array:
	var out: Array = []
	var n: int = pts.size()
	for i in n - 1:
		var p0: Vector3 = pts[maxi(i - 1, 0)]
		var p1: Vector3 = pts[i]
		var p2: Vector3 = pts[i + 1]
		var p3: Vector3 = pts[mini(i + 2, n - 1)]
		var len: float = p1.distance_to(p2)
		var k: int = maxi(1, int(len / step))
		for j in k:
			out.append(p1.cubic_interpolate(p2, p0, p3, float(j) / float(k)))
	out.append(pts[n - 1])
	return out


static func _hills(x: float, z: float) -> float:
	var h: float = 3.2 + 2.0 * sin(x * 0.10 + 1.3) * cos(z * 0.085 + 0.4) + 1.5 * sin(x * 0.17 - z * 0.12 + 2.0) + 0.9 * sin(z * 0.21 + x * 0.06)
	return maxf(h, 0.8)


static func build_grid() -> void:
	main_pts = _sample(MAIN, 1.5)
	br_pts = [_sample(BR_W, 1.5), _sample(BR_E, 1.5), _sample(BR_V, 1.5)]
	var xs: PackedFloat32Array = PackedFloat32Array()
	var zs: PackedFloat32Array = PackedFloat32Array()
	var ys: PackedFloat32Array = PackedFloat32Array()
	var all: Array = [main_pts, br_pts[0], br_pts[1], br_pts[2]]
	for arr in all:
		for p in arr:
			var v: Vector3 = p
			xs.append(v.x)
			zs.append(v.z)
			ys.append(v.y)
	hg.resize(GN * GN)
	dg.resize(GN * GN)
	var np: int = xs.size()
	for iz in GN:
		for ix in GN:
			var x: float = GO + float(ix) * GC
			var z: float = GO + float(iz) * GC
			var best: float = 1.0e9
			var by: float = 0.0
			for i in np:
				var dx: float = xs[i] - x
				var dz: float = zs[i] - z
				var d2: float = dx * dx + dz * dz
				if d2 < best:
					best = d2
					by = ys[i]
			var d: float = sqrt(best)
			var s: float = smoothstep(3.0, 9.5, d)
			var h: float = lerpf(by, _hills(x, z), s)
			var dd: float = d
			for c in CLEAR:
				var cc: Vector3 = c[0]
				var r: float = c[1]
				var bl: float = c[2]
				var dc: float = Vector2(x - cc.x, z - cc.z).length()
				var m: float = 1.0 - smoothstep(r, r + bl, dc)
				h = lerpf(h, cc.y, m)
				dd = minf(dd, dc - r)
			var e: float = smoothstep(34.0, 47.0, maxf(absf(x), absf(z)))
			h += e * 16.0 * s
			var mz: float = smoothstep(0.0, 1.0, clampf((-27.0 - z) / 5.0, 0.0, 1.0))
			var mx: float = 1.0 - smoothstep(16.0, 24.0, absf(x))
			h = lerpf(h, 0.0, mz * mx)
			hg[iz * GN + ix] = h
			dg[iz * GN + ix] = dd
	built = true


static func _g(arr: PackedFloat32Array, x: float, z: float) -> float:
	var fx: float = clampf((x - GO) / GC, 0.0, float(GN) - 1.001)
	var fz: float = clampf((z - GO) / GC, 0.0, float(GN) - 1.001)
	var ix: int = int(fx)
	var iz: int = int(fz)
	var tx: float = fx - float(ix)
	var tz: float = fz - float(iz)
	var a: float = lerpf(arr[iz * GN + ix], arr[iz * GN + ix + 1], tx)
	var b: float = lerpf(arr[(iz + 1) * GN + ix], arr[(iz + 1) * GN + ix + 1], tx)
	return lerpf(a, b, tz)


# Altura del suelo en (x, z)
static func gy(x: float, z: float) -> float:
	if not built:
		return 0.0
	return _g(hg, x, z)


# Distancia al camino/claro mas cercano (negativa dentro de un claro)
static func gd(x: float, z: float) -> float:
	if not built:
		return 99.0
	return _g(dg, x, z)


static func slope(x: float, z: float) -> float:
	var dx: float = gy(x + 1.0, z) - gy(x - 1.0, z)
	var dz: float = gy(x, z + 1.0) - gy(x, z - 1.0)
	return sqrt(dx * dx + dz * dz) * 0.5


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	if n.y < 0.0:
		n = -n
	st.set_normal(n)
	st.set_color(ca)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_color(cb)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_color(cc)
	st.add_vertex(c)


static func terrain(root: Node3D) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: Array = []
	for iz in GN:
		for ix in GN:
			var x: float = GO + float(ix) * GC
			var z: float = GO + float(iz) * GC
			var sl: float = slope(x, z)
			var t: float = smoothstep(0.55, 1.1, sl)
			var jitter: float = 0.9 + 0.1 * sin(x * 0.7) * cos(z * 0.9)
			var c: Color = Color(0.85, 1.0, 0.72).lerp(Color(0.78, 0.7, 0.6), t) * jitter
			cols.append(Color(c.r, c.g, c.b, 1.0))
	for iz in GN - 1:
		for ix in GN - 1:
			var x0: float = GO + float(ix) * GC
			var z0: float = GO + float(iz) * GC
			var a := Vector3(x0, hg[iz * GN + ix], z0)
			var b := Vector3(x0 + GC, hg[iz * GN + ix + 1], z0)
			var c := Vector3(x0, hg[(iz + 1) * GN + ix], z0 + GC)
			var d := Vector3(x0 + GC, hg[(iz + 1) * GN + ix + 1], z0 + GC)
			var ca: Color = cols[iz * GN + ix]
			var cb: Color = cols[iz * GN + ix + 1]
			var cc: Color = cols[(iz + 1) * GN + ix]
			var cd: Color = cols[(iz + 1) * GN + ix + 1]
			_tri(st, a, b, c, ca, cb, cc)
			_tri(st, b, d, c, cb, cd, cc)
	var mesh: ArrayMesh = st.commit()
	var gm: StandardMaterial3D = Tex.mat("grass", Color(1, 1, 1), 4.0).duplicate() as StandardMaterial3D
	gm.vertex_color_use_as_albedo = true
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = gm
	var body := StaticBody3D.new()
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var ts: ConcavePolygonShape3D = mesh.create_trimesh_shape()
	ts.backface_collision = true
	cs.shape = ts
	body.add_child(cs)
	root.add_child(body)
	# Camino de tierra (cinta sobre el terreno)
	var all: Array = [main_pts, br_pts[0], br_pts[1], br_pts[2]]
	for arr in all:
		_ribbon(root, arr, 4.8)


static func _ribbon(root: Node3D, pts: Array, w: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n: int = pts.size()
	var ls: Array = []
	var rs: Array = []
	for i in n:
		var p: Vector3 = pts[i]
		var q: Vector3 = pts[mini(i + 1, n - 1)]
		var o: Vector3 = pts[maxi(i - 1, 0)]
		var dir: Vector3 = q - o
		dir.y = 0.0
		dir = dir.normalized()
		var nr := Vector3(-dir.z, 0, dir.x)
		var half: float = w * 0.5
		if i == 0 or i == n - 1:
			half *= 0.8
		ls.append(p - nr * half + Vector3(0, 0.1, 0))
		rs.append(p + nr * half + Vector3(0, 0.1, 0))
	var white := Color(1, 1, 1)
	for i in n - 1:
		_tri(st, ls[i], rs[i], ls[i + 1], white, white, white)
		_tri(st, rs[i], rs[i + 1], ls[i + 1], white, white, white)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var dm: StandardMaterial3D = Tex.mat("dirt", Color(1, 1, 1), 2.0).duplicate() as StandardMaterial3D
	dm.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = dm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
