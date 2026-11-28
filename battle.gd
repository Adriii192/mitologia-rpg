extends CanvasLayer

signal chosen
signal finished(result: String)

const STAGE_OFFSET := Vector3(500, 0, 0)
const Character = preload("res://character.gd")
const CAM_POS := Vector3(0, 4.2, 10.5)
const CAM_LOOK := Vector3(0, 0.3, -2.5)

class FloatText:
	var text: String = ""
	var pos: Vector2 = Vector2.ZERO
	var t: float = 0.0
	var color: Color = Color(1, 1, 1)

var party: Array = []
var enemies: Array = []
var current = null
var state: String = "intro"
var message: String = ""
var pick_kind: String = ""
var pick_target = null
var pending: String = ""
var target_side: String = "enemy"
var floats: Array = []
var fled: bool = false
var ui: Control
var menu_labels: Array = ["Atacar", "Habilidad", "Defender", "Huir"]

var stage: Node3D = null
var cam: Camera3D = null
var prev_cam: Camera3D = null
var models: Dictionary = {}
var homes: Dictionary = {}
var body_mats: Dictionary = {}


func setup(p_party: Array, p_enemies: Array, host: Node3D, p_cam: Camera3D) -> void:
	party = p_party
	enemies = p_enemies
	prev_cam = p_cam
	layer = 20
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	add_child(ui)
	_build_stage(host)
	_run()


func _exit_tree() -> void:
	if stage != null and is_instance_valid(stage):
		stage.queue_free()
	if prev_cam != null and is_instance_valid(prev_cam) and prev_cam.is_inside_tree():
		prev_cam.make_current()


# ---------- Escenario 3D ----------

func _stage_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = pos
	stage.add_child(mi)


func _stage_column(pos: Vector3, height: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.6
	cm.bottom_radius = 0.6
	cm.height = height
	mi.mesh = cm
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.9, 0.88, 0.8)
	mi.material_override = m
	mi.position = pos + Vector3(0, height * 0.5, 0)
	stage.add_child(mi)


func _party_home(i: int) -> Vector3:
	var n: int = party.size()
	return Vector3((i - (n - 1) * 0.5) * 2.6 - 1.6, 0.0, 2.5)


func _enemy_home(i: int) -> Vector3:
	var n: int = enemies.size()
	return Vector3((i - (n - 1) * 0.5) * 3.2 + 0.6, 0.0, -3.8)


func _mesh_node(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, f, track: bool) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	mi.material_override = m
	mi.position = pos
	parent.add_child(mi)
	if track:
		body_mats[f].append(m)
	return mi


func _sphere(r: float) -> SphereMesh:
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	return sm


func _capsule(r: float, h: float) -> CapsuleMesh:
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = h
	return cm


func _cone(r: float, h: float) -> CylinderMesh:
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = r
	cm.height = h
	return cm


