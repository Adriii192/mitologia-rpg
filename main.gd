extends Node3D

const Zones = preload("res://zones.gd")
const State = preload("res://state.gd")
const Battle = preload("res://battle.gd")
const Dialog = preload("res://dialog.gd")
const Companion = preload("res://companion.gd")

const SPEED := 6.0
const GRAVITY := 20.0
const JUMP_SPEED := 9.0
const JOY_RADIUS := 110.0
const BTN_RADIUS := 80.0

var player: CharacterBody3D
var cam_pivot: Node3D
var camera: Camera3D
var zone: Node3D
var current_zone: String = "beach"
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
var in_battle := false
var in_dialog := false
var locked := false
var battle = null
var dialog = null
var battle_enemy: Node3D = null
var companion: Node3D = null
var grace := 0.0
var hint_timer := 0.0
var ui: Control
var info_label: Label
var hint_label: Label
var fade: ColorRect


func _ready() -> void:
	State.ensure_party()
	_build_player()
	_build_camera()
	_build_ui()
	_load_zone("beach")
	_play_intro()


func _view() -> Vector2:
	return get_viewport().get_visible_rect().size


func _jump_pos() -> Vector2:
	return Vector2(_view().x - 170, _view().y - 170)


func _act_pos() -> Vector2:
	return Vector2(_view().x - 370, _view().y - 130)


func _horn_pos() -> Vector2:
	return Vector2(_view().x - 170, _view().y - 360)


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
	name_tag.text = State.HERO_NAME
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
	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 34)
	hint_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7))
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	hint_label.add_theme_constant_override("outline_size", 8)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	hint_label.offset_left = -600
	hint_label.offset_right = 600
	hint_label.offset_top = 90
	hint_label.visible = false
	layer.add_child(hint_label)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)
	joy_center = _default_joy_center()
	joy_pos = joy_center
	ui.queue_redraw()


func _show_hint(text: String, secs: float) -> void:
	hint_label.text = text
	hint_label.visible = true
	hint_timer = secs


func _draw_button_text(text: String, center: Vector2, size: int = 26) -> void:
	var font := ThemeDB.fallback_font
	ui.draw_string(font, Vector2(center.x - BTN_RADIUS, center.y + 9), text, HORIZONTAL_ALIGNMENT_CENTER, BTN_RADIUS * 2.0, size, Color(1, 1, 1, 0.95))


func _draw_ui() -> void:
	if in_battle or in_dialog or locked:
		return
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
	if current_zone != "camp":
		ui.draw_circle(_horn_pos(), BTN_RADIUS, Color(1.0, 0.8, 0.25, 0.5))
		_draw_button_text("CUERNO", _horn_pos(), 24)
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
	companion = null
	zone = Node3D.new()
	add_child(zone)
	current_zone = zone_name
	var info: Dictionary
	if zone_name == "camp":
		info = Zones.build_camp(zone)
		State.heal_all()
	elif zone_name == "beach":
		info = Zones.build_beach(zone)
	else:
		info = Zones.build_world(zone)
		_spawn_enemies()
	spawn_point = info["spawn"]
	player.position = spawn_point
	player.velocity = Vector3.ZERO
	_spawn_companion()
	near_portal = null
	ui.queue_redraw()


func _spawn_companion() -> void:
	companion = Companion.build()
	zone.add_child(companion)
	_place_companion()


func _place_companion() -> void:
	if companion == null:
		return
	companion.position = player.position + Vector3(-2.0, -0.9, 1.5)


