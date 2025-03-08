extends CharacterBody3D
@onready var timer = $Timer

const SPEED = 1.0
const SPRINT_SPEED = 2.0  # 달리기 속도
const JUMP_VELOCITY = 3
const MOUSE_SENSITIVITY = 0.002
@onready var animation_player = $AnimationPlayer
var damage = 10
@onready var stamina_timer = $stamina_timer
var got_item = null
# 스테미나 관련 변수
var max_stamina = 100.0
var current_stamina = 100.0
var stamina_regen = 10.0  # 초당 회복량
var stamina_drain = 20.0  # 초당 소모량
var is_sprinting = false
var can_sprint = true
@export var inv : Inv
@onready var ray_cast_3d = $RayCast3D
@onready var camera = $Camera3D
var mouse_captured = true
var area_get = null
var attack_ok = true
var is_resting = true
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ray_cast_3d.target_position = Vector3(0, 0, -0.5)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 스테미나 처리
	handle_stamina(delta)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("a", "d", "w", "s")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 달리기 처리
	is_sprinting = Input.is_action_pressed("sprint") and can_sprint and (input_dir.x != 0 or input_dir.y != 0)  # w키를 누르고 있을 때만 달리기
	var current_speed = SPRINT_SPEED if is_sprinting else SPEED
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

	# 레이캐스트를 카메라 방향으로 회전
	ray_cast_3d.global_rotation = camera.global_rotation

	# 레이캐스트 충돌 체크
	if ray_cast_3d.is_colliding():
		var collider = ray_cast_3d.get_collider()
		area_get = collider
	else:
		area_get = null

	# 클릭 감지 및 Area 출력
	if area_get:
		var clayer_bit = 3
		var cis_layer_4 = area_get.collision_layer & (1 << clayer_bit)
		print(area_get.collision_layer)
		if cis_layer_4:
			print(area_get.get_parent().mesh_instance)
			area_get.get_parent().mesh_instance.mesh.material.albedo_color =  Color(1, 0, 0)
			got_item = area_get.get_parent()

	#elif got_item:
		#if not got_item == null:
			#got_item.mesh_instance.mesh.albedo_color=  Color(1,1,1, 1)
			#got_item = null
	
		
	if Input.is_action_just_pressed("click"):
		print("감지된 Area: ", area_get)
		animation_player.play("ppuk")
		if attack_ok:
			timer.start()
			if area_get:
				var layer_bit = 0
				var is_layer_4 = area_get.collision_mask & (1 << layer_bit)
				print(is_layer_4)
				if is_layer_4:
					
					print(area_get.name)
					area_get.get_parent().hp_out(damage)
				else:
					collect(area_get.get_parent().item)
					
		attack_ok = false

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
	if event.is_action_pressed("ui_cancel"):
		mouse_captured = !mouse_captured
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if mouse_captured else Input.MOUSE_MODE_VISIBLE
	
	if mouse_captured and event is InputEventMouseMotion:
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
