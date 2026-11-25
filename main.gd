extends Node3D

const Zones = preload("res://zones.gd")

const HERO_NAME := "Aris"
const SPEED := 6.0
const GRAVITY := 20.0
const JUMP_SPEED := 9.0
const JOY_RADIUS := 110.0
const BTN_RADIUS := 80.0

var player: CharacterBody3D
var cam_pivot: Node3D
var camera: Camera3D
var zone: Node3D
var spawn_point := Vector3(0, 1.1, 8)
var yaw := 0.0
var pitch := -0.4
var joy_id := -1
var look_id := -1
var jump_id := -1
var act_id := -1
var joy_center := Vector2(220, 520)
var joy_pos := Vector2(220, 520)
var joy_vec := Vector2.ZERO
var jump_buffer := 0.0
var coyote := 0.0
var near_portal: Node3D = null
var traveling := false
var ui: Control
var info_label: Label
var fade: ColorRect


func _ready() -> void:
	_build_player()
	_build_camera()
	_build_ui()
	_load_zone("world")


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size


func _jump_pos() -> Vector2:
	return Vector2(_view().x - 170, _view().y - 170)


func _act_pos() -> Vector2:
	return Vector2(_view().x - 370, _view().y - 130)


func _default_joy_center() -> Vector2:
	return Vector2(220, _view().y - 200)


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.position = spawn_point
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.4
	cap.height = 1.8
	mi.mesh = cap
	mi.material_override = Zones.mat(Color(0.2, 0.4, 0.9))
	player.add_child(mi)
	var nose := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.2, 0.2, 0.4)
	nose.mesh = nm
	nose.position = Vector3(0, 0.5, -0.45)
	nose.material_override = Zones.mat(Color(1, 0.8, 0.2))
	player.add_child(nose)
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	cs.shape = shape
	player.add_child(cs)
	var name_tag := Label3D.new()
	name_tag.text = HERO_NAME
	name_tag.font_size = 48
	name_tag.pixel_size = 0.01
	name_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_tag.position = Vector3(0, 1.4, 0)
	player.add_child(name_tag)
	add_child(player)


func _build_camera() -> void:
	cam_pivot = Node3D.new()
	add_child(cam_pivot)
	camera = Camera3D.new()
	camera.position = Vector3(0, 0, 6.0)
	cam_pivot.add_child(camera)
	camera.current = true


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
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	joy_center = _default_joy_center()
	joy_pos = joy_center
	ui.queue_redraw()


func _draw_button_text(text: String, center: Vector2) -> void:
	var font := ThemeDB.fallback_font
	ui.draw_string(font, Vector2(center.x - BTN_RADIUS, center.y + 9), text, HORIZONTAL_ALIGNMENT_CENTER, BTN_RADIUS * 2.0, 26, Color(1, 1, 1, 0.95))


func _draw_ui() -> void:
	var a := 0.2
	if joy_id != -1:
		a = 0.45
	ui.draw_circle(joy_center, JOY_RADIUS, Color(1, 1, 1, a * 0.5))
	ui.draw_circle(joy_pos, 45.0, Color(1, 1, 1, a + 0.2))
	var ja := 0.3
	if jump_id != -1:
		ja = 0.55
	ui.draw_circle(_jump_pos(), BTN_RADIUS, Color(1, 1, 1, ja))
	_draw_button_text("SALTAR", _jump_pos())
	if near_portal != null:
		var aa := 0.45
		if act_id != -1:
			aa = 0.7
		ui.draw_circle(_act_pos(), BTN_RADIUS, Color(1, 0.85, 0.3, aa))
		_draw_button_text("VIAJAR", _act_pos())


func _load_zone(zone_name: String) -> void:
	if zone != null:
		remove_child(zone)
		zone.queue_free()
	zone = Node3D.new()
	add_child(zone)
	var info: Dictionary
	if zone_name == "camp":
		info = Zones.build_camp(zone)
	else:
		info = Zones.build_world(zone)
	spawn_point = info["spawn"]
	player.position = spawn_point
	player.velocity = Vector3.ZERO
	near_portal = null
	ui.queue_redraw()


func _travel(target: String) -> void:
	if traveling:
		return
	traveling = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.35)
	await tw.finished
	_load_zone(target)
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.35)
	await tw2.finished
	traveling = false


func _input(event: InputEvent) -> void:
	var half := _view().x * 0.5
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			if pos.distance_to(_jump_pos()) < BTN_RADIUS * 1.2 and jump_id == -1:
				jump_id = event.index
				jump_buffer = 0.15
			elif near_portal != null and pos.distance_to(_act_pos()) < BTN_RADIUS * 1.2 and act_id == -1:
				act_id = event.index
				_travel(str(near_portal.get_meta("target")))
			elif pos.x < half and joy_id == -1:
				joy_id = event.index
				joy_center = pos
				joy_pos = pos
				joy_vec = Vector2.ZERO
			elif pos.x >= half and look_id == -1:
				look_id = event.index
		else:
			if event.index == jump_id:
				jump_id = -1
			elif event.index == act_id:
				act_id = -1
			elif event.index == joy_id:
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
	if traveling:
		return
	var dir := Vector3(joy_vec.x, 0, joy_vec.y).rotated(Vector3.UP, yaw)
	var vel := player.velocity
	vel.x = dir.x * SPEED
	vel.z = dir.z * SPEED
	if player.is_on_floor() and vel.y <= 0.0:
		coyote = 0.12
		vel.y = 0.0
	else:
		coyote -= delta
		vel.y -= GRAVITY * delta
	jump_buffer -= delta
	if jump_buffer > 0.0 and coyote > 0.0:
		vel.y = JUMP_SPEED
		jump_buffer = 0.0
		coyote = 0.0
	player.velocity = vel
	player.move_and_slide()
	if dir.length() > 0.1:
		player.rotation.y = lerp_angle(player.rotation.y, atan2(-dir.x, -dir.z), delta * 10.0)
	if player.position.y < -15.0:
		player.position = spawn_point
		player.velocity = Vector3.ZERO


func _process(_delta: float) -> void:
	cam_pivot.global_position = player.global_position + Vector3(0, 1.5, 0)
	cam_pivot.rotation = Vector3(pitch, yaw, 0)
	var found: Node3D = null
	for n in get_tree().get_nodes_in_group("portals"):
		var p := n as Node3D
		var dx := p.global_position.x - player.global_position.x
		var dz := p.global_position.z - player.global_position.z
		if Vector2(dx, dz).length() < 2.4 and absf(p.global_position.y - player.global_position.y) < 3.0:
			found = p
	if found != near_portal:
		near_portal = found
		ui.queue_redraw()
	info_label.text = "%s  |  FPS: %d\nIzq: moverte · Der: cámara" % [HERO_NAME, Engine.get_frames_per_second()]
