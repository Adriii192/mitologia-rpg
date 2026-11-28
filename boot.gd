extends Node

const FILES := ["res://main.gd", "res://zones.gd", "res://state.gd", "res://fighter.gd", "res://battle.gd", "res://dialog.gd", "res://companion.gd", "res://textures.gd", "res://house.gd", "res://character.gd", "res://nature.gd", "res://forest.gd", "res://monster.gd", "res://village.gd"]


func _ready() -> void:
	var problems: Array = []
	for f in FILES:
		if not ResourceLoader.exists(f):
			problems.append("FALTA el archivo: " + str(f).get_file())
	if problems.is_empty():
		for f in FILES:
			var s = load(f)
			if s == null:
				problems.append("Tiene errores de código: " + str(f).get_file())
			elif s is GDScript and not s.can_instantiate():
				problems.append("Tiene errores de código: " + str(f).get_file())
	if problems.is_empty():
		var game := Node3D.new()
		game.set_script(load("res://main.gd"))
		add_child(game)
		return
	_show_problems(problems)


func _show_problems(problems: Array) -> void:
	var text: String = "El juego no puede arrancar.\n\n" + "\n".join(problems) + "\n\nRevisa esos archivos en GitHub."
	print(text)
	var layer := CanvasLayer.new()
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.05, 0.05)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 40)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 40
	label.offset_top = 40
	label.offset_right = -40
	layer.add_child(label)
