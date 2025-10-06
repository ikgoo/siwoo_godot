@tool
extends Control
class_name ItemSlot

var on_mouse = false
@export var slot_no: int
@onready var sprite = $TextureRect
var shift_hold = false
var following = false
var count : int = 0

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
				count_.text = str(thing.count)
		else:
			if sprite:
				sprite.texture = null
				count_.text = ''



func _ready():
	pass

func add_item(item: Item, form_slot: ItemSlot):
	thing = item

# UI 디스플레이 업데이트 함수
func update_display():
	if thing:
		if sprite:
			sprite.texture = thing.img
			count_.text = str(thing.count)
	else:
		if sprite:
			sprite.texture = null
			count_.text = ''
		

func _process(delta):
	if following:
		# 글로벌 마우스 위치를 부모 좌표계로 변환
		var global_mouse_pos = get_global_mouse_position()
		var parent_node = get_parent()
		if parent_node:
			position = parent_node.to_local(global_mouse_pos)
	
	
	if Engine.is_editor_hint():
		return # 에디터 힌트 모드일 경우, 더 이상 진행하지 않고 함수를 종료합니다.
	
	# 클릭 액션 감지 디버깅
	if Input.is_action_just_released('clicks'):
		print("clicks 액션 발생! on_mouse: ", on_mouse)
	
	if on_mouse:
		pass
	if Input.is_action_just_released('clicks') and on_mouse:
		print("✅ 아이템 슬롯 클릭 감지! slot_no: ", slot_no, ", thing: ", thing)
		
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
							count_.text = str(thing.count)	
							InventoryManeger.change_now_hand.emit(InventoryManeger.now_hand)
						else:
							thing.count += InventoryManeger.now_hand.count
							count_.text = str(thing.count)
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
			count_.text = str(thing.count)
		else:
			count_.text = ''
	if Input.is_action_just_pressed('shift'):
		shift_hold = true
	if Input.is_action_just_released('shift'):
		shift_hold = false
	if Input.is_action_just_pressed('r_click') and on_mouse and shift_hold:
		if thing:
			get_parent().get_parent().drop(thing)
			thing = null
			
	


func _on_area_2d_mouse_entered():
	on_mouse = true
	print("마우스 슬롯 진입: slot_no: ", slot_no)


func _on_area_2d_mouse_exited():
	on_mouse = false
	print("마우스 슬롯 이탈: slot_no: ", slot_no)
