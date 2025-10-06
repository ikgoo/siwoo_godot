extends Control
@onready var thing_name = $thing_name
@onready var thing_img = $thing_img
@onready var mete_1 = $mete_1
@onready var mete_2 = $mete_2
@onready var mete_3 = $mete_3
@onready var mete_4 = $mete_4
@onready var mete_img_1 = $mete_img_1
@onready var mete_img_2 = $mete_img_2
@onready var mete_img_3 = $mete_img_3
@onready var mete_img_4 = $mete_img_4

var now_veiwing : resipi
var update_timer : Timer

# 노드가 씬 트리에 추가될 때 호출되는 함수
func _ready():
	# 돌 도끼 제작법을 로드해서 현재 보고 있는 레시피로 설정 (테스트용)
	now_veiwing = load("res://resipi/resipis/stone_axe.tres")
	# 레시피 정보를 UI에 표시
	veiwing()
	
	# 인벤토리 변경 시그널에 연결
	if InventoryManeger:
		InventoryManeger.change_now_hand.connect(_on_inventory_changed)
	
	# 주기적 업데이트용 타이머 설정 (0.5초마다 업데이트)
	update_timer = Timer.new()
	update_timer.wait_time = 0.5
	update_timer.timeout.connect(_on_update_timer_timeout)
	update_timer.autostart = true
	add_child(update_timer)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# 인벤토리 변경 시 호출되는 함수
func _on_inventory_changed(item: Item):
	# 재료 색상 즉시 업데이트
	update_material_colors()

# 타이머 시간 초과 시 호출되는 함수
func _on_update_timer_timeout():
	# 주기적으로 재료 색상 업데이트
	update_material_colors()


# 현재 선택된 레시피를 UI에 표시하는 함수
# now_veiwing 레시피의 재료들과 완성품 정보를 화면에 보여줌
func veiwing():
	# 현재 보고 있는 레시피가 없으면 함수 종료
	if now_veiwing == null:
		return
	
	# 완성품 정보 설정
	thing_name.text = now_veiwing.end_tem.name
	thing_img.texture = now_veiwing.end_tem.img
	
	# 재료 슬롯들을 배열로 묶어서 관리하기 쉽게 함
	var mete_slots = [mete_1, mete_2, mete_3, mete_4]
	var mete_img_slots = [mete_img_1, mete_img_2, mete_img_3, mete_img_4]
	
	# 모든 재료 슬롯 초기화 (빈 상태로 만들기)
	for i in range(4):
		mete_slots[i].text = ""
		mete_img_slots[i].texture = null
		mete_slots[i].visible = false
		mete_img_slots[i].visible = false
	
	# 필요한 재료들을 각 슬롯에 설정
	for i in range(min(now_veiwing.item_need.size(), 4)):
		var needed_item = now_veiwing.item_need[i]
		
		# 인벤토리에서 해당 아이템의 개수 확인
		var current_count = InventoryManeger.get_item_count_in_inventory(needed_item.r_item)
		var required_count = needed_item.count
		
		# 디버그 출력
		print("재료 체크: ", needed_item.r_item.name, " - 보유: ", current_count, ", 필요: ", required_count)
		
		# 재료 이름과 개수 설정 (예: "사과 x5")
		mete_slots[i].text = needed_item.r_item.name + " x" + str(required_count)
		
		# 재료가 부족한지 확인하여 텍스트 색상을 개별적으로 설정
		if current_count >= required_count:
			# 재료가 충분하면 흰색으로 설정
			print("재료 충분! ", needed_item.r_item.name, " 흰색으로 표시")
			update_text_color(mete_slots[i], Color.WHITE)
		else:
			# 재료가 부족하면 빨간색으로 설정
			print("재료 부족! ", needed_item.r_item.name, " 빨간색으로 표시")
			update_text_color(mete_slots[i], Color.RED)
		
		# 재료 이미지 설정
		mete_img_slots[i].texture = needed_item.r_item.img
		# 슬롯을 보이게 설정
		mete_slots[i].visible = true
		mete_img_slots[i].visible = true

# 라벨의 텍스트 색상을 변경하는 함수
# label: 색상을 변경할 Label 노드
# color: 설정할 색상
func update_text_color(label: Label, color: Color):
	# modulate를 사용하여 색상 변경 (더 간단함)
	label.modulate = color

# 레시피를 설정하고 UI를 업데이트하는 함수
# recipe: 설정할 레시피
func set_recipe(recipe: resipi):
	now_veiwing = recipe
	veiwing()

