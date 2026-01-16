extends Node3D
class_name WeaponManager

## 무기 교체 시스템을 관리하는 클래스
## 마우스 휠과 숫자키로 무기 전환 처리

# 시그널
signal weapon_switched(slot_index: int, weapon_name: String)

# 무기 슬롯 (최대 3개)
var weapon_slots: Array[WeaponBase] = [null, null, null]
var current_slot: int = -1
var previous_slot: int = -1

# 무기 교체 중 플래그
var is_switching: bool = false
var switch_duration: float = 0.3  # 무기 교체 시간

# 플레이어 참조
var player: PlayerController

func _ready():
	# 플레이어 참조 획득
	var node = get_parent()
	while node:
		if node is PlayerController:
			player = node
			break
		node = node.get_parent()

func _input(event):
	# 멀티플레이어: 로컬 플레이어만 입력 처리
	if multiplayer.get_peers().size() > 0:
		if not player or not player.is_multiplayer_authority():
			return
	
	if is_switching:
		return
	
	# 숫자키로 직접 슬롯 선택
	if event.is_action_pressed("weapon_slot_1"):
		switch_to_slot(0)
	elif event.is_action_pressed("weapon_slot_2"):
		switch_to_slot(1)
	elif event.is_action_pressed("weapon_slot_3"):
		switch_to_slot(2)
	
	# 마우스 휠로 순환
	elif event.is_action_pressed("weapon_next"):
		switch_to_next_weapon()
	elif event.is_action_pressed("weapon_previous"):
		switch_to_previous_weapon()

func _process(_delta):
	# 멀티플레이어: 로컬 플레이어만 입력 처리
	if multiplayer.get_peers().size() > 0:
		if not player or not player.is_multiplayer_authority():
			return
	
	if current_slot < 0 or current_slot >= weapon_slots.size():
		return
	
	var current_weapon = weapon_slots[current_slot]
	if not current_weapon or is_switching:
		return
	
	# 발사 입력 처리
	if Input.is_action_pressed("fire"):
		current_weapon.fire()
	else:
		current_weapon.stop_fire()
	
	# 재장전 입력 처리
	if Input.is_action_just_pressed("reload"):
		current_weapon.reload()
	
	# 조준 입력 처리
	if Input.is_action_pressed("aim"):
		if not current_weapon.is_aiming:
			current_weapon.start_aim()
	else:
		if current_weapon.is_aiming:
			current_weapon.stop_aim()

# 무기를 슬롯에 추가
# weapon: 추가할 무기
# slot_index: 슬롯 인덱스 (0-2)
func add_weapon(weapon: WeaponBase, slot_index: int):
	if slot_index < 0 or slot_index >= weapon_slots.size():
		return
	
	# 기존 무기가 있으면 제거
	if weapon_slots[slot_index]:
		weapon_slots[slot_index].queue_free()
	
	# 무기 추가
	add_child(weapon)
	weapon_slots[slot_index] = weapon
	weapon.unequip()
	
	# 첫 무기면 자동 장착
	if current_slot < 0:
		switch_to_slot(slot_index)

# 특정 슬롯으로 전환
# slot_index: 슬롯 인덱스
func switch_to_slot(slot_index: int):
	if slot_index < 0 or slot_index >= weapon_slots.size():
		return
	
	if not weapon_slots[slot_index]:
		return
	
	if slot_index == current_slot:
		return
	
	_perform_weapon_switch(slot_index)

# 다음 무기로 전환 (순환)
func switch_to_next_weapon():
	var next_slot = (current_slot + 1) % weapon_slots.size()
	var attempts = 0
	
	# 다음 무기가 있을 때까지 순환
	while not weapon_slots[next_slot] and attempts < weapon_slots.size():
		next_slot = (next_slot + 1) % weapon_slots.size()
		attempts += 1
	
	if weapon_slots[next_slot]:
		_perform_weapon_switch(next_slot)

# 이전 무기로 전환 (순환)
func switch_to_previous_weapon():
	var prev_slot = (current_slot - 1) if current_slot > 0 else weapon_slots.size() - 1
	var attempts = 0
	
	# 이전 무기가 있을 때까지 순환
	while not weapon_slots[prev_slot] and attempts < weapon_slots.size():
		prev_slot = (prev_slot - 1) if prev_slot > 0 else weapon_slots.size() - 1
		attempts += 1
	
	if weapon_slots[prev_slot]:
		_perform_weapon_switch(prev_slot)

# 실제 무기 교체 처리 (내부 함수)
# new_slot: 새 슬롯 인덱스
func _perform_weapon_switch(new_slot: int):
	is_switching = true
	
	# 현재 무기 해제
	if current_slot >= 0 and weapon_slots[current_slot]:
		weapon_slots[current_slot].unequip()
	
	previous_slot = current_slot
	current_slot = new_slot
	
	# 무기 교체 딜레이 (첫 무기는 딜레이 없음)
	if previous_slot >= 0:
		await get_tree().create_timer(switch_duration).timeout
	
	# 새 무기 장착
	var new_weapon = weapon_slots[current_slot]
	if new_weapon:
		new_weapon.equip()
		weapon_switched.emit(current_slot, new_weapon.weapon_data.weapon_name if new_weapon.weapon_data else "무기")
	
	is_switching = false

# 현재 무기 가져오기
func get_current_weapon() -> WeaponBase:
	if current_slot >= 0 and current_slot < weapon_slots.size():
		return weapon_slots[current_slot]
	return null

# 마지막으로 사용한 무기로 전환 (Q키용, 나중에 구현 가능)
func switch_to_last_weapon():
	if previous_slot >= 0 and weapon_slots[previous_slot]:
		_perform_weapon_switch(previous_slot)

