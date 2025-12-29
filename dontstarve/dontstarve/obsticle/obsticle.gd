extends Resource

class_name obsticle
enum mineable{
	nothing,
	tree,
	stone,
	moon_stone,
	moon_tree,
	craft_table,
	collectable,
}

@export var tier : int
@export var name : String
@export var img : Texture2D
@export var sulmung : String
@export var moving : bool
@export var type : mineable
## 이 장애물 채굴에 적합한 도구
@export var suitable_tool : Item.what_tool = Item.what_tool.nothing
@export var times_mine : int
@export var things : Array[obsticle_get]
@export var offset : float
@export var collectable_thing : Array[Item]
@export var is_collectable : int
@export_group("수집 가능 아이템 이미지")
## 수집 전 이미지 (is_collectable이 1일 때 표시)
@export var img_before_collect : Texture2D
## 수집 후 이미지 (is_collectable이 0일 때 표시)
@export var img_after_collect : Texture2D
@export_group("타일 설정")
## 그리드 상에서 차지하는 너비 (타일 개수, 예: 3이면 3칸)
@export var grid_width : int = 3
## 그리드 상에서 차지하는 높이 (타일 개수, 예: 4이면 4칸)
@export var grid_height : int = 3

@export_group("성장 시스템")
## 성장 기능 활성화 여부
@export var is_growable : bool = false
## 성장 단계별 데이터 배열 (나이 순서대로, 비어있으면 기본 설정만 사용)
## 각 단계마다 개별적으로 성장 시간을 설정할 수 있습니다
@export var growth_stages : Array[ObGrowthStage] = []

@export_group("Area 설정")
## Area3D의 CollisionShape 크기 배율 (이미지 크기 * area_radius, 기본값 1.0)
## 1.0 = 이미지 크기 그대로, 1.5 = 이미지보다 1.5배 크게, 0.5 = 이미지보다 0.5배 작게
@export var area_radius : float = 1.0
