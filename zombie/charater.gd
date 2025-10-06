extends CharacterBody3D
@onready var timer = $Timer

const SPEED = 5.0
const SPRINT_SPEED = 10.0  # 달리기 속도
const JUMP_VELOCITY = 15
const MOUSE_SENSITIVITY = 0.002
@onready var animation_player = $AnimationPlayer
var damage = 10
@onready var stamina_timer = $stamina_timer
var got_item = null
# 스테미나 관련 변수
var weopons = {
	"pole" : preload("res://items/weopon/pole.tscn")
}

var eatable = {
	"h_t_m" : preload("res://items/weopon/h_t_m.tscn")
}
@onready var marker_3d = $Camera3D/Node3D/Hand/Marker3D
var ui = null
var max_stamina = 100.0
var current_stamina = 100.0
var stamina_regen = 10.0  # 초당 회복량
var stamina_drain = 20.0  # 초당 소모량
var is_sprinting = false
var can_sprint = true
@export var inv : Inv
@onready var camera = $Camera3D
var mouse_captured = true
var area_get = null
var attack_ok = true
var is_resting = true
var inventory_open = false
@onready var ray_cast_3d = $Camera3D/RayCast3D
var can_eat = false  # 먹기 가능 여부
var is_eating = false  # 현재 먹는 중인지 상태
var equipped_weapon = ""  # 장착된 무기 이름 저장 변수
var current_slot = 0  # 현재 들고 있는 슬롯 번호 (0: 없음, 1: 첫 번째 슬롯, 2: 두 번째 슬롯)
var current_hunger = 50  # 현재 허기

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

	if not inventory_open:
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		handle_stamina(delta)

		var input_dir = Input.get_vector("a", "d", "w", "s")
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
		is_sprinting = Input.is_action_pressed("sprint") and can_sprint and (input_dir.x != 0 or input_dir.y != 0)
		var current_speed = SPRINT_SPEED if is_sprinting else SPEED
		
		if direction:
			velocity.x = direction.x * current_speed
			velocity.z = direction.z * current_speed
		else:
			velocity.x = move_toward(velocity.x, 0, current_speed)
			velocity.z = move_toward(velocity.z, 0, current_speed)
	else:
		velocity.x = 0
		velocity.z = 0
	
	move_and_slide()

	ray_cast_3d.global_rotation = camera.global_rotation

	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		area_get = collider
	else:
		area_get = null

	# 클릭 감지 및 Area 출력
	if area_get:
		var clayer_bit = 3
		var cis_layer_4 = area_get.collision_layer & (1 << clayer_bit)
		if cis_layer_4:
			area_get.get_parent().mesh_instance.mesh.material.albedo_color = Color(1, 0, 0)
			got_item = area_get.get_parent()

	elif got_item:
		if not got_item == null:
			got_item.mesh_instance.mesh.material.albedo_color = Color(1, 1, 1)
			got_item = null
	else:
		var d = ray_cast_3d.get_collider()
		if d:
			if d.get_parent().thing == "op":
				if not d.get_parent().op:
					d.get_parent().animation_player.play("open")
				elif d.get_parent().op:
					d.get_parent().animation_player.play("close")

func handle_stamina(delta):
	if is_sprinting and current_stamina > 0:
		is_resting = false
		stamina_timer.start()
		current_stamina = max(0, current_stamina - stamina_drain * delta)
		if current_stamina == 0:
			can_sprint = false
	elif not is_sprinting:
		if is_resting:
			current_stamina = min(max_stamina, current_stamina + stamina_regen * delta)
		if current_stamina > 20:  # 스테미나가 20% 이상 회복되면 다시 달리기 가능
			can_sprint = true

func _unhandled_input(event):
	# ESC로 마우스 모드 전환
	if event.is_action_pressed("ui_cancel"):
		mouse_captured = !mouse_captured
		if !mouse_captured or inventory_open:  # ESC로 해제하거나 인벤토리가 열려있으면
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 인벤토리 열기/닫기
	if event.is_action_pressed("tab"):
		inventory_open = !inventory_open
		if inventory_open or !mouse_captured:  # 인벤토리가 열려있거나 마우스가 해제되어 있으면
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# 마우스가 캡처되어 있고 인벤토리가 닫혀있을 때만 시점 회전
	if mouse_captured and !inventory_open and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
	if event.is_action_pressed("f"):
		if got_item:
			if got_item != null:
				collect(got_item.item)
				got_item.queue_free()
				got_item = null

func _on_timer_timeout():
	attack_ok = true

func _on_stamina_timer_timeout():
	is_resting = true

func player():
	pass
	
func collect(item:Inven_Item):
	inv.insert(item)

