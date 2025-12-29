extends Node

signal change_now_hand(item: Item)
signal change_hand_equipment(item: Item)  # 손 장비 변경 시그널
signal change_body_equipment(item: Item)  # 몸통 장비 변경 시그널
signal change_head_equipment(item: Item)  # 머리 장비 변경 시그널
signal stamina_changed()  # 스태미나 변화 신호
signal craft_tier_changed(new_tier: int)  # 제작대 tier 변경 시그널


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

# 근처에 있는 제작대들 (tier별로 추적)
var nearby_craft_tables : Dictionary = {}  # {tier: [obsticle_node, ...]}
var highest_nearby_tier : int = 0  # 근처에 있는 가장 높은 tier

# 스태미나 변수
var stamina: int = 100:
	set(value):
		stamina = max(0, min(100, value))  # 0~100 사이로 제한
		stamina_changed.emit()

# HP 변수
signal hp_changed()  # HP 변화 신호
var player_hp: int = 90:
	set(value):
		player_hp = max(0, min(100, value))  # 0~100 사이로 제한
		hp_changed.emit()

# 허기 변수
signal hunger_changed()  # 허기 변화 신호
var player_hunger: int = 90:
	set(value):
		player_hunger = max(0, min(100, value))  # 0~100 사이로 제한
		hunger_changed.emit()
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
	# resipis 폴더의 모든 .tres 파일을 자동으로 로드
	var recipe_dir_path = "res://resipi/resipis/"
	var dir = DirAccess.open(recipe_dir_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var loaded_count = 0
		
		# 디렉토리의 모든 파일을 순회
		while file_name != "":
			# .tres 파일만 로드
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				var full_path = recipe_dir_path + file_name
				var recipe = load(full_path)
				
				if recipe and recipe is resipi:
					learn_recipe(recipe)
					loaded_count += 1
					print("📜 [레시피 로드] ", file_name, " 로드 완료")
				else:
					print("⚠️ [레시피 로드 실패] ", file_name, " - resipi 타입이 아님")
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
		print("✅ [레시피 초기화 완료] 총 ", loaded_count, "개의 레시피 로드됨")
	else:
		print("❌ [레시피 로드 실패] resipis 폴더를 열 수 없습니다: ", recipe_dir_path)

# 새로운 레시피를 배우는 함수
func learn_recipe(recipe: resipi):
	# 이미 알고 있는 레시피인지 확인
	if not is_recipe_known(recipe):
		known_recipes.append(recipe)
		return true
	else:
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

# 현재 제작 가능한 레시피만 반환하는 함수 (tier 체크 포함)
func get_craftable_recipes() -> Array[resipi]:
	var craftable : Array[resipi] = []
	
	for recipe in known_recipes:
		# required_tier가 0이면 제작대 불필요
		if recipe.required_tier == 0:
			craftable.append(recipe)
		# required_tier가 있으면 해당 tier 이상의 제작대가 근처에 있어야 함
		elif recipe.required_tier <= highest_nearby_tier:
			craftable.append(recipe)
	
	return craftable

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
		return true
	return false

# 인벤토리에서 특정 아이템의 총 개수를 계산하는 함수
# target_item: 확인하고자 하는 아이템
# 반환값: 인벤토리에 있는 해당 아이템의 총 개수
func get_item_count_in_inventory(target_item: Item) -> int:
	var total_count = 0
	
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
				break
	
	if inventory_ui:
		var texture_rect = inventory_ui.get_node_or_null("TextureRect2")
		
		if texture_rect:
			var slots = texture_rect.get_children()
			
			for slot in slots:
				# ItemSlot 타입인지 확인 후 thing 속성 체크
				if slot.has_method("_ready") and slot.thing:
					# 아이템 이름 비교 (공백 제거 및 소문자 변환으로 안전한 비교)
					var slot_name = slot.thing.name.strip_edges().to_lower()
					var target_name = target_item.name.strip_edges().to_lower()
					
					if slot_name == target_name:
						total_count += slot.thing.count
	
	# 손에 든 아이템도 확인
	if now_hand:
		var hand_name = now_hand.name.strip_edges().to_lower()
		var target_name = target_item.name.strip_edges().to_lower()
		
		if hand_name == target_name:
			total_count += now_hand.count
	
	return total_count

# 인벤토리 UI 참조를 설정하는 함수 (inventory.gd에서 호출)
func set_inventory_ui(ui_node):
	inventory_ui = ui_node

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

## 근처에 제작대가 들어왔을 때 호출
## craft_table_node: 제작대 노드 (obsticle)
func add_nearby_craft_table(craft_table_node):
	if not craft_table_node or not craft_table_node.thing:
		return
	
	var tier = craft_table_node.thing.tier
	
	# tier별 배열에 추가
	if not nearby_craft_tables.has(tier):
		nearby_craft_tables[tier] = []
	
	if not nearby_craft_tables[tier].has(craft_table_node):
		nearby_craft_tables[tier].append(craft_table_node)
		print("🔨 [제작대 추가] tier ", tier, " 제작대 근처 진입")
		update_highest_tier()

## 근처에서 제작대가 나갔을 때 호출
## craft_table_node: 제작대 노드 (obsticle)
func remove_nearby_craft_table(craft_table_node):
	if not craft_table_node or not craft_table_node.thing:
		return
	
	var tier = craft_table_node.thing.tier
	
	# tier별 배열에서 제거
	if nearby_craft_tables.has(tier):
		nearby_craft_tables[tier].erase(craft_table_node)
		
		# 배열이 비었으면 키 제거
		if nearby_craft_tables[tier].is_empty():
			nearby_craft_tables.erase(tier)
		
		print("🔨 [제작대 제거] tier ", tier, " 제작대 근처 이탈")
		update_highest_tier()

## 가장 높은 tier를 업데이트하는 함수
func update_highest_tier():
	var old_tier = highest_nearby_tier
	highest_nearby_tier = 0
	
	for tier in nearby_craft_tables.keys():
		if tier > highest_nearby_tier:
			highest_nearby_tier = tier
	
	print("🔨 [제작대] 현재 최고 tier: ", highest_nearby_tier)
	
	# tier가 변경되었으면 시그널 발생
	if old_tier != highest_nearby_tier:
		craft_tier_changed.emit(highest_nearby_tier)

## 인벤토리에서 특정 아이템을 제거하는 함수
## target_item: 제거하고자 하는 아이템
## remove_count: 제거할 개수
## 반환값: 실제로 제거된 개수 (인벤토리에 충분하지 않으면 제거 가능한 만큼만 제거)
func remove_item_from_inventory(target_item: Item, remove_count: int) -> int:
	var removed_count = 0
	
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
				break
	
	if inventory_ui:
		var texture_rect = inventory_ui.get_node_or_null("TextureRect2")
		
		if texture_rect:
			var slots = texture_rect.get_children()
			
			# 슬롯들을 순회하면서 아이템 제거
			for slot in slots:
				if removed_count >= remove_count:
					break
				
				# ItemSlot 타입인지 확인 후 thing 속성 체크
				if slot.has_method("_ready") and slot.thing:
					# 아이템 이름 비교
					var slot_name = slot.thing.name.strip_edges().to_lower()
					var target_name = target_item.name.strip_edges().to_lower()
					
					if slot_name == target_name:
						var available_count = slot.thing.count
						var to_remove = min(available_count, remove_count - removed_count)
						
						slot.thing.count -= to_remove
						removed_count += to_remove
						
						# 아이템 개수가 0이 되면 슬롯 비우기
						if slot.thing.count <= 0:
							slot.thing = null
						else:
							# 슬롯 UI 업데이트
							slot.update_display()
	
	# 손에 든 아이템도 확인
	if removed_count < remove_count and now_hand:
		var hand_name = now_hand.name.strip_edges().to_lower()
		var target_name = target_item.name.strip_edges().to_lower()
		
		if hand_name == target_name:
			var available_count = now_hand.count
			var to_remove = min(available_count, remove_count - removed_count)
			
			now_hand.count -= to_remove
			removed_count += to_remove
			
			# 아이템 개수가 0이 되면 손 비우기
			if now_hand.count <= 0:
				now_hand = null
			
			change_now_hand.emit(now_hand)
	
	return removed_count
