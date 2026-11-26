extends CanvasLayer

signal finished

var lines: Array = []
var index: int = 0
var shown: float = 0.0
var active: bool = false
var ui: Control
var label: Label


func start(p_lines: Array) -> void:
	lines = p_lines
	index = 0
	shown = 0.0
	active = true
	layer = 15
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	add_child(ui)
	label = Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	_layout()


func _v() -> Vector2:
	return get_viewport().get_visible_rect().size


func _s() -> float:
	return _v().y / 1080.0


func _box() -> Rect2:
	var v: Vector2 = _v()
	var s: float = _s()
	return Rect2(60.0 * s, v.y - 300.0 * s, v.x - 120.0 * s, 250.0 * s)


func _layout() -> void:
	var s: float = _s()
	var b: Rect2 = _box()
	label.position = Vector2(b.position.x + 40.0 * s, b.position.y + 34.0 * s)
	label.size = Vector2(b.size.x - 80.0 * s, b.size.y - 60.0 * s)
	label.add_theme_font_size_override("font_size", int(40.0 * s))


func _full_text() -> String:
	if index >= lines.size():
		return ""
	return str(lines[index][1])


func _speaker() -> String:
	if index >= lines.size():
		return ""
	return str(lines[index][0])


func _process(delta: float) -> void:
	if not active:
		return
	shown += delta * 45.0
	_layout()
	var full: String = _full_text()
	label.text = full
	label.visible_characters = mini(full.length(), int(shown))
	var sp: String = _speaker()
	if sp == "":
		label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95))
	else:
		label.add_theme_color_override("font_color", Color(1, 1, 1))
	ui.queue_redraw()


func handle_touch() -> void:
	if not active:
		return
	var total: int = _full_text().length()
	if shown < float(total):
		shown = float(total)
		return
	index += 1
	shown = 0.0
	if index >= lines.size():
		active = false
		label.visible = false
		ui.queue_redraw()
		finished.emit()


func _speaker_color(sp: String) -> Color:
	if sp == "Aris":
		return Color(0.3, 0.5, 0.9)
	if sp == "Amaltea":
		return Color(0.85, 0.65, 0.15)
	return Color(0.4, 0.4, 0.5)


func _draw_ui() -> void:
	if not active or index >= lines.size():
		return
	var s: float = _s()
	var b: Rect2 = _box()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.16, 0.94)
	sb.border_color = Color(0.85, 0.7, 0.3)
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(18)
	ui.draw_style_box(sb, b)
	var sp: String = _speaker()
	if sp != "":
		var tag_w: float = 90.0 * s + sp.length() * 24.0 * s
		var tag := Rect2(b.position.x + 36.0 * s, b.position.y - 38.0 * s, tag_w, 66.0 * s)
		var tb := StyleBoxFlat.new()
		tb.bg_color = _speaker_color(sp)
		tb.border_color = Color(1, 1, 1, 0.9)
		tb.set_border_width_all(3)
		tb.set_corner_radius_all(14)
		ui.draw_style_box(tb, tag)
		var font: Font = ThemeDB.fallback_font
		ui.draw_string(font, Vector2(tag.position.x, tag.position.y + tag.size.y * 0.5 + 14.0 * s), sp, HORIZONTAL_ALIGNMENT_CENTER, tag.size.x, int(38.0 * s), Color(1, 1, 1))
	if shown >= float(_full_text().length()):
		var bob: float = sin(Time.get_ticks_msec() / 160.0) * 6.0 * s
		var c: Vector2 = Vector2(b.end.x - 60.0 * s, b.end.y - 40.0 * s + bob)
		ui.draw_colored_polygon(PackedVector2Array([c + Vector2(-16, -10) * s, c + Vector2(16, -10) * s, c + Vector2(0, 14) * s]), Color(1.0, 0.85, 0.3))
