extends Control

@onready var equip_slot = $equip_slot
@onready var equip_slot_2 = $equip_slot2

@onready var inv : Inv = preload("res://items/player_inv.tres")
@onready var sprite_2d = $Sprite2D
var times = 0
@onready var slots : Array = $NinePatchRect/GridContainer.get_children()
var on_hand = false
var is_open = false
var hand_in = null
var was_in = 0
func _ready():
	Charater.ui = self
	inv.update.connect(update_slots)
	close()
	
	# 시작할 때 장비 슬롯 확인
	if equip_slot.item:  # 1번 슬롯에 아이템이 있으면
		Charater.current_slot = 1
		print("시작 시 장착된 슬롯: 1")
		if "name_i" in equip_slot.item:
			Charater.equipped_weapon = equip_slot.item.name_i
			Charater.equip_on(equip_slot.item.name_i)
			Charater.swap()  # 즉시 무기 메시 생성
		elif equip_slot.item.type == 1:
			Charater.can_eat = true
	elif equip_slot_2.item:  # 2번 슬롯에 아이템이 있으면
		Charater.current_slot = 2
		print("시작 시 장착된 슬롯: 2")
		if "name_i" in equip_slot_2.item:
			Charater.equipped_weapon = equip_slot_2.item.name_i
			Charater.equip_on(equip_slot_2.item.name_i)
			Charater.swap()  # 즉시 무기 메시 생성
	else:  # 둘 다 비어있으면
		Charater.current_slot = 0
		print("시작 시 장착된 슬롯: 없음")
		Charater.equipped_weapon = ""
		Charater.equip_on("none")
	
func _process(delta):
	sprite_2d.global_position = get_global_mouse_position()
	update_slots()
	if Input.is_action_just_pressed("tab"):
		if is_open:
			close()
		else:
			open()
	
func open():
	visible = true
	is_open = true
	
func close():
	visible = false
	is_open = false


func update_slots():
	
	for i in range(min(inv.slots.size(),slots.size())):
		slots[i].update(inv.slots[i])

