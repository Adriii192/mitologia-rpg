extends RefCounted

const Fighter = preload("res://fighter.gd")
const HERO_NAME := "Aris"

static var party: Array = []
static var defeated: Dictionary = {}
static var flags: Dictionary = {}
static var last_zone: String = "cap1"
static var last_pos: Vector3 = Vector3.ZERO
static var has_last: bool = false


static func _mk(n: String, col: Color, hp: int, mp: int, atk: int, defense: int, mag: int, skill: String, cost: int, kind: String, power: float):
	var f = Fighter.new()
	f.fname = n
	f.color = col
	f.max_hp = hp
	f.hp = hp
	f.max_mp = mp
	f.mp = mp
	f.atk = atk
	f.defense = defense
	f.mag = mag
	f.skill_name = skill
	f.skill_cost = cost
	f.skill_kind = kind
	f.skill_power = power
	return f


static func ensure_party() -> void:
	if party.size() > 0:
		return
	var aris = _mk(HERO_NAME, Color(0.2, 0.4, 0.9), 40, 10, 9, 4, 5, "Golpe heroico", 4, "single", 1.8)
	var nika = _mk("Nika", Color(0.2, 0.7, 0.4), 32, 12, 8, 3, 6, "Lluvia de flechas", 6, "all", 0.8)
	var dion = _mk("Dión", Color(0.8, 0.3, 0.25), 50, 6, 10, 6, 2, "Embestida", 3, "single", 1.6)
	dion.hp_gain = 10
	dion.def_gain = 2
	var eleni = _mk("Eleni", Color(0.9, 0.8, 0.4), 30, 16, 5, 3, 9, "Plegaria", 5, "heal", 2.0)
	eleni.mag_gain = 2
	eleni.mp_gain = 3
	party.append(aris)
	party.append(nika)
	party.append(dion)
	party.append(eleni)


static func enemy_info(kind: String) -> Dictionary:
	if kind == "arpia":
		return {"name": "Arpía", "color": Color(0.55, 0.25, 0.65), "scale": 1.0}
	if kind == "aelo":
		return {"name": "Arpía Aelo", "color": Color(0.8, 0.2, 0.35), "scale": 1.9}
	return {"name": "Sátiro", "color": Color(0.65, 0.38, 0.2), "scale": 1.0}


static func reset() -> void:
	party = []
	defeated = {}
	flags = {}
	last_zone = "cap1"
	last_pos = Vector3.ZERO
	has_last = false


const SAVE_PATH := "user://partida.cfg"


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func save_game(zone: String, pos: Vector3) -> void:
	var cf := ConfigFile.new()
	var arr: Array = []
	for p in party:
		arr.append({"lv": p.level, "xp": p.xp, "mhp": p.max_hp, "hp": p.hp, "mmp": p.max_mp, "mp": p.mp, "atk": p.atk, "def": p.defense, "mag": p.mag})
	cf.set_value("s", "party", arr)
	cf.set_value("s", "defeated", defeated)
	cf.set_value("s", "flags", flags)
	cf.set_value("s", "zone", zone)
	cf.set_value("s", "pos", pos)
	cf.set_value("s", "last_zone", last_zone)
	cf.set_value("s", "last_pos", last_pos)
	cf.set_value("s", "has_last", has_last)
	cf.save(SAVE_PATH)


# Devuelve {"zone": String, "pos": Vector3} o un diccionario vacio si falla.
static func load_game() -> Dictionary:
	var cf := ConfigFile.new()
	if cf.load(SAVE_PATH) != OK:
		return {}
	party = []
	ensure_party()
	var arr: Array = cf.get_value("s", "party", [])
	for i in mini(arr.size(), party.size()):
		var d: Dictionary = arr[i]
		var p = party[i]
		p.level = int(d.get("lv", 1))
		p.xp = int(d.get("xp", 0))
		p.max_hp = int(d.get("mhp", p.max_hp))
		p.hp = int(d.get("hp", p.max_hp))
		p.max_mp = int(d.get("mmp", p.max_mp))
		p.mp = int(d.get("mp", p.max_mp))
		p.atk = int(d.get("atk", p.atk))
		p.defense = int(d.get("def", p.defense))
		p.mag = int(d.get("mag", p.mag))
	defeated = cf.get_value("s", "defeated", {})
	flags = cf.get_value("s", "flags", {})
	last_zone = str(cf.get_value("s", "last_zone", "cap1"))
	last_pos = cf.get_value("s", "last_pos", Vector3.ZERO)
	has_last = bool(cf.get_value("s", "has_last", false))
	return {"zone": str(cf.get_value("s", "zone", "beach")), "pos": cf.get_value("s", "pos", Vector3.ZERO)}


static func make_enemy(kind: String):
	var f = null
	if kind == "aelo":
		f = _mk("Arpía Aelo", Color(0.8, 0.2, 0.35), 120, 0, 15, 5, 0, "", 0, "single", 1.0)
		f.xp_reward = 90
	elif kind == "arpia":
		f = _mk("Arpía", Color(0.55, 0.25, 0.65), 28, 0, 11, 2, 0, "", 0, "single", 1.0)
		f.xp_reward = 16
	else:
		f = _mk("Sátiro", Color(0.65, 0.38, 0.2), 36, 0, 9, 3, 0, "", 0, "single", 1.0)
		f.xp_reward = 14
	f.is_enemy = true
	return f


static func heal_all() -> void:
	for p in party:
		p.hp = p.max_hp
		p.mp = p.max_mp
		p.defending = false
