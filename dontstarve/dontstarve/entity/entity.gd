extends Resource
class_name entity

## 기본 정보
@export var entity_name : String = "알 수 없는 생명체"  ## Entity의 이름
@export_multiline var description : String = ""  ## Entity의 설명

## 기본 스탯
@export var hp : int
@export var speed : float
@export var scale : Vector3i
@export var flying : bool
@export var recog : int
@export var dead_tem : Array[obsticle_get] #그냥 이런느낌 새로만들기 귀찮음 ㅋ 그래서 걍 obsticle_get으로
@export var img : Texture2D
@export var img_xy : Vector2i
@export var pixel_s : int = 16
## 달의 위상 시스템
## moon_phase_spawn: 등장 가능한 최소 달 위상 (0~5)
## - 0: 모든 위상에서 등장 (0,1,2,3,4,5)
## - 1: 위상 1 이상에서 등장 (1,2,3,4,5)
## - 2: 위상 2 이상에서 등장 (2,3,4,5)
## - 3: 위상 3 이상에서 등장 (3,4,5)
## - 4: 위상 4 이상에서 등장 (4,5)
## - 5: 위상 5에서만 등장 (5)
@export var moon_phase_spawn : int = 0

## moon_phase_power_boost: 달 위상에 따른 능력치 강화 배율
## 1.0이 기본값, 1.5면 50% 강화
@export var moon_phase_power_boost : float = 1.0
func take_damage(dam:int):
	hp -= dam
