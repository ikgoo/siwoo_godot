extends Control
@onready var control = $Control
@onready var item_maker_veiw = $Control/item_maker_veiw
@onready var grid_container = $Control/GridContainer

# maker_item_slot 씬을 미리 로드
var maker_slot_scene = preload("res://maker_item_slot.tscn")
# 노드가 씬 트리에 추가될 때 호출
func _ready():
	# 레시피 슬롯들 생성
	create_recipe_slots()

# 알려진 레시피만큼 maker_item_slot을 생성하는 함수
func create_recipe_slots():
	# 기존 슬롯들 제거
	clear_existing_slots()
	
	# 글로벌 inventory_maneger에서 알려진 레시피들 가져오기
	var known_recipes = InventoryManeger.get_known_recipes()
	print("알려진 레시피 개수: ", known_recipes.size())
	
	# 각 레시피마다 슬롯 생성
	for recipe in known_recipes:
		create_slot_for_recipe(recipe)

# 기존 슬롯들을 제거하는 함수
func clear_existing_slots():
	# VBoxContainer의 모든 자식 노드 제거
	for child in grid_container.get_children():
		child.queue_free()

# 특정 레시피를 위한 슬롯을 생성하는 함수
func create_slot_for_recipe(recipe: resipi):
	# 새로운 maker_item_slot 인스턴스 생성
	var slot_instance = maker_slot_scene.instantiate()
	
	# 레시피를 직접 설정 (instantiate 직후에는 가능)
	slot_instance.item_make = recipe
	
	# VBoxContainer에 추가
	grid_container.add_child(slot_instance)
	
	print("레시피 슬롯 생성됨: ", recipe.end_tem.name)

# 레시피 슬롯들을 새로고침하는 함수 (새 레시피를 배웠을 때 사용)
func refresh_recipe_slots():
	create_recipe_slots()


func _on_button_button_down():
	control.visible = !control.visible
