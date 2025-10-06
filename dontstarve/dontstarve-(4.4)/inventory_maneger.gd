extends Node

signal change_now_hand(item: Item)
signal change_hand_equipment(item: Item)
signal change_body_equipment(item: Item)
signal change_head_equipment(item: Item)
signal stamina_changed()  # 스태미나 변화 신호


var inventory = []
var hand = null  # 손 슬롯 UI 참조
var body = null  # 몸통 슬롯 UI 참조
var head = null  # 머리 슬롯 UI 참조
var inventory_ui = null  # 인벤토리 UI 참조

# 실제 장착된 장비 아이템들
var equipped_hand: Item = null
var equipped_body: Item = null
var equipped_head: Item = null

# 플레이어가 알고 있는 레시피들
var known_recipes : Array[resipi] = []

# 스태미나 변수
var stamina: int = 100:
	set(value):
		stamina = max(0, value)  # 0 이하로 내려가지 않게 제한
		stamina_changed.emit()
func _ready():
	for i in range(29):
		inventory.append([])
	# 기본 레시피들 초기화
	initialize_default_recipes()

var now_hand : Item = null :
	set(value):
		change_now_hand.emit(value)
		now_hand = value

# 기본 레시피들을 초기화하는 함수
func initialize_default_recipes():
	# resipis 폴더의 모든 레시피를 기본으로 추가
	var recipe_paths = [
		"res://resipi/resipis/chiken_winner.tres",
		"res://resipi/resipis/stone_axe.tres", 
		"res://resipi/resipis/stone_pickaxe.tres"
	]
	
	# 각 레시피 파일을 로드하고 추가
	for recipe_path in recipe_paths:
		var recipe = load(recipe_path)
		if recipe:
			learn_recipe(recipe)
			print("기본 레시피 추가됨: ", recipe.end_tem.name)
		else:
			print("레시피 로드 실패: ", recipe_path)

# 새로운 레시피를 배우는 함수
func learn_recipe(recipe: resipi):
	# 이미 알고 있는 레시피인지 확인
	if not is_recipe_known(recipe):
		known_recipes.append(recipe)
		print("새로운 레시피를 배웠습니다: ", recipe.end_tem.name)
		return true
	else:
		print("이미 알고 있는 레시피입니다: ", recipe.end_tem.name)
		return false

# 레시피를 알고 있는지 확인하는 함수
func is_recipe_known(recipe: resipi) -> bool:
	for known_recipe in known_recipes:
		if known_recipe == recipe:
			return true
	return false

# 알고 있는 모든 레시피를 반환하는 함수
func get_known_recipes() -> Array[resipi]:
	return known_recipes

# 특정 타입의 레시피들만 반환하는 함수
func get_recipes_by_type(recipe_type: resipi.r_type) -> Array[resipi]:
	var filtered_recipes : Array[resipi] = []
	for recipe in known_recipes:
		if recipe.type == recipe_type:
			filtered_recipes.append(recipe)
	return filtered_recipes

# 레시피를 잊는 함수 (필요시 사용)
func forget_recipe(recipe: resipi):
	var index = known_recipes.find(recipe)
	if index != -1:
		known_recipes.remove_at(index)
		print("레시피를 잊었습니다: ", recipe.end_tem.name)
		return true
	return false

# 인벤토리에서 특정 아이템의 총 개수를 계산하는 함수
# target_item: 확인하고자 하는 아이템
# 반환값: 인벤토리에 있는 해당 아이템의 총 개수
func get_item_count_in_inventory(target_item: Item) -> int:
	var total_count = 0
	
	print("=== 아이템 개수 계산 시작: ", target_item.name, " ===")
	
	# 인벤토리 UI가 설정되지 않았다면 자동으로 찾기
	if inventory_ui == null:
		var possible_paths = [
			"/root/Node3D/CanvasLayer/inventory",
			"/root/Main/CanvasLayer/inventory"
		]
		
		for path in possible_paths:
			var node = get_node_or_null(path)
			if node != null:
				inventory_ui = node
				print("인벤토리 UI 자동 감지: ", path)
				break
	
	if inventory_ui:
		var texture_rect = inventory_ui.get_node_or_null("TextureRect2")
		
		if texture_rect:
			var slots = texture_rect.get_children()
			print("총 ", slots.size(), "개의 슬롯 검사 중...")
			
			for slot in slots:
				# ItemSlot 타입인지 확인 후 thing 속성 체크
				if slot.has_method("_ready") and slot.thing:
					# 아이템 이름 비교 (공백 제거 및 소문자 변환으로 안전한 비교)
					var slot_name = slot.thing.name.strip_edges().to_lower()
					var target_name = target_item.name.strip_edges().to_lower()
					
					print("슬롯 아이템: '", slot.thing.name, "' (", slot.thing.count, "개)")
					
					if slot_name == target_name:
						print("✓ 아이템 일치! 개수 추가: ", slot.thing.count)
						total_count += slot.thing.count
					else:
						print("✗ 아이템 불일치")
	else:
		print("⚠️ 인벤토리 UI를 찾을 수 없음!")
	
	# 손에 든 아이템도 확인
	if now_hand:
		var hand_name = now_hand.name.strip_edges().to_lower()
		var target_name = target_item.name.strip_edges().to_lower()
		print("손에 든 아이템: '", now_hand.name, "' (", now_hand.count, "개)")
		
		if hand_name == target_name:
			print("✓ 손 아이템 일치! 개수 추가: ", now_hand.count)
			total_count += now_hand.count
		else:
			print("✗ 손 아이템 불일치")
	else:
		print("손에 든 아이템 없음")
	
	print("=== 최종 계산 결과: ", target_item.name, " = ", total_count, "개 ===")
	return total_count

# 인벤토리 UI 참조를 설정하는 함수 (inventory.gd에서 호출)
func set_inventory_ui(ui_node):
	inventory_ui = ui_node
	print("인벤토리 UI 참조 설정됨: ", ui_node)

# 특정 아이템이 충분한 개수만큼 있는지 확인하는 함수
# target_item: 확인하고자 하는 아이템
# required_count: 필요한 개수
# 반환값: 충분한 개수가 있으면 true, 부족하면 false
func has_enough_items(target_item: Item, required_count: int) -> bool:
	var current_count = get_item_count_in_inventory(target_item)
	return current_count >= required_count

# 스태미나를 변경하는 함수
func change_stamina(amount: int):
	stamina += amount
	print("스태미나 변경: ", amount, " (현재: ", stamina, ")")
