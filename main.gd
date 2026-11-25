extends Node3D

const SPEED := 6.0
const GRAVITY := 20.0
const JOY_RADIUS := 110.0

var player: CharacterBody3D
var cam_pivot: Node3D
var camera: Camera3D
var yaw := 0.0
var pitch := -0.4
var joy_id := -1
var look_id := -1
var joy_center := Vector2(220, 520)
var joy_pos := Vector2(220, 520)
var joy_vec := Vector2.ZERO
var ui: Control
var info_label: Label


func _ready() -> void:
	_build_world()
	_build_player()
	_build_camera()
	_build_ui()


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	return m


func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.75, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.75, 0.85)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

	_add_box(Vector3(0, -0.5, 0), Vector3(120, 1, 120), Color(0.35, 0.6, 0.3))
	_add_box(Vector3(0, 0.4, -6), Vector3(4, 0.8, 4), Color(0.85, 0.82, 0.75))
	for i in 12:
		var a := TAU * i / 12.0
		_add_column(Vector3(cos(a) * 14.0, 0, sin(a) * 14.0))


func _add_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	add_child(body)


func _add_column(pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos + Vector3(0, 3, 0)
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = 6.0
	mi.mesh = cm
	mi.material_override = _mat(Color(0.9, 0.88, 0.8))
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 6.0
	cs.shape = shape
	body.add_child(cs)
	add_child(body)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = Vector3(0, 1.1, 8)
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.8
	mi.mesh = cap
	mi.material_override = _mat(Color(0.2, 0.4, 0.9))
	player.add_child(mi)
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.2, 0.2, 0.4)
	nose.mesh = nm
	nose.position = Vector3(0, 0.5, -0.45)
	nose.material_override = _mat(Color(1, 0.8, 0.2))
	player.add_child(nose)
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	cs.shape = shape
	player.add_child(cs)
	add_child(player)


func _build_camera() -> void:
	cam_pivot = Node3D.new()
	add_child(cam_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 6.0)
	cam_pivot.add_child(camera)
	camera.current = true


func _default_joy_center() -> Vector2:
	return Vector2(220, get_viewport().get_visible_rect().size.y - 200)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	layer.add_child(ui)
	info_label = Label.new()
	info_label.position = Vector2(20, 12)
	info_label.add_theme_font_size_override("font_size", 26)
	layer.add_child(info_label)
	joy_center = _default_joy_center()
	joy_pos = joy_center
	ui.queue_redraw()


func _draw_ui() -> void:
	var a := 0.2
	if joy_id != -1:
		a = 0.45
	ui.draw_circle(joy_center, JOY_RADIUS, Color(1, 1, 1, a * 0.5))
	ui.draw_circle(joy_pos, 45.0, Color(1, 1, 1, a + 0.2))


func _input(event: InputEvent) -> void:
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < half and joy_id == -1:
				joy_id = event.index
				joy_center = event.position
				joy_pos = event.position
				joy_vec = Vector2.ZERO
			elif event.position.x >= half and look_id == -1:
				look_id = event.index
		else:
			if event.index == joy_id:
				joy_id = -1
				joy_vec = Vector2.ZERO
				joy_center = _default_joy_center()
				joy_pos = joy_center
			elif event.index == look_id:
				look_id = -1
		ui.queue_redraw()
	elif event is InputEventScreenDrag:
		if event.index == joy_id:
			var d: Vector2 = event.position - joy_center
			if d.length() > JOY_RADIUS:
				d = d.normalized() * JOY_RADIUS
			joy_pos = joy_center + d
			joy_vec = d / JOY_RADIUS
			ui.queue_redraw()
		elif event.index == look_id:
			yaw -= event.relative.x * 0.005
			pitch = clampf(pitch - event.relative.y * 0.005, -1.3, -0.1)


func _physics_process(delta: float) -> void:
	var dir := Vector3(joy_vec.x, 0, joy_vec.y).rotated(Vector3.UP, yaw)
	var vel := player.velocity
	vel.x = dir.x * SPEED
	vel.z = dir.z * SPEED
	if player.is_on_floor():
		vel.y = 0.0
	else:
		vel.y -= GRAVITY * delta
	player.velocity = vel
	player.move_and_slide()
	if dir.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-dir.x, -dir.z), delta * 10.0)


func _process(_delta: float) -> void:
	cam_pivot.global_position = player.global_position + Vector3(0, 1.5, 0)
	cam_pivot.rotation = Vector3(pitch, yaw, 0)
	info_label.text = "FPS: %d\nIzquierda: moverte | Derecha: cámara" % Engine.get_frames_per_second()
