@tool
extends Control
class_name ItemSlot

var on_mouse = false
@export var slot_no: int
@onready var sprite = $TextureRect
var shift_hold = false
var following = false
var count : int = 0
@onready var percent = $percent

@onready var count_ = $count
enum thins{
	nothing,
	body,
	head,
	hand,
}

@export var is_thing : thins = thins["nothing"]
@export var thing: Item = null:
	set(value):
		thing = value
		if thing:
			if sprite:
				sprite.texture = thing.img
				update_count_display()
		else:
			if sprite:
				sprite.texture = null
				count_.text = ''
				percent.text = ''



func _ready():
	pass

func add_item(item: Item, form_slot: ItemSlot):
	thing = item

# UI 디스플레이 업데이트 함수
func update_display():
	if thing:
		if sprite:
			sprite.texture = thing.img
			update_count_display()
	else:
		if sprite:
			sprite.texture = null
			count_.text = ''
			percent.text = ''

func update_count_display():
	if not thing:
		count_.text = ''
		percent.text = ''
		return
	
	# 내구도 시스템이 활성화된 아이템
	if thing.negudo:
		count_.text = ''  # 개수는 표시하지 않음
		percent.text = str(int(thing.negudo_per)) + "%"
	# 일반 아이템 (개수 표시)
	else:
		percent.text = ''  # 내구도는 표시하지 않음
		count_.text = str(thing.count)
		

func _process(_delta):
	if following:
		# 글로벌 마우스 위치를 부모 좌표계로 변환
		var global_mouse_pos = get_global_mouse_position()
		var parent_node = get_parent()
		if parent_node:
			position = parent_node.to_local(global_mouse_pos)
	
	
	if Engine.is_editor_hint():
		return # 에디터 힌트 모드일 경우, 더 이상 진행하지 않고 함수를 종료합니다.
	
	# 스페이스바로 아이템 먹기
	if on_mouse and Input.is_action_just_pressed("space_bar"):
		if thing and thing.eatable:
			eat_item()
			return
	
	# 클릭 액션 감지 디버깅
	if Input.is_action_just_released('clicks'):
		print("clicks 액션 발생! on_mouse: ", on_mouse)
	
	if on_mouse:
		pass
	if Input.is_action_just_released('clicks') and on_mouse:
		print("✅ 아이템 슬롯 클릭 감지! slot_no: ", slot_no, ", thing: ", thing)
		
		# Shift + 좌클릭: 아이템 절반 나누기
		if shift_hold and thing and is_thing == thins["nothing"]:
			handle_split_item()
			return
		
		if is_thing == thins["hand"]:
			if InventoryManeger.now_hand and InventoryManeger.now_hand.can_hand:
				if thing:
					var a = thing
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = a
				else:
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = null
			else:
				InventoryManeger.now_hand = thing
				thing = null
			# 손 장비 슬롯 업데이트
			InventoryManeger.equipped_hand = thing
			InventoryManeger.change_hand_equipment.emit(thing)
			get_parent().get_parent().get_parent().get_parent().anime_update(thing)
		elif is_thing == thins["head"]:
			if InventoryManeger.now_hand and InventoryManeger.now_hand.wear == InventoryManeger.now_hand.wears_op["head"]:
				if thing:
					var a = thing
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = a
				else:
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = null
			else:
				InventoryManeger.now_hand = thing
				thing = null
			# 머리 장비 슬롯 업데이트
			InventoryManeger.equipped_head = thing
			InventoryManeger.change_head_equipment.emit(thing)
			get_parent().get_parent().get_parent().get_parent().anime_update('head',thing)
		elif is_thing == thins["body"]:
			if InventoryManeger.now_hand and InventoryManeger.now_hand.wear == InventoryManeger.now_hand.wears_op["body"]:
				if thing:
					var a = thing
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = a
				else:
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = null
			else:
				InventoryManeger.now_hand = thing
				thing = null
			# 몸통 장비 슬롯 업데이트
			InventoryManeger.equipped_body = thing
			InventoryManeger.change_body_equipment.emit(thing)
			get_parent().get_parent().get_parent().get_parent().anime_update('body',thing)
		else:
			if thing:
				if InventoryManeger.now_hand:
					if InventoryManeger.now_hand.name == thing.name:
						if InventoryManeger.now_hand.count + thing.count > thing.max_count:
							var a = thing.count
							thing.count = thing.max_count
							InventoryManeger.now_hand.count = (a+InventoryManeger.now_hand.count) - thing.max_count
							update_count_display()
							InventoryManeger.change_now_hand.emit(InventoryManeger.now_hand)
						else:
							thing.count += InventoryManeger.now_hand.count
							update_count_display()
							InventoryManeger.now_hand = null
							InventoryManeger.change_now_hand.emit(InventoryManeger.now_hand)
					else:
						var a = thing
						thing = InventoryManeger.now_hand
						InventoryManeger.now_hand = a
				else:
					InventoryManeger.now_hand = thing
					thing = null
			else:
				if InventoryManeger.now_hand:
					thing = InventoryManeger.now_hand
					InventoryManeger.now_hand = null
		if thing:
			update_count_display()
		else:
			count_.text = ''
			percent.text = ''
	if Input.is_action_just_pressed('shift'):
		shift_hold = true
	if Input.is_action_just_released('shift'):
		shift_hold = false
	
	# 우클릭 처리
	if Input.is_action_just_pressed('r_click') and on_mouse:
		if shift_hold:
			# Shift + 우클릭: 아이템 버리기
			if thing:
				get_parent().get_parent().drop(thing)
				thing = null
		else:
			# 일반 우클릭: 숫자 키와 동일한 효과 (hand 슬롯으로 장착)
			handle_right_click_equip()
			
	


