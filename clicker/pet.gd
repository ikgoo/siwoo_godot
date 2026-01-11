# ============================================
# Pet.gd - 펫 팔로우 시스템
# 시뮬레이터 설정값 적용 버전
# ============================================

extends CharacterBody2D

# === 플레이어 참조 ===
@export var player: CharacterBody2D

# === 시뮬레이터에서 설정한 값들 ===
@export var max_speed: float = 60.0
@export var steering_force: float = 1.5
@export var arrive_radius: float = 40.0
@export var stop_radius: float = 9.0
@export var bob_amplitude: float = 2.0
@export var bob_frequency: float = 2.5
@export var flip_speed: float = 14.0
@export var follow_distance: float = 45.0

# === 내부 변수 ===
var time_elapsed: float = 0.0
var current_visual_scale_x: float = 1.0

# === 노드 참조 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var follow_point: Marker2D = player.get_node("Sprite2D/FollowPoint")


func _physics_process(delta: float) -> void:
	time_elapsed += delta
	
	# 1. 타겟 위치 계산
	var target = follow_point.global_position
	var distance = global_position.distance_to(target)
	
	# 2. 스티어링 기반 이동
	var desired_velocity = Vector2.ZERO
	
	if distance > stop_radius:
		var direction = global_position.direction_to(target)
		var speed_factor = clamp(distance / arrive_radius, 0.0, 1.0)
		desired_velocity = direction * max_speed * speed_factor
	
	var steering = (desired_velocity - velocity) * steering_force * delta
	velocity += steering
	
	move_and_slide()
	
	# 3. 둥둥 효과 (Sprite에만 적용)
	var bob_offset = sin(time_elapsed * bob_frequency) * bob_amplitude
	sprite.position.y = bob_offset
	
	# 4. 부드러운 방향 전환
	var target_scale_x = 1.0 if velocity.x >= 0 else -1.0
	
	# 움직임이 있을 때만 방향 전환
	if abs(velocity.x) > 5.0:
		current_visual_scale_x = lerp(current_visual_scale_x, target_scale_x, flip_speed * delta)
	
	sprite.scale.x = current_visual_scale_x


# ============================================
# PetManager.gd - 다중 펫 관리 (선택사항)
# 펫이 여러 마리일 때 사용
# ============================================

#extends Node2D
#
#@export var player: CharacterBody2D
#@export var pet_scene: PackedScene
#@export var pet_count: int = 3
#
#var pets: Array[CharacterBody2D] = []
#
#func _ready() -> void:
#	for i in range(pet_count):
#		var pet = pet_scene.instantiate() as CharacterBody2D
#		add_child(pet)
#		
#		# 첫 번째 펫은 플레이어를, 나머지는 앞 펫을 따라감
#		if i == 0:
#			pet.player = player
#		else:
#			pet.player = pets[i - 1]
#		
#		pets.append(pet)
