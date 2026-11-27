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
var in_menu := false
var menu_layer: CanvasLayer
var menu_ui: Control
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
	if State.has_save():
		_show_menu()
	else:
		_new_game()


func _new_game() -> void:
	State.reset()
	State.ensure_party()
	_load_zone("house")
	_play_house_intro()


func _show_menu() -> void:
	in_menu = true
	menu_layer = CanvasLayer.new()
	menu_layer.layer = 30
	add_child(menu_layer)
	menu_ui = Control.new()
	menu_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_ui.draw.connect(_draw_menu)
	menu_layer.add_child(menu_ui)


func _menu_rects() -> Array:
	var v: Vector2 = _view()
	return [Rect2(v.x * 0.5 - 280.0, v.y * 0.5 - 10.0, 560.0, 110.0), Rect2(v.x * 0.5 - 280.0, v.y * 0.5 + 130.0, 560.0, 110.0)]


func _draw_menu() -> void:
	var v: Vector2 = _view()
	menu_ui.draw_rect(Rect2(Vector2.ZERO, v), Color(0.04, 0.05, 0.12, 1.0))
	var font: Font = ThemeDB.fallback_font
	menu_ui.draw_string(font, Vector2(0, v.y * 0.5 - 150.0), "MITOLOGÍA RPG", HORIZONTAL_ALIGNMENT_CENTER, v.x, 90, Color(0.95, 0.8, 0.35))
	menu_ui.draw_string(font, Vector2(0, v.y * 0.5 - 85.0), "Un viaje por el mundo de los mitos griegos", HORIZONTAL_ALIGNMENT_CENTER, v.x, 32, Color(0.8, 0.8, 0.9))
	var labels: Array = ["CONTINUAR", "NUEVA PARTIDA"]
	var rects: Array = _menu_rects()
	for i in 2:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.28, 0.5, 0.95) if i == 0 else Color(0.35, 0.2, 0.2, 0.95)
		sb.border_color = Color(0.85, 0.7, 0.3)
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(18)
		var r: Rect2 = rects[i]
		menu_ui.draw_style_box(sb, r)
		menu_ui.draw_string(font, Vector2(r.position.x, r.position.y + 72.0), labels[i], HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 48, Color(1, 1, 1))


func _menu_touch(pos: Vector2) -> void:
	var rects: Array = _menu_rects()
	var r0: Rect2 = rects[0]
	var r1: Rect2 = rects[1]
	if r0.has_point(pos):
		_close_menu()
		_continue_game()
	elif r1.has_point(pos):
		_close_menu()
		_new_game()


func _close_menu() -> void:
	in_menu = false
	menu_layer.queue_free()
	menu_layer = null


func _continue_game() -> void:
	var d: Dictionary = State.load_game()
	if d.is_empty():
		_new_game()
		return
	var z: String = str(d["zone"])
	_load_zone(z)
	if z != "camp" and z != "house":
		player.position = d["pos"] + Vector3(0, 0.3, 0)
		_place_companion()
	grace = 3.0
	_show_hint("Partida cargada", 2.5)


