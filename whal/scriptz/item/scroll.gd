extends Resource

class_name Scroll

@export var name : String
@export var real_tmi : String
@export var can_use : bool 
#액티브 스킬 쿨타임(초) - 패시브면 안 씀
@export var cool : float = 1.0
@export var texture : Texture2D
@export_enum("normal","rare","epic","mistic") var rarity : String

#스탯 보정
@export_group("스탯")
@export var hp_add : int = 0
@export var max_hp_add : int = 0
@export var damage_add : int = 0
@export var arrow_add : int = 0
@export var quiver_add : int = 0
@export var big_arrow_add : int = 0

#아이템 효과
func use():
	Gamemaneger.max_hp += max_hp_add
	Gamemaneger.hp += hp_add + max_hp_add
	if Gamemaneger.hp > Gamemaneger.max_hp:
		Gamemaneger.hp = Gamemaneger.max_hp
	Gamemaneger.damage_add += damage_add
	Gamemaneger.small_attack_p += arrow_add
	Gamemaneger.can_small_attack_r += quiver_add
	Gamemaneger.big_attack_p += big_arrow_add

func unuse():
	Gamemaneger.max_hp -= max_hp_add
	Gamemaneger.damage_add -= damage_add
	Gamemaneger.small_attack_p -= arrow_add
	Gamemaneger.can_small_attack_r -= quiver_add
	Gamemaneger.big_attack_p -= big_arrow_add
	if Gamemaneger.hp > Gamemaneger.max_hp:
		Gamemaneger.hp = Gamemaneger.max_hp
