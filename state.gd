extends RefCounted

const Fighter = preload("res://fighter.gd")
const HERO_NAME := "Aris"

static var party: Array = []
static var defeated: Dictionary = {}
static var flags: Dictionary = {}
static var last_zone: String = "world"
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


static func make_enemy(kind: String):
	var f = null
	if kind == "arpia":
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