func _autosave() -> void:
	if in_menu or current_zone == "house" or not State.flags.has("intro_done"):
		return
	State.save_game(current_zone, player.global_position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if player != null and not in_battle:
			_autosave()


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
	if in_menu or in_battle or in_dialog or locked:
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
	if _horn_available():
		ui.draw_circle(_horn_pos(), BTN_RADIUS, Color(1.0, 0.8, 0.25, 0.5))
		_draw_button_text("CUERNO", _horn_pos(), 24)
	if near_portal != null:
		var aa := 0.45
		if act_id != -1:
			aa = 0.7
		ui.draw_circle(_act_pos(), BTN_RADIUS, Color(1, 0.85, 0.3, aa))
		_draw_button_text(str(near_portal.get_meta("button", "VIAJAR")), _act_pos())


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
	elif zone_name == "house":
		info = Zones.build_house(zone)
	else:
		info = Zones.build_cap1(zone)
		_spawn_enemies(Zones.cap1_enemies())
	spawn_point = info["spawn"]
	player.position = spawn_point
	player.velocity = Vector3.ZERO
	player.scale = Vector3.ONE
	player.rotation = Vector3.ZERO
	if zone_name != "house":
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


func _spawn_enemies(defs: Array) -> void:
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
			var info: Dictionary = State.enemy_info(kind)
			var sc: float = float(info["scale"])
			var mi := MeshInstance3D.new()
			var cap := CapsuleMesh.new()
			cap.radius = 0.45
			cap.height = 1.8
			mi.mesh = cap
			var col: Color = info["color"]
			var label: String = str(info["name"])
			mi.material_override = Zones.mat(col)
			mi.scale = Vector3(sc, sc, sc)
			mi.position = Vector3(ox, 0.9 * sc, 0)
			n.add_child(mi)
			var tag := Label3D.new()
			tag.text = label
			tag.font_size = 44
			tag.pixel_size = 0.01
			tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			tag.position = Vector3(ox, 2.2 * sc + 0.1, 0)
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
		["Amaltea", "Bienvenido a Creta, en los tiempos en que los dioses aún eran jóvenes. Pero dime, náufrago, ¿cómo te llamas?"],
		["Aris", "Aris. Me llamo Aris."],
		["Amaltea", "¿Aris...? Qué curioso. Ese nombre me suena a alguien que conozco... pero eso es otra historia."],
		["Aris", "¿Creta? ¿Los dioses? ¿Estoy dentro de mi libro? ¿Y cómo vuelvo a casa?"],
		["Amaltea", "Pues... no tengo ni idea, la verdad. Solo sé que te encontré tirado en la arena con un libro brillando a tu lado."],
		["Amaltea", "Mira, al menos algo útil: este cuerno dorado se me rompió un día que cuidaba a un niño muy fuerte y muy travieso. Desde entonces da abundancia a quien lo sostiene."],
		["Amaltea", "Y, no sé por qué, también sé abrir un camino hasta un campamento seguro. Toca CUERNO y nos vamos."],
		["Aris", "Un campamento... Vale. Esto es una locura, pero me gusta."],
		["Amaltea", "Pues date una vuelta por la playa. Yo me quedo cerca."],
	])
	State.flags["intro_done"] = true
	locked = false
	_autosave()
	_show_hint("Toca CUERNO para ir al campamento", 7.0)


func _horn_available() -> bool:
	return State.flags.has("intro_done") and current_zone != "camp" and current_zone != "house"


func _camera_collision() -> void:
	var from: Vector3 = cam_pivot.global_position
	var want: Vector3 = cam_pivot.global_transform * Vector3(0, 0, 6.0)
	var q := PhysicsRayQueryParameters3D.create(from, want)
	q.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(q)
	var z: float = 6.0
	if not hit.is_empty():
		var d: float = from.distance_to(hit["position"])
		z = clampf(d - 0.35, 0.8, 6.0)
	camera.position.z = lerpf(camera.position.z, z, 0.5)


func _do_action(node: Node3D) -> void:
	var action: String = str(node.get_meta("action", "travel"))
	if action == "travel":
		_travel(str(node.get_meta("target")))
	elif action == "talk":
		_talk(str(node.get_meta("id")))
	elif action == "sleep":
		_play_bedtime()
	elif action == "brazier":
		_light_brazier(node)
	elif action == "chest":
		_open_chest(node)
	elif action == "end":
		_end_chapter()