# 인벤토리 변화에 따라 재료 색상을 실시간으로 업데이트하는 함수
# 인벤토리 변경 시그널과 연결하여 사용할 수 있음
func update_material_colors():
	# 현재 보고 있는 레시피가 없으면 업데이트 불필요
	if now_veiwing == null:
		return
	
	# 재료 슬롯들 배열
	var mete_slots = [mete_1, mete_2, mete_3, mete_4]
	
	# 각 재료 슬롯의 색상을 개별적으로 업데이트
	for i in range(min(now_veiwing.item_need.size(), 4)):
		var needed_item = now_veiwing.item_need[i]
		var current_count = InventoryManeger.get_item_count_in_inventory(needed_item.r_item)
		var required_count = needed_item.count
		
		print("색상 업데이트 - ", needed_item.r_item.name, ": 보유 ", current_count, " / 필요 ", required_count)
		
		# 각 재료별로 독립적으로 색상 설정
		if current_count >= required_count:
			# 재료가 충분하면 흰색(또는 검은색)으로 설정
			update_text_color(mete_slots[i], Color.WHITE)
			print("재료 충분! ", needed_item.r_item.name, " 흰색으로 표시")
		else:
			# 재료가 부족하면 빨간색으로 설정
			update_text_color(mete_slots[i], Color.RED)
			print("재료 부족! ", needed_item.r_item.name, " 빨간색으로 표시")


func _on_make_button_down():
	# 현재 보고 있는 레시피가 없으면 제작 불가
	if now_veiwing == null:
		print("제작할 레시피가 선택되지 않음")
		return
	
	# 모든 재료가 충분한지 확인
	if not check_all_materials_available():
		print("재료가 부족하여 제작할 수 없습니다")
		return
	
	# 재료 소모
	consume_materials()
	
	# 완성품을 인벤토리에 추가
	add_crafted_item_to_inventory()
	
	# UI 업데이트 (재료 색상 다시 체크)
	update_material_colors()
	
	print("제작 완료: ", now_veiwing.end_tem.name)

# 모든 재료가 충분한지 확인하는 함수
func check_all_materials_available() -> bool:
	print("=== 재료 확인 시작 ===")
	
	for needed_item in now_veiwing.item_need:
		var current_count = InventoryManeger.get_item_count_in_inventory(needed_item.r_item)
		var required_count = needed_item.count
		
		print("재료 체크: ", needed_item.r_item.name, " - 보유: ", current_count, " / 필요: ", required_count)
		
		if current_count < required_count:
			print("❌ 재료 부족: ", needed_item.r_item.name)
			return false
	
	print("✅ 모든 재료 충분")
	return true

# 제작에 필요한 재료들을 인벤토리에서 소모하는 함수
func consume_materials():
	print("=== 재료 소모 시작 ===")
	
	for needed_item in now_veiwing.item_need:
		var remaining_to_consume = needed_item.count
		
		# 인벤토리에서 해당 아이템 찾아서 소모
		if InventoryManeger.inventory_ui:
			var texture_rect = InventoryManeger.inventory_ui.get_node_or_null("TextureRect2")
			if texture_rect:
				var slots = texture_rect.get_children()
				
				for slot in slots:
					if remaining_to_consume <= 0:
						break
						
					if slot.has_method("_ready") and slot.thing:
						var slot_name = slot.thing.name.strip_edges().to_lower()
						var target_name = needed_item.r_item.name.strip_edges().to_lower()
						
						if slot_name == target_name:
							var consume_amount = min(slot.thing.count, remaining_to_consume)
							slot.thing.count -= consume_amount
							remaining_to_consume -= consume_amount
							
							print("재료 소모: ", slot.thing.name, " -", consume_amount, " (남은 개수: ", slot.thing.count, ")")
							
							# 아이템이 0개가 되면 슬롯에서 제거
							if slot.thing.count <= 0:
								slot.thing = null
		
		# 손에 든 아이템도 확인
		if remaining_to_consume > 0 and InventoryManeger.now_hand:
			var hand_name = InventoryManeger.now_hand.name.strip_edges().to_lower()
			var target_name = needed_item.r_item.name.strip_edges().to_lower()
			
			if hand_name == target_name:
				var consume_amount = min(InventoryManeger.now_hand.count, remaining_to_consume)
				InventoryManeger.now_hand.count -= consume_amount
				remaining_to_consume -= consume_amount
				
				print("손 아이템 소모: ", InventoryManeger.now_hand.name, " -", consume_amount)
				
				# 손에 든 아이템이 0개가 되면 제거
				if InventoryManeger.now_hand.count <= 0:
					InventoryManeger.now_hand = null

# 완성품을 인벤토리의 빈 슬롯에 추가하는 함수
func add_crafted_item_to_inventory():
	print("=== 완성품 인벤토리 추가 ===")
	
	# 완성품 복사본 생성
	var crafted_item = now_veiwing.end_tem.duplicate()
	crafted_item.count = 1  # 기본적으로 1개 제작
	
	# 인벤토리에서 빈 슬롯 찾기
	if InventoryManeger.inventory_ui:
		var texture_rect = InventoryManeger.inventory_ui.get_node_or_null("TextureRect2")
		if texture_rect:
			var slots = texture_rect.get_children()
			
			for slot in slots:
				if slot.has_method("_ready") and slot.thing == null:
					# 빈 슬롯 발견, 완성품 배치
					slot.thing = crafted_item
					print("완성품 배치: ", crafted_item.name, " → 슬롯 ", slot.name)
					return
			
			print("❌ 인벤토리에 빈 슬롯이 없습니다!")
		else:
			print("❌ TextureRect2를 찾을 수 없습니다!")
	else:
		print("❌ 인벤토리 UI를 찾을 수 없습니다!")
