extends RefCounted

var fname: String = ""
var is_enemy: bool = false
var level: int = 1
var xp: int = 0
var max_hp: int = 30
var hp: int = 30
var max_mp: int = 10
var mp: int = 10
var atk: int = 8
var defense: int = 3
var mag: int = 5
var hp_gain: int = 8
var mp_gain: int = 2
var atk_gain: int = 2
var def_gain: int = 1
var mag_gain: int = 1
var skill_name: String = ""
var skill_cost: int = 0
var skill_kind: String = "single"
var skill_power: float = 1.5
var color: Color = Color(1, 1, 1)
var xp_reward: int = 0
var defending: bool = false
var flash: float = 0.0


func xp_needed() -> int:
	return 15 + level * 10


func level_up() -> void:
	level += 1
	max_hp += hp_gain
	hp = mini(max_hp, hp + hp_gain)
	max_mp += mp_gain
	mp = mini(max_mp, mp + mp_gain)
	atk += atk_gain
	defense += def_gain
	mag += mag_gain