func _spawn_enemies() -> void:
	var defs: Array = [
		["g1", Vector3(-9, 0, -3), ["satiro", "satiro"]],
		["g2", Vector3(7, 0, -17), ["satiro", "arpia"]],
		["g3", Vector3(-6, 0, 18), ["arpia", "arpia", "satiro"]],
	]
	for d in defs:
		var id: String = d[0]
		if State.defeated.has(id):
			continue
		var kinds: Array = d[2]
		var n := Node3D.new()
		n.position = d[1]
		n.add_to_group("enemies")
		n.set_meta("id", id)
		n.set_meta("kinds", kinds)
		zone.add_child(n)
		for j in kinds.size():
			var kind: String = kinds[j]
			var ox: float = (j - (kinds.size() - 1) / 2.0) * 1.5
			var mi := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.45
			cap.height = 1.8
			mi.mesh = cap
			var col := Color(0.65, 0.38, 0.2)
			var label := "Sátiro"
			if kind == "arpia":
				col = Color(0.55, 0.25, 0.65)
				label = "Arpía"
			mi.material_override = Zones.mat(col)
			mi.position = Vector3(ox, 0.9, 0)
			n.add_child(mi)
			var tag := Label3D.new()
			tag.text = label
			tag.font_size = 44
			tag.pixel_size = 0.01
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.position = Vector3(ox, 2.2, 0)
			n.add_child(tag)
		var tw := n.create_tween().set_loops()
		tw.tween_property(n, "position:y", 0.3, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(n, "position:y", 0.0, 0.7).set_trans(Tween.TRANS_SINE)


# ---------- Diálogos e introducción ----------

func _release_touches() -> void:
	joy_id = -1
	look_id = -1
	jump_id = -1
	act_id = -1
	joy_vec = Vector2.ZERO
	joy_center = _default_joy_center()
	joy_pos = joy_center
	player.velocity = Vector3.ZERO
	ui.queue_redraw()


func _run_dialog(lines: Array) -> void:
	_release_touches()
	in_dialog = true
	dialog = Dialog.new()
	add_child(dialog)
	dialog.start(lines)
	await dialog.finished
	dialog.queue_free()
	dialog = null
	in_dialog = false
	ui.queue_redraw()


func _wait(secs: float) -> void:
	await get_tree().create_timer(secs).timeout


func _play_intro() -> void:
	if State.flags.has("intro_done"):
		return
	locked = true
	_release_touches()
	fade.color = Color(0, 0, 0, 1)
	player.rotation.x = -PI * 0.5
	player.position.y = 0.45
	companion.position = Vector3(-7, 0, -2)
	companion.rotation.y = atan2(-7.0, -2.0)
	yaw = 0.0
	pitch = -0.3
	await _wait(0.5)
	await _run_dialog([["", "Todo está oscuro... Solo se oye el mar."]])
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.6)
	await tw.finished
	var goal: Vector3 = Vector3(-2.0, 0, 4.6)
	companion.rotation.y = atan2(-(goal.x - companion.position.x), -(goal.z - companion.position.z))
	var walk := create_tween()
	walk.tween_property(companion, "position", goal, 2.4).set_trans(Tween.TRANS_SINE)
	await walk.finished
	companion.rotation.y = PI
	await _run_dialog([
		["Amaltea", "¡Eh! ¡Eh, tú! ¿Estás vivo? Venga, despierta, que las olas no esperan."],
		["", "Algo suave y húmedo te empuja el hombro."],
	])
	var wake := create_tween().set_parallel(true)
	wake.tween_property(player, "rotation:x", 0.0, 0.7)
	wake.tween_property(player, "position:y", 1.1, 0.7)
	await wake.finished
	await _run_dialog([
		["Aris", "¿Qué...? ¿Dónde estoy? Estaba en mi cuarto... leyendo..."],
		["Aris", "Espera. Una cabra. Una cabra que habla. Esto es un sueño, seguro."],
		["Amaltea", "¿Cabra? ¡Soy una cabrita, sí, pero con mucho más pedigrí! Me llamo Amaltea, y no, no es un sueño."],
		["Aris", "Claro que es un sueño. Me habré dormido con el libro encima."],
		["", "Amaltea agacha la cabeza y le da un golpecito con uno de sus cuernos."],
		["Aris", "¡Ay! ...Vale. Eso ha dolido demasiado para ser un sueño."],
		["Amaltea", "Bienvenido a Creta, en los tiempos en que los dioses aún eran jóvenes. Tu libro te ha traído hasta aquí."],
		["Aris", "¿Dentro del libro? ¿Y cómo vuelvo a casa?"],
		["Amaltea", "Lo averiguaremos recorriendo la historia entera. No estarás solo: yo hablo con todos los animales que guían a los viajeros perdidos."],
		["Amaltea", "Eres Aris, ¿verdad? Tu nombre sonó en el libro cuando caíste. Curioso... se parece al de alguien que conozco."],
		["Amaltea", "Y mira mi cuerno dorado: se me rompió un día que cuidaba a un niño muy fuerte y muy travieso. Desde entonces da abundancia a quien lo sostiene."],
		["Amaltea", "Con él podré llevarnos a un campamento seguro cuando lo necesites. Toca CUERNO y nos vamos."],
		["Aris", "Un campamento... Vale. Esto es una locura, pero me gusta."],
		["Amaltea", "¡Pues vamos, Aris! Explora la playa, que yo te sigo."],
	])
	State.flags["intro_done"] = true
	locked = false
	_show_hint("Toca CUERNO para ir al campamento", 7.0)


# ---------- Combate ----------

func _start_battle(enemy_node: Node3D) -> void:
	in_battle = true
	battle_enemy = enemy_node
	_release_touches()
	var enemies: Array = []
	var kinds: Array = enemy_node.get_meta("kinds")
	for k in kinds:
		enemies.append(State.make_enemy(str(k)))
	var counts: Dictionary = {}
	for e in enemies:
		counts[e.fname] = int(counts.get(e.fname, 0)) + 1
	var seen: Dictionary = {}
	for e in enemies:
		if int(counts[e.fname]) > 1:
			var base: String = e.fname
			var idx: int = int(seen.get(base, 0))
			seen[base] = idx + 1
			e.fname = "%s %s" % [base, "ABC"[idx]]
	battle = Battle.new()
	add_child(battle)
	battle.finished.connect(_on_battle_finished)
	battle.setup(State.party, enemies, zone, camera)


