extends Resource
class_name Item
enum wears_op{
	nothing,
	body,
	head
}
enum what_tool{
	nothing,
	pickaxe,
	axe,
	moon_axe,
	moon_pickaxe,
	weapon
}
@export var tier : int
@export var name : String
@export var img : Texture
@export var wear : wears_op
@export var eatable : bool
@export var negudo : bool  ## 내구도 시스템 활성화 여부
@export var wear_img : Texture
@export var count : int
@export var max_count : int
@export var can_hand : bool
@export var tool : what_tool
@export var damage : int = 0
@export var is_setable : bool
@export var set_obsticle : obsticle

@export_group("내구도 시스템")
@export var negudo_per : float = 100.0  ## 현재 내구도 (%)
@export var negudo_out : float = 0.5  ## 한 번 사용 시 감소량 (%)
@export_group("먹기 효과")
## 먹었을 때 회복량 [HP, 허기, 스태미나]
## 예: [10, 20, 15] = HP +10, 허기 +20, 스태미나 +15
@export var eat_up : Array[int] = [0, 0, 0]

func use_durability() -> bool:
	if not negudo:
		return false  # 내구도 시스템이 없는 아이템은 파괴되지 않음
	
	# 내구도 감소
	negudo_per -= negudo_out
	
	# 내구도가 0 이하가 되면 파괴
	if negudo_per <= 0:
		negudo_per = 0
		return true  # 아이템 파괴됨
	
	return false  # 아직 사용 가능