func _input(event):
	if visible:
		if Input.is_action_just_pressed("click"):
			# 인벤토리 슬롯에서 아이템 집기
			for s in slots:
				if s.on:
					if s.item_display.texture:
						on_hand = true
						sprite_2d.texture = s.item_display.texture
						hand_in = inv.slots[times].item
						s.item_display.texture = null
						inv.slots[times].item = null
						was_in = times
				times += 1
			
			# 장비 슬롯에서 아이템 집기
			if equip_slot.on and equip_slot.item_display.texture:
				on_hand = true
				sprite_2d.texture = equip_slot.item_display.texture
				hand_in = equip_slot.item
				equip_slot.item_display.texture = null
				equip_slot.item = null
				
				# 1번 슬롯에서 아이템을 집었을 때
				if Charater.current_slot == 1:
					if not Charater.is_eating:
						# 2번 슬롯에 아이템이 있으면 2번으로 전환
						if equip_slot_2.item:
							Charater.current_slot = 2
							print("현재 장착된 슬롯: 2")
							if equip_slot_2.item.type == 1:  # 먹기 타입 아이템
								Charater.equipped_weapon = equip_slot_2.item.name_i
								Charater.equip_on("none")
								Charater.can_eat = true
								Charater.swap()
							else:  # 무기 타입
								Charater.equipped_weapon = equip_slot_2.item.name_i
								Charater.equip_on(equip_slot_2.item.name_i)
								Charater.can_eat = false
								Charater.swap()
						else:
							# 둘 다 비어있으면 주먹으로
							Charater.current_slot = 0
							print("현재 장착된 슬롯: 없음")
							Charater.equipped_weapon = ""
							Charater.equip_on("none")
							Charater.can_eat = false
							Charater.swap()
					
			if equip_slot_2.on and equip_slot_2.item_display.texture:
				on_hand = true
				sprite_2d.texture = equip_slot_2.item_display.texture
				hand_in = equip_slot_2.item
				equip_slot_2.item_display.texture = null
				equip_slot_2.item = null
				
				# 2번 슬롯에서 아이템을 집었을 때
				if Charater.current_slot == 2:
					if not Charater.is_eating:
						# 1번 슬롯에 아이템이 있으면 1번으로 전환
						if equip_slot.item:
							Charater.current_slot = 1
							print("현재 장착된 슬롯: 1")
							if "name_i" in equip_slot.item:
								Charater.equipped_weapon = equip_slot.item.name_i
								Charater.equip_on(equip_slot.item.name_i)
								Charater.can_eat = false
								Charater.swap()
							elif equip_slot.item.type == 1:  # 먹기 타입 아이템
								Charater.equipped_weapon = ""
								Charater.equip_on("none")
								Charater.can_eat = true
								Charater.swap()
						else:
							# 둘 다 비어있으면 주먹으로
							Charater.current_slot = 0
							print("현재 장착된 슬롯: 없음")
							Charater.equipped_weapon = ""
							Charater.equip_on("none")
							Charater.can_eat = false
							Charater.swap()
						
			times = 0
					
		if Input.is_action_just_released("click"):
			if sprite_2d.texture != null:
				var placed = false
				var current_slot = 0
				
				# 인벤토리 슬롯에 놓기
				for s in slots:
					if s.on:
						if s.item_display.texture == null:
							on_hand = false
							s.item_display.texture = sprite_2d.texture
							inv.slots[current_slot].item = hand_in
							sprite_2d.texture = null
							hand_in = null
							placed = true
							break
					current_slot += 1
				
				# 장비 슬롯에 놓기
				if equip_slot.on and !placed:
					if hand_in.type == 0 or hand_in.type == 1:
						on_hand = false
						equip_slot.item_display.texture = sprite_2d.texture
						equip_slot.item = hand_in
						sprite_2d.texture = null
						hand_in = null
						placed = true
						
				if equip_slot_2.on and !placed:
					if hand_in.type == 0:
						on_hand = false
						equip_slot_2.item_display.texture = sprite_2d.texture
						equip_slot_2.item = hand_in
						sprite_2d.texture = null
						hand_in = null
						placed = true

				# 아이템을 집었을 때 자동 슬롯 전환
				if equip_slot.on and equip_slot.item_display.texture == null:
					if equip_slot_2.item:  # 2번 슬롯에 아이템이 있으면
						Charater.current_slot = 2
						print("현재 장착된 슬롯: 2")
						if "name_i" in equip_slot_2.item:
							Charater.equipped_weapon = equip_slot_2.item.name_i
							Charater.equip_on(equip_slot_2.item.name_i)
					else:  # 둘 다 비어있으면
						Charater.current_slot = 0
						print("현재 장착된 슬롯: 없음")
						Charater.equipped_weapon = ""
						Charater.equip_on("none")
						Charater.swap()
					
				if equip_slot_2.on and equip_slot_2.item_display.texture == null:
					if equip_slot.item:  # 1번 슬롯에 아이템이 있으면
						Charater.current_slot = 1
						print("현재 장착된 슬롯: 1")
						if "name_i" in equip_slot.item:
							Charater.equipped_weapon = equip_slot.item.name_i
							Charater.equip_on(equip_slot.item.name_i)
					else:  # 둘 다 비어있으면
						Charater.current_slot = 0
						print("현재 장착된 슬롯: 없음")
						Charater.equipped_weapon = ""
						Charater.equip_on("none")
						Charater.swap()
					
				# 아이템을 놓을 수 없는 경우 원래 위치로 되돌리기
				if !placed and sprite_2d.texture != null:
					if was_in >= 0:  # 인벤토리에서 왔다면
						inv.slots[was_in].item = hand_in
					else:  # 장비 슬롯에서 왔다면
						equip_slot.item_display.texture = sprite_2d.texture
						equip_slot.item = hand_in
					sprite_2d.texture = null
					hand_in = null
					on_hand = false
					
	if Input.is_action_just_pressed("1"):  # 1번 무기 선택
		if equip_slot.item:  # 1번에 아이템이 있으면
			Charater.current_slot = 1
			print("현재 장착된 슬롯: 1")
			if equip_slot.item.type == 1:  # 먹기 타입 아이템
				Charater.equipped_weapon = equip_slot.item.name_i  # 메시를 위해 name_i 설정
				Charater.equip_on("none")  # 애니메이션은 none으로
				Charater.can_eat = true
				Charater.swap()  # eatable에서 메시 찾아서 장착
			else:  # 무기 타입
				Charater.equipped_weapon = equip_slot.item.name_i
				Charater.equip_on(equip_slot.item.name_i)
				Charater.can_eat = false
				Charater.swap()
		else:
			# 1번에 아이템이 없으면 무기 해제
			Charater.current_slot = 0
			print("현재 장착된 슬롯: 없음")
			Charater.equipped_weapon = ""
			Charater.equip_on("none")
			Charater.swap()  # swap() 호출 추가
				
	elif Input.is_action_just_pressed("2"):  # 2번 무기 선택
		if equip_slot_2.item:  # 2번에 아이템이 있으면
			Charater.current_slot = 2
			print("현재 장착된 슬롯: 2")
			# 2번 무기에 name_i 속성이 있는지 확인
			if "name_i" in equip_slot_2.item:
				# 2번 무기 장착
				Charater.equipped_weapon = equip_slot_2.item.name_i
				Charater.equip_on(equip_slot_2.item.name_i)
				Charater.swap()  # swap() 호출 추가
			else:
				# name_i 속성이 없으면 무기 해제
				Charater.equipped_weapon = ""
				Charater.equip_on("none")
				Charater.swap()  # swap() 호출 추가
		else:
			# 2번에 아이템이 없으면 무기 해제
			Charater.current_slot = 0
			print("현재 장착된 슬롯: 없음")
			Charater.equipped_weapon = ""
			Charater.equip_on("none")
			Charater.swap()  # swap() 호출 추가