func _on_battle_finished(result: String) -> void:
	if battle != null:
		battle.queue_free()
		battle = null
	in_battle = false
	if battle_enemy != null and is_instance_valid(battle_enemy):
		if result == "win":
			State.defeated[str(battle_enemy.get_meta("id"))] = true
			battle_enemy.queue_free()
		elif result == "flee":
			grace = 4.0
			var away: Vector3 = player.global_position - battle_enemy.global_position
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3(0, 0, 1)
			player.global_position += away.normalized() * 4.0
	battle_enemy = null
	if result == "lose":
		State.has_last = false
		_travel("camp", false)
	ui.queue_redraw()


# ---------- Viajes ----------

func _travel(target: String, remember: bool = true) -> void:
	if traveling:
		return
	traveling = true
	var dest: String = target
	var use_pos: bool = false
	if target == "camp" and remember:
		State.last_zone = current_zone
		State.last_pos = player.global_position
		State.has_last = true
	elif target == "return":
		dest = State.last_zone
		use_pos = State.has_last
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.35)
	await tw.finished
	_load_zone(dest)
	if use_pos:
		player.position = State.last_pos + Vector3(0, 0.3, 0)
		_place_companion()
	var tw2 := create_tween()
	tw2.tween_property(fade, "color:a", 0.0, 0.35)
	await tw2.finished
	traveling = false


func _input(event: InputEvent) -> void:
	if in_battle:
		if event is InputEventScreenTouch and event.pressed and battle != null:
			battle.handle_touch(event.position)
		return
	if in_dialog:
		if event is InputEventScreenTouch and event.pressed and dialog != null:
			dialog.handle_touch()
		return
	if locked:
		return
	var half := _view().x * 0.5
	if event is InputEventScreenTouch:
		var pos: Vector2 = event.position
		if event.pressed:
			if pos.distance_to(_jump_pos()) < BTN_RADIUS * 1.2 and jump_id == -1:
				jump_id = event.index
				jump_buffer = 0.15
			elif current_zone != "camp" and pos.distance_to(_horn_pos()) < BTN_RADIUS * 1.2:
				_travel("camp")
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
	if traveling or in_battle or in_dialog or locked:
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


func _update_companion(delta: float) -> void:
	if companion == null or not is_instance_valid(companion) or locked or in_dialog:
		return
	var desired: Vector3 = player.global_position + Vector3(-1.9, 0.0, 1.7).rotated(Vector3.UP, yaw)
	var to_goal: Vector3 = desired - companion.global_position
	to_goal.y = 0.0
	var dist: float = to_goal.length()
	var moving: bool = false
	if dist > 14.0:
		_place_companion()
		return
	if dist > 0.35:
		var speed: float = minf(9.0, dist * 4.0 + 1.0)
		companion.global_position += to_goal.normalized() * minf(speed * delta, dist)
		moving = true
		var target_yaw: float = atan2(-to_goal.x, -to_goal.z)
		companion.rotation.y = lerp_angle(companion.rotation.y, target_yaw, delta * 8.0)
	else:
		companion.rotation.y = lerp_angle(companion.rotation.y, yaw, delta * 4.0)
	var ground_y: float = player.global_position.y - 0.9
	companion.global_position.y = lerpf(companion.global_position.y, ground_y, delta * 8.0)
	var body: Node3D = companion.get_child(0)
	var hop: float = 0.0
	if moving:
		hop = absf(sin(Time.get_ticks_msec() / 110.0)) * 0.12
	body.position.y = lerpf(body.position.y, hop, delta * 14.0)


func _process(delta: float) -> void:
	cam_pivot.global_position = player.global_position + Vector3(0, 1.5, 0)
	cam_pivot.rotation = Vector3(pitch, yaw, 0)
	grace = maxf(0.0, grace - delta)
	if hint_timer > 0.0:
		hint_timer -= delta
		if hint_timer <= 0.0:
			hint_label.visible = false
	var hero = State.party[0]
	info_label.visible = not in_battle
	info_label.text = "%s Nv%d  PV %d/%d  |  FPS: %d" % [hero.fname, hero.level, hero.hp, hero.max_hp, Engine.get_frames_per_second()]
	if in_battle or traveling:
		return
	_update_companion(delta)
	if locked or in_dialog:
		return
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
	if grace <= 0.0:
		for n in get_tree().get_nodes_in_group("enemies"):
			var en := n as Node3D
			if en == null or en.is_queued_for_deletion():
				continue
			var ex: float = en.global_position.x - player.global_position.x
			var ez: float = en.global_position.z - player.global_position.z
			if Vector2(ex, ez).length() < 2.6 and absf(en.global_position.y - player.global_position.y) < 3.0:
				_start_battle(en)
				break