func _talk(id: String) -> void:
	var lines: Array = []
	if id == "papa":
		lines = [["Papá", "¿Todavía despierto? Ese libro de mitología te tiene hechizado, ¿eh?"], ["Aris", "Es que las historias son increíbles, papá."]]
	elif id == "mama":
		lines = [["Mamá", "Es tarde, Aris. Mañana hay clase. ¿Seguro que no quieres un vaso de leche caliente?"], ["Aris", "No hace falta, mamá. Subo, leo un poco y me duermo."]]
	elif id == "libro":
		lines = [["Aris", "Mi libro de mitología griega. Lo leeré en la cama."]]
	elif id == "curete":
		lines = [
			["Curete", "¡Chist! Baja la voz, forastero. En este bosque hay que hablar bajito."],
			["Aris", "¿Por qué? ¿Quién nos va a oír?"],
			["Curete", "Las arpías. Vigilan la cueva del monte y no les gustan los ruidos. Ni los visitantes."],
			["Curete", "La puerta de piedra solo se abre con los tres fuegos antiguos. Están en los claros del bosque, uno al oeste, otro al este... y otro, muy alto."],
			["Aris", "Tres fuegos. Vale. ¿Y qué hay dentro de esa cueva?"],
			["Curete", "Algo que nadie debe oír llorar. Eso es todo lo que puedo decirte."],
			["Amaltea", "Qué conversación más animada. Yo no pregunto nada, que me pongo nerviosa."],
		]
		State.flags["curete"] = true
	if lines.is_empty():
		return
	await _run_dialog(lines)
	if id == "curete":
		_show_hint("Enciende los tres fuegos antiguos para abrir la cueva", 6.0)
		_autosave()


func _play_house_intro() -> void:
	if State.flags.has("house_intro"):
		return
	State.flags["house_intro"] = true
	locked = true
	_release_touches()
	await _wait(0.6)
	await _run_dialog([
		["", "Es de noche. La casa está en silencio, salvo por la tele del salón."],
		["Mamá", "Aris, cariño, ya es tarde. ¿No te vas a dormir?"],
		["Aris", "Ya voy, mamá. Solo quiero leer un rato."],
		["Papá", "¿Otra vez con ese libro de mitología? ¡Hasta mañana, campeón!"],
	])
	locked = false
	_show_hint("Sube a tu habitación por las escaleras", 7.0)


