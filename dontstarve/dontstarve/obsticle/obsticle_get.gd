extends Resource
class_name obsticle_get

@export var get_item : Item     # 드롭될 아이템
@export var min_count : int     # 최소 드롭 개수
@export var max_count : int     # 최대 드롭 개수
@export var drop_chance : float = 1.0  # 드롭 확률 (0.0 ~ 1.0)

# 이 아이템이 드롭될지 확률적으로 결정하는 함수
func should_drop() -> bool:
	return randf() <= drop_chance

# min_count와 max_count 사이에서 균등한 확률로 개수 결정
func get_random_count() -> int:
	if min_count >= max_count:
		return min_count
	return randi_range(min_count, max_count)