## Shift + 좌클릭으로 아이템을 절반씩 나누는 함수
func handle_split_item():
	# 슬롯이 비어있으면 리턴
	if not thing:
		print("빈 슬롯입니다")
		return
	
	# 손에 이미 아이템이 있으면 리턴
	if InventoryManeger.now_hand:
		print("손에 이미 아이템이 있어서 나눌 수 없습니다")
		return
	
	# 개수가 1개면 그냥 전체를 손으로 가져가기
	if thing.count <= 1:
		InventoryManeger.now_hand = thing
		thing = null
		count_.text = ''
		print("아이템 개수가 1개라서 전체를 손으로 가져갔습니다")
		return
	
	# 절반 계산 (올림 처리: 홀수일 때 손에 더 많이 가도록)
	var half_count = int(ceil(thing.count / 2.0))
	var remaining_count = thing.count - half_count
	
	# 손으로 가져갈 아이템 생성 (duplicate로 복사)
	var split_item = thing.duplicate()
	split_item.count = half_count
	
	# 슬롯에 남은 아이템 개수 업데이트
	thing.count = remaining_count
	update_count_display()
	
	# 손에 절반 배치
	InventoryManeger.now_hand = split_item
	
	print("아이템 나누기 완료: 손 ", half_count, "개 / 슬롯 ", remaining_count, "개")

## 아이템을 먹는 함수
func eat_item():
	if not thing or not thing.eatable:
		return
	
	print("🍎 [먹기] ", thing.name, " 먹는 중...")
	print("  [디버그] eat_up 배열: ", thing.eat_up)
	print("  [디버그] 먹기 전 - HP: ", InventoryManeger.player_hp, " | 허기: ", InventoryManeger.player_hunger, " | 스태미나: ", InventoryManeger.stamina)
	
	# eat_up 배열이 있고 크기가 3이면 회복 적용
	if thing.eat_up and thing.eat_up.size() >= 3:
		# HP 회복
		if thing.eat_up[0] != 0:
			InventoryManeger.player_hp += thing.eat_up[0]
			print("  ❤️ HP +", thing.eat_up[0], " (현재: ", InventoryManeger.player_hp, ")")
		
		# 허기 회복
		if thing.eat_up[1] != 0:
			InventoryManeger.player_hunger += thing.eat_up[1]
			print("  🍖 허기 +", thing.eat_up[1], " (현재: ", InventoryManeger.player_hunger, ")")
		
		# 스태미나 회복
		if thing.eat_up[2] != 0:
			InventoryManeger.stamina += thing.eat_up[2]
			print("  ⚡ 스태미나 +", thing.eat_up[2], " (현재: ", InventoryManeger.stamina, ")")
	
	print("  [디버그] 먹은 후 - HP: ", InventoryManeger.player_hp, " | 허기: ", InventoryManeger.player_hunger, " | 스태미나: ", InventoryManeger.stamina)
	
	# 아이템 개수 감소
	thing.count -= 1
	
	# 개수가 0이 되면 슬롯 비우기
	if thing.count <= 0:
		thing = null
		count_.text = ''
		percent.text = ''
		print("  아이템을 모두 먹었습니다")
	else:
		update_count_display()
		print("  남은 개수: ", thing.count)