func _play_bedtime() -> void:
	if locked:
		return
	locked = true
	_release_touches()
	var out := create_tween()
	out.tween_property(fade, "color:a", 1.0, 0.6)
	await out.finished
	player.position = Vector3(-7.5, 4.8, -6.2)
	player.rotation = Vector3(-PI * 0.5, 0, 0)
	yaw = PI * 0.5
	pitch = -0.45
	var fx := Node3D.new()
	zone.add_child(fx)
	fx.position = Vector3(-7.5, 5.5, -5.6)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.85, 0.4)
	glow.light_energy = 0.0
	glow.omni_range = 14.0
	fx.add_child(glow)
	var inn := create_tween()
	inn.tween_property(fade, "color:a", 0.0, 0.8)
	await inn.finished
	await _run_dialog([
		["Aris", "Solo un capítulo más..."],
		["", "Abres el libro de mitología griega. Las páginas huelen a polvo y a historias muy antiguas."],
		["Aris", "Cronos, los titanes... Zeus escondido en una cueva..."],
		["", "Los párpados te pesan. Las letras empiezan a moverse solas sobre el papel."],
		["", "De pronto, el libro brilla."],
	])
	var sparks: Array = []
	for i in 30:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		s.mesh = sm
		s.material_override = Zones.mat(Color(1.0, 0.85, 0.4), 3.0)
		var ang: float = randf() * TAU
		var r: float = randf_range(1.5, 3.2)
		s.position = Vector3(cos(ang) * r, randf_range(-1.0, 2.0), sin(ang) * r)
		fx.add_child(s)
		sparks.append(s)
	var fxt := create_tween().set_parallel(true)
	fxt.tween_property(glow, "light_energy", 9.0, 2.6)
	for s in sparks:
		fxt.tween_property(s, "position", Vector3.ZERO, randf_range(1.6, 2.6)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	fxt.tween_property(player, "scale", Vector3(0.05, 0.05, 0.05), 2.4).set_delay(0.4)
	await fxt.finished
	fade.color = Color(1, 1, 1, 0)
	var white := create_tween()
	white.tween_property(fade, "color:a", 1.0, 1.0)
	await white.finished
	fade.color = Color(0, 0, 0, 1)
	_load_zone("beach")
	_play_intro()


# ---------- Capitulo 1 ----------

func _drop_interact(node: Node3D) -> void:
	node.remove_from_group("portals")
	node.queue_free()
	near_portal = null
	ui.queue_redraw()


func _light_brazier(node: Node3D) -> void:
	var id: String = str(node.get_meta("id"))
	State.flags[id] = true
	_drop_interact(node)
	Zones.refresh_cap1(zone)
	var n: int = 0
	for k in ["b1", "b2", "b3"]:
		if State.flags.has(k):
			n += 1
	if n < 3:
		_show_hint("Fuegos encendidos: %d/3" % n, 3.5)
		_autosave()
		return
	await _run_dialog([["", "El tercer fuego prende. Se oye un crujido profundo, como si la montaña despertara."], ["Amaltea", "Eso ha sonado a puerta. A puerta grande."]])
	State.flags["gate_open"] = true
	Zones.refresh_cap1(zone)
	_show_hint("La puerta de la cueva se ha abierto", 5.0)
	_autosave()


func _open_chest(node: Node3D) -> void:
	var id: String = str(node.get_meta("id"))
	State.flags[id] = true
	_drop_interact(node)
	Zones.refresh_cap1(zone)
	for p in State.party:
		p.max_hp += 6
		p.hp += 6
	await _run_dialog([["", "Dentro hay un fruto dorado que huele a miel y a verano. Lo compartís entre todos."], ["", "¡Los PV máximos de todo el grupo aumentan en 6!"]])
	_autosave()


func _boss_defeated() -> void:
	State.flags["boss_done"] = true
	await _run_dialog([
		["", "La gran arpía cae entre un remolino de plumas oscuras y se desvanece con un chillido."],
		["Aris", "¿Estáis todos bien? ...Creo que ahora sí que ha sido real."],
		["Amaltea", "Del fondo de la cueva viene una luz. Y un sonido muy bajito... como de hipo."],
	])
	Zones.interact(zone, Vector3(0, 0, -46), "end", "fin", "ENTRAR", "Fondo de la cueva")


func _end_chapter() -> void:
	await _run_dialog([
		["", "Al fondo de la cueva, en una cuna hecha de ramas y miel, algo se mueve entre las mantas."],
		["Aris", "Amaltea... ¿esto qué es?"],
		["Amaltea", "Ay, mira tú qué casualidad. Vamos a dejarlo dormir, que ha sido un día muy largo."],
		["", "FIN DEL CAPÍTULO 1 - Continuará..."],
	])
	State.flags["cap1_done"] = true
	_autosave()
	_show_hint("Capítulo 1 completado. Toca CUERNO para ir al campamento", 7.0)


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
	var won_id: String = ""
	if battle_enemy != null and is_instance_valid(battle_enemy) and result == "win":
		won_id = str(battle_enemy.get_meta("id"))
	battle_enemy = null
	if result == "lose":
		State.has_last = false
		await _travel("camp", false)
	ui.queue_redraw()
	if won_id == "boss":
		await _boss_defeated()
	_autosave()


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
	_autosave()
	if current_zone == "cap1" and not State.flags.has("cap1_enter"):
		State.flags["cap1_enter"] = true
		await _run_dialog([["", "El bosque de Creta huele a pino y a tierra húmeda. Todo está demasiado silencioso."], ["Amaltea", "Qué raro... normalmente aquí no se calla ni un grillo."]])


func _input(event: InputEvent) -> void:
	if in_menu:
		if event is InputEventScreenTouch and event.pressed:
			_menu_touch(event.position)
		return
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
			elif _horn_available() and pos.distance_to(_horn_pos()) < BTN_RADIUS * 1.2:
				_travel("camp")
			elif near_portal != null and pos.distance_to(_act_pos()) < BTN_RADIUS * 1.2 and act_id == -1:
				act_id = event.index
				_do_action(near_portal)
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
	if not in_battle:
		_camera_collision()
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
		if Vector2(dx, dz).length() < 2.4 and absf(p.global_position.y - player.global_position.y) < 2.2:
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
