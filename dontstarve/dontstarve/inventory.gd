extends Control
var on_area = [false, -1]
const ITEM_SLOT = preload("res://item_slot.tscn")
@onready var mouse = $mouse
@onready var areas = $areas
@onready var sprite_2d_2 = $TextureRect
@onready var texture_rect = $TextureRect2
const STONE_PICKAXE = preload("res://item/tems/stone_pickaxe.tres")
@onready var label = $TextureRect/Label
const STONE_AXE = preload("res://item/tems/stone_axe.tres")
const APPLE = preload("res://item/tems/apple.tres")
@onready var item_slot = $TextureRect4/item_slot
@onready var item_slot_2 = $TextureRect4/item_slot2
@onready var item_slot_3 = $TextureRect4/item_slot3
const BATTLE_GROUND_WINNER = preload("res://item/tems/battle_ground_winner.tres")
@onready var hp = $hp
@onready var stamina = $stamina
@onready var fun = $fun
@onready var hunger = $hunger

func _ready():
	InventoryManeger.hand = item_slot
	InventoryManeger.body = item_slot_2
	InventoryManeger.head = item_slot_3
	
	# 인벤토리 UI 참조를 InventoryManager에 등록
	InventoryManeger.set_inventory_ui(self)
	
	InventoryManeger.change_now_hand.connect(change_now_hand)
	# 스태미나 변화 신호 연결
	InventoryManeger.stamina_changed.connect(update_stamina_label)
	# HP 변화 신호 연결
	InventoryManeger.hp_changed.connect(update_hp_label)
	
	# 초기 라벨 업데이트
	update_stamina_label()
	update_hp_label()

	
	var c = texture_rect.get_children()
	for index in range(c.size()):
		var a = c[index]
		a.slot_no = index
		
	# 아이템 리소스를 duplicate()로 복사해서 독립적인 인스턴스 생성
	var apple1 = APPLE.duplicate()
	apple1.count = 1
	c[0].thing = apple1
	
	var apple2 = APPLE.duplicate()
	apple2.count = 9
	c[1].thing = apple2
	
	var apple3 = APPLE.duplicate()
	apple3.count = 7
	c[2].thing = apple3
	
	var stone_axe = STONE_AXE.duplicate()
	stone_axe.count = 1
	c[4].thing = stone_axe
	var stone_paxe = STONE_PICKAXE.duplicate()
	c[6].thing = stone_paxe
	
	var battle_ground_winner = BATTLE_GROUND_WINNER.duplicate()
	battle_ground_winner.count = 1
	c[5].thing = battle_ground_winner
func change_now_hand(item: Item):
	if item:
		sprite_2d_2.texture = item.img
		label.text = str(item.count)
	else:
		sprite_2d_2.texture = null
		label.text = ''
		
func drop(thing):
	get_parent().get_parent().drop(thing)

func _process(delta):
	# 글로벌 마우스 위치를 현재 노드 좌표계로 변환
	sprite_2d_2.position = get_local_mouse_position()
	sprite_2d_2.position -= Vector2(60,60)
	
	##if Input.is_action_just_pressed("clicks"):
		##if on_area[0]:  # 슬롯 위에서 클릭
			##if InventoryManeger.now_hand:
				##place_item_from_hand(on_area[1])
			##else:
				##pick_up_item_from_slot(on_area[1])
		##else:  # 빈 공간에서 클릭
			##if InventoryManeger.now_hand:
				##drop_item_to_ground()
##
#### 손에서 슬롯으로 아이템 배치
##func place_item_from_hand(slot_index: int):
	##if InventoryManeger.now_hand:
		##place_item(slot_index, InventoryManeger.now_hand)
		##InventoryManeger.now_hand = null
##
#### 슬롯에서 아이템 집기
##func pick_up_item_from_slot(slot_index: int):
	##var slot_data = InventoryManeger.inventory[slot_index]
	##if slot_data.size() > 0:  # 슬롯에 아이템이 있으면
		##InventoryManeger.now_hand = slot_data[0]
		##slot_data[0].following = true
		##InventoryManeger.inventory[slot_index] = []  # 슬롯 비우기
##
#### 아이템을 특정 슬롯에 배치
##func place_item(slot_index: int, item_instance: Item):
	##InventoryManeger.inventory[slot_index] = [item_instance, InventoryManeger.inventory[slot_index][1]]
	##var new = ITEM_SLOT.instantiate()
	##new.thing = item_instance
	##areas.add_child(new)
	##new.position = Vector2(slot_index * 35, 1)
##
#### 아이템을 땅에 떨어뜨리기
##func drop_item_to_ground():
	##if InventoryManeger.now_hand:
		##InventoryManeger.now_hand.following = false
		##InventoryManeger.now_hand.position = get_global_mouse_position()
		##InventoryManeger.now_hand = null
##
##
#### 테스트 함수: 1번 칸에 사과 넣기
##func test_add_apple_to_slot_1():
	### 사과 아이템 리소스 로드
	##var apple_item = load("res://item/tems/apple.tres") as Item
	##if apple_item:
		### 1번 칸(인덱스 0)에 사과 1개 넣기
		##InventoryManeger.inventory[0] = [apple_item, 1]
	##place_item(0, apple_item)


func _on_texture_rect_2_mouse_entered():
	# main.gd에 마우스가 인벤토리에 들어왔다고 알림
	get_parent().get_parent().is_mouse_over_inventory = true

func _on_texture_rect_2_mouse_exited():
	# main.gd에 마우스가 인벤토리에서 나갔다고 알림
	get_parent().get_parent().is_mouse_over_inventory = false

func add_item(thing):
	var item_to_add = thing.thing
	
	var c = texture_rect.get_children()
	var remaining_count = item_to_add.count
	
	# max_count가 1인 아이템은 합치기 로직을 건너뛰고 바로 빈 슬롯에 배치
	if item_to_add.max_count <= 1:
		
		# 빈 슬롯 찾아서 바로 배치
		for slot in c:
			if not slot.thing:
				slot.thing = item_to_add
				return
		
		return
	
	# max_count가 2 이상인 아이템만 합치기 로직 실행
	
	# 1단계: 같은 아이템이 있는 슬롯 찾아서 합치기
	for slot in c:
		if remaining_count <= 0:
			break
			
		# 같은 아이템이 있는 슬롯 찾기
		if slot.thing and slot.thing.name == item_to_add.name:
			var existing_item = slot.thing
			var available_space = existing_item.max_count - existing_item.count
			
			if available_space > 0:
				var add_amount = min(remaining_count, available_space)
				existing_item.count += add_amount
				remaining_count -= add_amount
				
				
				# UI 업데이트
				slot.update_display()
	
	# 2단계: 남은 아이템을 빈 슬롯에 배치
	while remaining_count > 0:
		var empty_slot = null
		
		# 빈 슬롯 찾기
		for slot in c:
			if not slot.thing:
				empty_slot = slot
				break
		
		if empty_slot == null:
			break
		
		# 새 아이템 인스턴스 생성
		var new_item = item_to_add.duplicate()
		new_item.count = min(remaining_count, item_to_add.max_count)
		remaining_count -= new_item.count
		
		# 빈 슬롯에 배치
		empty_slot.thing = new_item
	

# 스태미나 라벨을 업데이트하는 함수
func update_stamina_label():
	if stamina:
		stamina.text = str(InventoryManeger.stamina)

# HP 라벨을 업데이트하는 함수
func update_hp_label():
	if hp:
		hp.text = str(InventoryManeger.player_hp)
			 
			