## 우클릭으로 hand 슬롯에 장착하는 함수 (숫자 키와 동일한 효과)
func handle_right_click_equip():
	# hand 장비 슬롯을 우클릭한 경우 - 장착 해제
	if is_thing == thins["hand"]:
		unequip_hand_to_inventory()
		return
	
	# head, body 슬롯은 우클릭 불가
	if is_thing != thins["nothing"]:
		print("장비 슬롯은 우클릭으로 장착할 수 없습니다")
		return
	
	# 슬롯이 비어있으면 리턴
	if not thing:
		print("빈 슬롯입니다")
		return
	
	# eatable 아이템이면 먹기
	if thing.eatable:
		eat_item()
		return
	
	# can_hand가 아닌 아이템은 장착 불가
	if not thing.can_hand:
		print("이 아이템은 손에 들 수 없습니다: ", thing.name)
		return
	
	# hand 장비 슬롯 가져오기
	var hand_slot = InventoryManeger.hand
	if not hand_slot:
		print("hand 슬롯을 찾을 수 없습니다")
		return
	
	# 장착할 아이템 저장
	var item_to_equip = thing
	
	# 현재 hand 슬롯에 무기가 있는지 확인
	if hand_slot.thing:
		# 기존 무기를 이 슬롯으로 이동 (스왑)
		var old_weapon = hand_slot.thing
		thing = old_weapon
		update_display()
		print("기존 무기를 ", slot_no + 1, "번 슬롯으로 이동: ", old_weapon.name)
	else:
		# hand 슬롯이 비어있으면 이 슬롯만 비우기
		thing = null
		update_display()
	
	# 새 무기를 hand 슬롯에 장착
	hand_slot.thing = item_to_equip
	hand_slot.update_display()
	
	# 손 장비 업데이트
	InventoryManeger.equipped_hand = item_to_equip
	InventoryManeger.change_hand_equipment.emit(item_to_equip)
	
	# 애니메이션 업데이트
	get_parent().get_parent().get_parent().get_parent().anime_update(item_to_equip)
	
	print("우클릭으로 무기 장착 완료: ", item_to_equip.name, " (hand 슬롯)")


## hand 슬롯의 무기를 인벤토리의 빈 슬롯으로 이동 (장착 해제)
func unequip_hand_to_inventory():
	# hand 슬롯이 비어있으면 리턴
	if not thing:
		print("hand 슬롯이 비어있습니다")
		return
	
	# 장착 해제할 무기 저장
	var weapon_to_unequip = thing
	
	# 인벤토리 UI 찾기
	var inventory_ui = get_parent().get_parent()
	if not inventory_ui:
		print("인벤토리 UI를 찾을 수 없습니다")
		return
	
	var texture_rect = inventory_ui.get_node_or_null("TextureRect2")
	if not texture_rect:
		print("TextureRect2를 찾을 수 없습니다")
		return
	
	var slots = texture_rect.get_children()
	
	# 인벤토리를 처음부터 훑어서 빈 슬롯 찾기
	var empty_slot = null
	for slot in slots:
		if not slot.thing:
			empty_slot = slot
			break
	
	# 빈 슬롯이 없으면 리턴
	if not empty_slot:
		print("인벤토리에 빈 슬롯이 없습니다")
		return
	
	# 무기를 빈 슬롯에 배치
	empty_slot.thing = weapon_to_unequip
	empty_slot.update_display()
	
	# hand 슬롯 비우기
	thing = null
	update_display()
	
	# 손 장비 업데이트
	InventoryManeger.equipped_hand = null
	InventoryManeger.change_hand_equipment.emit(null)
	
	# 애니메이션 업데이트 (맨손)
	get_parent().get_parent().get_parent().get_parent().anime_update(null)
	
	print("무기 장착 해제: ", weapon_to_unequip.name, " → ", empty_slot.slot_no + 1, "번 슬롯")


func _on_area_2d_mouse_entered():
	on_mouse = true


func _on_area_2d_mouse_exited():
	on_mouse = false