func _collect_mats(n: Node, f) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		if mi.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = (mi.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
			mi.material_override = m
			body_mats[f].append(m)
	for c in n.get_children():
		_collect_mats(c, f)


func _make_model(f) -> Node3D:
	body_mats[f] = []
	var root := Node3D.new()
	var body := Node3D.new()
	root.add_child(body)
	var col: Color = f.color
	if f.is_enemy:
		var is_arpia: bool = str(f.fname).begins_with("Arp")
		if is_arpia:
			_mesh_node(body, _capsule(0.34, 1.4), Vector3(0, 0.95, 0), col, f, true)
			_mesh_node(body, _sphere(0.27), Vector3(0, 1.9, 0), col.lightened(0.25), f, true)
			var wl := _mesh_node(body, BoxMesh.new(), Vector3(-0.95, 1.35, 0.05), col.darkened(0.25), f, true)
			(wl.mesh as BoxMesh).size = Vector3(1.4, 0.06, 0.7)
			wl.rotation_degrees = Vector3(0, 0, 28)
			var wr := _mesh_node(body, BoxMesh.new(), Vector3(0.95, 1.35, 0.05), col.darkened(0.25), f, true)
			(wr.mesh as BoxMesh).size = Vector3(1.4, 0.06, 0.7)
			wr.rotation_degrees = Vector3(0, 0, -28)
			_mesh_node(body, _cone(0.09, 0.3), Vector3(0, 1.85, -0.3), Color(0.95, 0.8, 0.3), f, false).rotation_degrees = Vector3(-90, 0, 0)
		else:
			_mesh_node(body, _capsule(0.45, 1.7), Vector3(0, 0.85, 0), col, f, true)
			_mesh_node(body, _sphere(0.32), Vector3(0, 2.0, 0), col.lightened(0.2), f, true)
			_mesh_node(body, _cone(0.09, 0.45), Vector3(-0.2, 2.4, 0), Color(0.92, 0.88, 0.75), f, false)
			_mesh_node(body, _cone(0.09, 0.45), Vector3(0.2, 2.4, 0), Color(0.92, 0.88, 0.75), f, false)
		_mesh_node(body, _sphere(0.05), Vector3(-0.12, 2.02, -0.27), Color(1, 0.15, 0.1), f, false)
		_mesh_node(body, _sphere(0.05), Vector3(0.12, 2.02, -0.27), Color(1, 0.15, 0.1), f, false)
		root.rotation.y = PI
		if str(f.fname).find("Aelo") >= 0:
			root.scale = Vector3(1.6, 1.6, 1.6)
	elif str(f.fname) == "Aris":
		var hm: Node3D = Character.build(Color(0.15, 0.3, 0.7), Color(0.22, 0.25, 0.4), Color(0.95, 0.76, 0.6), Color(0.35, 0.2, 0.1), "messy", true)
		hm.scale = Vector3(1.25, 1.25, 1.25)
		body.add_child(hm)
		_collect_mats(hm, f)
	else:
		_mesh_node(body, _capsule(0.38, 1.6), Vector3(0, 0.8, 0), col, f, true)
		_mesh_node(body, _sphere(0.3), Vector3(0, 1.95, 0), Color(0.86, 0.66, 0.48), f, true)
		_mesh_node(body, _sphere(0.05), Vector3(-0.11, 1.98, -0.27), Color(0.05, 0.05, 0.05), f, false)
		_mesh_node(body, _sphere(0.05), Vector3(0.11, 1.98, -0.27), Color(0.05, 0.05, 0.05), f, false)
	return root


func _build_stage(host: Node3D) -> void:
	stage = Node3D.new()
	host.add_child(stage)
	stage.position = STAGE_OFFSET
	_stage_box(Vector3(0, -0.5, 0), Vector3(90, 1, 90), Color(0.42, 0.55, 0.3))
	var disc := MeshInstance3D.new()
	var dm := CylinderMesh.new()
	dm.top_radius = 11.0
	dm.bottom_radius = 11.0
	dm.height = 0.06
	disc.mesh = dm
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.6, 0.54, 0.4)
	disc.material_override = dmat
	disc.position = Vector3(0, 0.02, -1.0)
	stage.add_child(disc)
	for i in 7:
		_stage_column(Vector3(-13.0 + i * 4.33, 0, -15.0), 6.0)
	_stage_column(Vector3(-15, 0, -4), 6.0)
	_stage_column(Vector3(15, 0, -4), 6.0)
	for i in party.size():
		var m: Node3D = _make_model(party[i])
		stage.add_child(m)
		m.position = _party_home(i)
		models[party[i]] = m
		homes[party[i]] = m.position
	for i in enemies.size():
		var m2: Node3D = _make_model(enemies[i])
		stage.add_child(m2)
		m2.position = _enemy_home(i)
		models[enemies[i]] = m2
		homes[enemies[i]] = m2.position
	cam = Camera3D.new()
	cam.fov = 55.0
	stage.add_child(cam)
	cam.look_at_from_position(CAM_POS, CAM_LOOK)
	var rot: Vector3 = cam.rotation
	cam.position = CAM_POS + Vector3(0, 2.5, 6.0)
	cam.rotation = rot
	cam.make_current()
	var tw := create_tween()
	tw.tween_property(cam, "position", CAM_POS, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _screen_of(f) -> Vector2:
	if cam == null or not cam.is_inside_tree() or not models.has(f):
		return _v() * 0.5
	var m: Node3D = models[f]
	return cam.unproject_position(m.global_position + Vector3(0, 1.1, 0))


func _head_of(f) -> Vector2:
	if cam == null or not cam.is_inside_tree() or not models.has(f):
		return _v() * 0.5
	var m: Node3D = models[f]
	return cam.unproject_position(m.global_position + Vector3(0, 2.5, 0))


# ---------- Medidas de pantalla ----------

func _v() -> Vector2:
	return get_viewport().get_visible_rect().size


func _s() -> float:
	return _v().y / 1080.0


func _party_rect(i: int) -> Rect2:
	var s := _s()
	var v := _v()
	var w: float = minf(300.0 * s, (v.x * 0.55) / 4.0 - 20.0 * s)
	var h: float = 230.0 * s
	return Rect2(30.0 * s + i * (w + 20.0 * s), v.y - h - 30.0 * s, w, h)


func _menu_rect(i: int) -> Rect2:
	var s := _s()
	var v := _v()
	var bw: float = 340.0 * s
	var bh: float = 105.0 * s
	var gap: float = 20.0 * s
	var x0: float = v.x - (2.0 * bw + gap) - 40.0 * s
	var y0: float = v.y - (2.0 * bh + gap) - 30.0 * s
	var col: int = i % 2
	var row: int = int(floor(i / 2.0))
	return Rect2(x0 + col * (bw + gap), y0 + row * (bh + gap), bw, bh)


func _cancel_rect() -> Rect2:
	var a: Rect2 = _menu_rect(2)
	var b: Rect2 = _menu_rect(3)
	return Rect2(a.position, Vector2(b.end.x - a.position.x, a.size.y))


func _pos_of(t) -> Vector2:
	return _head_of(t) + Vector2(0, 20)


# ---------- Bucle ----------

func _process(delta: float) -> void:
	for p in party:
		if p.flash > 0.0:
			p.flash -= delta
	for e in enemies:
		if e.flash > 0.0:
			e.flash -= delta
	for f in body_mats.keys():
		var flashing: bool = f.flash > 0.0
		for m in body_mats[f]:
			m.emission_enabled = flashing
			m.emission = Color(1, 1, 1)
			m.emission_energy_multiplier = 1.2
	for p in party:
		if models.has(p):
			var body: Node3D = models[p].get_child(0)
			var target_rot: float = 0.0
			var target_y: float = 0.0
			if p.hp <= 0:
				target_rot = -PI * 0.5
				target_y = 0.35
			body.rotation.x = lerp_angle(body.rotation.x, target_rot, delta * 8.0)
			body.position.y = lerpf(body.position.y, target_y, delta * 8.0)
	var keep: Array = []
	for ft in floats:
		ft.t += delta
		ft.pos = Vector2(ft.pos.x, ft.pos.y - 70.0 * delta)
		if ft.t < 1.0:
			keep.append(ft)
	floats = keep
	if ui != null:
		ui.queue_redraw()


func _float(text: String, pos: Vector2, color: Color) -> void:
	var ft := FloatText.new()
	ft.text = text
	ft.pos = pos
	ft.color = color
	floats.append(ft)


func _say(text: String, secs: float) -> void:
	message = text
	await get_tree().create_timer(secs).timeout


func _all_dead(arr: Array) -> bool:
	for x in arr:
		if x.hp > 0:
			return false
	return true


# ---------- Animaciones ----------

func _anim_attack(att, tgt) -> void:
	var m: Node3D = models[att]
	var tm: Node3D = models[tgt]
	var dir: Vector3 = tm.position - m.position
	dir.y = 0.0
	var dest: Vector3 = tm.position - dir.normalized() * 1.9
	var tw := create_tween()
	tw.tween_property(m, "position", dest, 0.22).set_trans(Tween.TRANS_QUAD)
	await tw.finished


func _anim_back(att) -> void:
	var m: Node3D = models[att]
	var tw := create_tween()
	tw.tween_property(m, "position", homes[att], 0.25).set_trans(Tween.TRANS_QUAD)
	await tw.finished


func _anim_hop(f) -> void:
	var m: Node3D = models[f]
	var base: Vector3 = homes[f]
	var tw := create_tween()
	tw.tween_property(m, "position", base + Vector3(0, 0.7, 0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "position", base, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished


func _shake(f) -> void:
	var m: Node3D = models[f]
	var base: Vector3 = m.position
	var tw := create_tween()
	tw.tween_property(m, "position", base + Vector3(0.18, 0, 0), 0.04)
	tw.tween_property(m, "position", base + Vector3(-0.18, 0, 0), 0.06)
	tw.tween_property(m, "position", base + Vector3(0.1, 0, 0), 0.05)
	tw.tween_property(m, "position", base, 0.04)


func _die_anim(f) -> void:
	if not f.is_enemy:
		return
	var body: Node3D = models[f].get_child(0)
	var tw := create_tween()
	tw.tween_property(body, "scale", Vector3(0.01, 0.01, 0.01), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished
	models[f].visible = false


# ---------- Flujo del combate ----------

func _run() -> void:
	state = "anim"
	message = "¡Un grupo enemigo os corta el paso!"
	await get_tree().create_timer(1.1).timeout
	while true:
		for f in party:
			if _all_dead(enemies):
				break
			if f.hp <= 0:
				continue
			await _player_turn(f)
			if fled:
				finished.emit("flee")
				return
		if _all_dead(enemies):
			await _win()
			return
		for e in enemies:
			if _all_dead(party):
				break
			if e.hp <= 0:
				continue
			await _enemy_turn(e)
		if _all_dead(party):
			await _lose()
			return


func _player_turn(f) -> void:
	current = f
	f.defending = false
	f.mp = mini(f.max_mp, f.mp + 1)
	state = "menu"
	message = "%s: ¿qué hacemos?" % f.fname
	await chosen
	await _resolve_player(f)


func _resolve_player(f) -> void:
	if pick_kind == "defend":
		f.defending = true
		await _say("%s se pone en guardia." % f.fname, 0.8)
	elif pick_kind == "flee":
		if randf() < 0.6:
			fled = true
			await _say("¡Escapáis del combate!", 1.0)
		else:
			await _say("No hay forma de huir...", 0.9)
	elif pick_kind == "attack":
		var t = pick_target
		await _say("%s ataca a %s." % [f.fname, t.fname], 0.3)
		await _anim_attack(f, t)
		await _do_damage(f, t, 1.0)
		await _anim_back(f)
	elif pick_kind == "skill":
		f.mp -= f.skill_cost
		await _say("%s usa %s." % [f.fname, f.skill_name], 0.4)
		if f.skill_kind == "all":
			await _anim_hop(f)
			for e in enemies:
				if e.hp > 0:
					await _do_damage(f, e, f.skill_power)
		elif f.skill_kind == "heal":
			var ally = pick_target
			await _anim_hop(f)
			var amt: int = int(f.mag * f.skill_power) + randi_range(0, 3)
			ally.hp = mini(ally.max_hp, ally.hp + amt)
			ally.flash = 0.0
			_float("+%d" % amt, _pos_of(ally), Color(0.4, 1.0, 0.5))
			await get_tree().create_timer(0.7).timeout
		else:
			await _anim_attack(f, pick_target)
			await _do_damage(f, pick_target, f.skill_power)
			await _anim_back(f)


func _enemy_turn(e) -> void:
	var living: Array = []
	for p in party:
		if p.hp > 0:
			living.append(p)
	if living.is_empty():
		return
	var t = living[randi() % living.size()]
	await _say("%s ataca a %s." % [e.fname, t.fname], 0.3)
	await _anim_attack(e, t)
	await _do_damage(e, t, 1.0)
	await _anim_back(e)


func _do_damage(att, tgt, mult: float) -> void:
	var raw: float = att.atk * mult * randf_range(0.9, 1.1)
	var crit: bool = randf() < 0.1
	if crit:
		raw *= 1.5
	var d: int = maxi(1, int(round(raw - tgt.defense * 0.5)))
	if tgt.defending:
		d = maxi(1, int(d * 0.5))
	tgt.hp = maxi(0, tgt.hp - d)
	tgt.flash = 0.35
	_shake(tgt)
	var txt: String = str(d)
	var col: Color = Color(1, 1, 1)
	if crit:
		txt += "!"
		col = Color(1.0, 0.85, 0.3)
	_float(txt, _pos_of(tgt), col)
	await get_tree().create_timer(0.55).timeout
	if tgt.hp <= 0:
		await _say("%s cae derrotado." % tgt.fname, 0.4)
		await _die_anim(tgt)


func _win() -> void:
	state = "anim"
	var total: int = 0
	for e in enemies:
		total += e.xp_reward
	await _say("¡Victoria! Ganáis %d de experiencia." % total, 1.3)
	for p in party:
		if p.hp <= 0:
			p.hp = maxi(1, int(p.max_hp * 0.25))
		p.xp += total
		while p.xp >= p.xp_needed():
			p.xp -= p.xp_needed()
			p.level_up()
			await _say("¡%s sube al nivel %d!" % [p.fname, p.level], 1.1)
	finished.emit("win")


func _lose() -> void:
	state = "anim"
	await _say("Todo el grupo ha caído... Despertáis en el campamento.", 1.8)
	finished.emit("lose")


# ---------- Entrada táctil ----------

func _nearest(list: Array, pos: Vector2):
	var best = null
	var best_d: float = 170.0 * _s()
	for x in list:
		if x.hp <= 0:
			continue
		var d: float = _screen_of(x).distance_to(pos)
		if d < best_d:
			best_d = d
			best = x
	return best


func handle_touch(pos: Vector2) -> void:
	if state == "menu":
		for i in 4:
			if _menu_rect(i).has_point(pos):
				_menu_pick(i)
				return
	elif state == "target":
		if _cancel_rect().has_point(pos):
			state = "menu"
			message = "%s: ¿qué hacemos?" % current.fname
			return
		if target_side == "enemy":
			var e = _nearest(enemies, pos)
			if e != null:
				_confirm(e)
		else:
			for i in party.size():
				var p = party[i]
				if p.hp > 0 and _party_rect(i).has_point(pos):
					_confirm(p)
					return
			var a = _nearest(party, pos)
			if a != null:
				_confirm(a)


func _menu_pick(i: int) -> void:
	if i == 0:
		pending = "attack"
		_ask_target("enemy")
	elif i == 1:
		if current.mp < current.skill_cost:
			message = "No tienes PM suficientes."
			return
		pending = "skill"
		if current.skill_kind == "all":
			_confirm(null)
		elif current.skill_kind == "heal":
			_ask_target("ally")
		else:
			_ask_target("enemy")
	elif i == 2:
		pending = "defend"
		_confirm(null)
	else:
		pending = "flee"
		_confirm(null)


func _ask_target(side: String) -> void:
	if side == "enemy":
		var living: Array = []
		for e in enemies:
			if e.hp > 0:
				living.append(e)
		if living.size() == 1:
			_confirm(living[0])
			return
	target_side = side
	state = "target"
	message = "Toca a tu objetivo."


func _confirm(t) -> void:
	pick_kind = pending
	pick_target = t
	state = "anim"
	chosen.emit()


# ---------- Dibujo 2D ----------

func _panel(r: Rect2, fill: Color, border: Color, bw: int = 3) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(14)
	ui.draw_style_box(sb, r)


func _text(text: String, r: Rect2, size: float, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	ui.draw_string(font, Vector2(r.position.x, r.position.y + r.size.y * 0.5 + size * 0.35), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(size), color)


func _text_outlined(text: String, r: Rect2, size: float, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var pos := Vector2(r.position.x, r.position.y + r.size.y * 0.5 + size * 0.35)
	ui.draw_string_outline(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(size), 8, Color(0, 0, 0, 0.9))
	ui.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(size), color)


func _text_left(text: String, pos: Vector2, size: float, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	ui.draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size), color)


func _bar(r: Rect2, frac: float, color: Color) -> void:
	ui.draw_rect(r, Color(0, 0, 0, 0.6))
	var f: float = clampf(frac, 0.0, 1.0)
	ui.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), color)


func _marker(head: Vector2, s: float, color: Color) -> void:
	var bob: float = sin(Time.get_ticks_msec() / 150.0) * 6.0 * s
	var p: Vector2 = head + Vector2(0, -70.0 * s + bob)
	ui.draw_colored_polygon(PackedVector2Array([p + Vector2(-20, -24) * s, p + Vector2(20, -24) * s, p + Vector2(0, 8) * s]), color)


func _draw_ui() -> void:
	var v: Vector2 = _v()
	var s: float = _s()
	ui.draw_rect(Rect2(0, v.y * 0.72, v.x, v.y * 0.28), Color(0.02, 0.03, 0.08, 0.55))

	var mr := Rect2(40.0 * s, 30.0 * s, v.x - 80.0 * s, 100.0 * s)
	_panel(mr, Color(0.08, 0.1, 0.2, 0.92), Color(0.8, 0.7, 0.3))
	_text(message, mr, 38.0 * s, Color(1, 1, 1))

	var picking_enemy: bool = state == "target" and target_side == "enemy"
	for e in enemies:
		if e.hp <= 0:
			continue
		var head: Vector2 = _head_of(e)
		var w: float = 190.0 * s
		_text_outlined(e.fname, Rect2(head.x - w * 0.5, head.y - 52.0 * s, w, 36.0 * s), 30.0 * s, Color(1, 1, 1))
		_bar(Rect2(head.x - w * 0.5, head.y - 14.0 * s, w, 16.0 * s), float(e.hp) / float(e.max_hp), Color(0.85, 0.2, 0.2))
		if picking_enemy:
			_marker(head, s, Color(1.0, 0.9, 0.3))

	var picking_ally: bool = state == "target" and target_side == "ally"
	if current != null and (state == "menu" or state == "target") and current.hp > 0:
		_marker(_head_of(current), s, Color(1.0, 0.85, 0.3))
	for i in party.size():
		var p = party[i]
		var r: Rect2 = _party_rect(i)
		var off := Vector2.ZERO
		if p.flash > 0.0:
			off = Vector2(randf_range(-8.0, 8.0), 0)
		var rr := Rect2(r.position + off, r.size)
		var fill: Color = Color(0.1, 0.13, 0.25, 0.95)
		var border: Color = Color(0.35, 0.4, 0.6)
		if p.hp <= 0:
			fill = Color(0.12, 0.12, 0.12, 0.95)
		if p == current and (state == "menu" or state == "target"):
			border = Color(1.0, 0.85, 0.3)
		if picking_ally and p.hp > 0:
			border = Color(0.4, 1.0, 1.0)
			_marker(_head_of(p), s, Color(0.4, 1.0, 1.0))
		_panel(rr, fill, border, 4)
		var x: float = rr.position.x + 16.0 * s
		_text_left("%s  Nv%d" % [p.fname, p.level], Vector2(x, rr.position.y + 44.0 * s), 30.0 * s, Color(1, 1, 1))
		_text_left("PV %d/%d" % [p.hp, p.max_hp], Vector2(x, rr.position.y + 90.0 * s), 24.0 * s, Color(0.9, 0.9, 0.9))
		_bar(Rect2(x, rr.position.y + 100.0 * s, rr.size.x - 32.0 * s, 20.0 * s), float(p.hp) / float(p.max_hp), Color(0.3, 0.85, 0.35))
		_text_left("PM %d/%d" % [p.mp, p.max_mp], Vector2(x, rr.position.y + 152.0 * s), 24.0 * s, Color(0.9, 0.9, 0.9))
		_bar(Rect2(x, rr.position.y + 162.0 * s, rr.size.x - 32.0 * s, 20.0 * s), float(p.mp) / float(maxi(p.max_mp, 1)), Color(0.3, 0.55, 0.95))
		var xpf: float = float(p.xp) / float(p.xp_needed())
		_bar(Rect2(x, rr.position.y + 200.0 * s, rr.size.x - 32.0 * s, 10.0 * s), xpf, Color(0.8, 0.7, 0.3))

	if state == "menu" and current != null:
		for i in 4:
			var r: Rect2 = _menu_rect(i)
			var label: String = menu_labels[i]
			var disabled: bool = false
			if i == 1:
				label = "%s (%d PM)" % [current.skill_name, current.skill_cost]
				disabled = current.mp < current.skill_cost
			var fill: Color = Color(0.15, 0.2, 0.4, 0.95)
			var tcol: Color = Color(1, 1, 1)
			if disabled:
				fill = Color(0.15, 0.15, 0.18, 0.95)
				tcol = Color(0.55, 0.55, 0.6)
			_panel(r, fill, Color(0.8, 0.7, 0.3))
			_text(label, r, 28.0 * s, tcol)
	elif state == "target":
		_panel(_cancel_rect(), Color(0.3, 0.12, 0.12, 0.95), Color(0.9, 0.5, 0.4))
		_text("Cancelar", _cancel_rect(), 32.0 * s, Color(1, 1, 1))

	var font: Font = ThemeDB.fallback_font
	for ft in floats:
		var a: float = clampf(1.0 - ft.t, 0.0, 1.0)
		var fc: Color = Color(ft.color.r, ft.color.g, ft.color.b, a)
		var p2: Vector2 = Vector2(ft.pos.x - 40.0 * s, ft.pos.y)
		ui.draw_string_outline(font, p2, ft.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(56.0 * s), 8, Color(0, 0, 0, a))
		ui.draw_string(font, p2, ft.text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(56.0 * s), fc)
