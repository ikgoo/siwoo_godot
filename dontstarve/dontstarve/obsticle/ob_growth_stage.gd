extends Resource

class_name ObGrowthStage

## 성장 단계 이름 (예: "씨앗", "새싹", "어린 나무", "성숙한 나무")
@export var stage_name : String = ""

## 이 단계에서 표시할 이미지 (null이면 obsticle의 기본 img 사용)
@export var stage_img : Texture2D = null

## 이 단계에서 채굴 시 나오는 아이템들 (비어있으면 obsticle의 기본 things 사용)
@export var stage_drops : Array[obsticle_get] = []

## 이 단계에서 채굴에 필요한 횟수 (0이면 obsticle의 기본 times_mine 사용)
@export var stage_times_mine : int = 0

## 이미지 오프셋 (0이면 obsticle의 기본 offset 사용)
@export var stage_offset : float = 0.0

## 이 단계에서 채굴 가능한지 여부
@export var is_mineable : bool = true

## 이 단계에서 채굴에 적합한 도구
@export var suitable_tool : Item.what_tool = Item.what_tool.nothing


@export_group("성장 시간 설정")
## 다음 단계로 성장하는데 걸리는 최소 시간 (초)
@export var growth_time_min : float = 60.0
## 다음 단계로 성장하는데 걸리는 최대 시간 (초)
@export var growth_time_max : float = 60.0

## 이 단계에서 다음 단계로 성장하는데 걸리는 시간을 랜덤으로 반환
func get_random_growth_time() -> float:
	if growth_time_min >= growth_time_max:
		return growth_time_min
	return randf_range(growth_time_min, growth_time_max)