# 무기 이름을 사용하는 예시
func _process(delta):

	if equipped_weapon != "":
		print("현재 장착된 무기: ", equipped_weapon)

func equip_on(thing):
	# 스왑 애니메이션만 실행하고, 
	# 스왑 애니메이션 안에서 swap() 함수를 호출하도록 함
	animation_player.play("swap")

func swap():
	if equipped_weapon != '':
		# 기존 무기/아이템 제거
		if marker_3d.get_child(0):
			marker_3d.get_child(0).queue_free()
			
		# 새 무기/아이템 장착
		if weopons.has(equipped_weapon):  # 무기인 경우
			var weo = weopons[equipped_weapon].instantiate()
			marker_3d.add_child(weo)
		elif eatable.has(equipped_weapon):  # 먹을 수 있는 아이템인 경우
			var eat = eatable[equipped_weapon].instantiate()
			marker_3d.add_child(eat)
	else:
		# 무기/아이템 없는 상태로 전환
		if marker_3d.get_child(0):
			marker_3d.get_child(0).queue_free()

func _input(event):
	# 먹기 동작 시작
	if Input.is_action_just_pressed("click") and !is_eating and !animation_player.is_playing():
		if current_slot != 0:  # 슬롯이 선택되어 있을 때
			if ui.equip_slot.item and current_slot == 1:  # 1번 슬롯
				if ui.equip_slot.item.type == 1 and can_eat:  # 먹기 타입이고 can_eat이 true일 때
					animation_player.play("eating")
					is_eating = true
				else:  # 공격 타입
					animation_player.play("ppuk")
					if area_get:
						var layer_bit = 0
						var is_layer_4 = area_get.collision_mask & (1 << layer_bit)
						if is_layer_4:
							# 아이템의 value를 데미지로 사용
							var attack_damage = ui.equip_slot.item.value if ui.equip_slot.item else damage
							area_get.get_parent().hp_out(attack_damage)
						else:
							collect(area_get.get_parent().item)
			elif ui.equip_slot_2.item and current_slot == 2:  # 2번 슬롯도 같은 방식으로
				if ui.equip_slot_2.item.type == 1 and can_eat:
					animation_player.play("eating")
					is_eating = true
				else:
					animation_player.play("ppuk")
					if area_get:
						var layer_bit = 0
						var is_layer_4 = area_get.collision_mask & (1 << layer_bit)
						if is_layer_4:
							# 아이템의 value를 데미지로 사용
							var attack_damage = ui.equip_slot_2.item.value if ui.equip_slot_2.item else damage
							area_get.get_parent().hp_out(attack_damage)
						else:
							collect(area_get.get_parent().item)
		else:  # 슬롯이 선택되어 있지 않을 때 (주먹)
			animation_player.play("ppuk")
			if area_get:
				var layer_bit = 0
				var is_layer_0 = area_get.collision_layer & (1 << layer_bit)  # 실제로는 0번 레이어 확인
				if is_layer_0:
					# 아이템의 value를 데미지로 사용
					var attack_damage = ui.equip_slot.item.value if ui.equip_slot.item else damage
					area_get.get_parent().hp_out(attack_damage)
				elif area_get.collision_layer & (1 << 4):  # 4번 레이어이면
					collect(area_get.get_parent().item)
				elif area_get.collision_layer & (1 << 6):
					pass
		attack_ok = false
		timer.start()
	if Input.is_action_just_pressed("f") and !is_eating:
			if area_get:
				print(area_get.collision_layer,(1 << 5))
				if area_get.collision_layer & (1 << 5):
					area_get.get_parent().get_parent().op_cl(area_get)

func eaten():
	is_eating = false
	
	var ui = get_tree().get_root().get_node("main/CanvasLayer/ui/inv_ui")
	
	# 현재 선택된 슬롯에 따라 아이템 제거
	if current_slot == 1:  # 1번 슬롯이 선택되어 있을 때
		# 허기 회복
		if ui.equip_slot.item and ui.equip_slot.item.type == 1:
			current_hunger = min(100, current_hunger + ui.equip_slot.item.value)
		
		ui.equip_slot.item_display.texture = null
		ui.equip_slot.item = null
		equipped_weapon = ""
		equip_on("none")
		can_eat = false
		current_slot = 0
	elif current_slot == 2:  # 2번 슬롯이 선택되어 있을 때
		ui.equip_slot_2.item_display.texture = null
		ui.equip_slot_2.item = null
		equipped_weapon = ""
		equip_on("none")
		can_eat = false
		current_slot = 0
	
	# 아이템 효과 적용
	# 예: 체력 회복, 스태미나 회복 등
