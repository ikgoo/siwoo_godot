extends Node2D
@onready var gpu_particles_2d = $GPUParticles2D
@onready var animation_player = $AnimationPlayer
@onready var lifetime_timer = Timer.new()  # 새로운 타이머 추가
@onready var audio_stream_player_2d = $AudioStreamPlayer2D

signal star_clicked
var get_s = 0
var target_position = Vector2.ZERO
var speed = 400
var is_flying = true  # 항상 날아가도록 변경
var velocity = Vector2.ZERO  # 이동 방향과 속도

# 카메라 최대 이동 범위 (camera_2d.gd와 동일하게 설정)
const CAMERA_BOUNDS_MIN = Vector2(-3000, -2000)
const CAMERA_BOUNDS_MAX = Vector2(3000, 2000)
const LIFETIME = 30.0  # 별의 수명 30초

func _ready():
	# 타이머 설정
	add_child(lifetime_timer)
	lifetime_timer.wait_time = LIFETIME
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(on_lifetime_end)
	lifetime_timer.start()
	
	target_position = position
	position = get_parent().position
	animation_player.play("fly")
	
	# 초기 이동 방향 설정
	velocity = (target_position - position).normalized() * speed
	
	# Gamemaneger의 stars 배열에 추가
	Gamemaneger.add_star(self)

func _process(delta):
	if is_flying:
		position += velocity * delta
		
		# 카메라 최대 범위를 벗어나면 튕기기
		if position.x < CAMERA_BOUNDS_MIN.x or position.x > CAMERA_BOUNDS_MAX.x:
			velocity.x = -velocity.x
			gpu_particles_2d.look_at(position + velocity)
		
		if position.y < CAMERA_BOUNDS_MIN.y or position.y > CAMERA_BOUNDS_MAX.y:
			velocity.y = -velocity.y
			gpu_particles_2d.look_at(position + velocity)

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var distance = get_local_mouse_position().length()
		if distance < 10 and is_flying:  # is_flying 상태일 때만 클릭 가능
			collect()

func collect():
	
	if not is_flying:  # 이미 수집된 상태면 무시
		return
	audio_stream_player_2d.play()
	is_flying = false  # 움직임 중단
	velocity = Vector2.ZERO  # 속도도 0으로
	gpu_particles_2d.emitting = false  # 파티클 효과 즉시 중단
	$AnimationPlayer.play("new_animation")
	Gamemaneger.stardust += get_s
	emit_signal("star_clicked")
	Gamemaneger.remove_star(self)  # stars 배열에서 제거

func get_stard():
	Gamemaneger.stardust += get_s

# 수명이 다했을 때 호출되는 함수
func on_lifetime_end():
	if is_flying:  # 아직 수집되지 않은 경우에만
		gpu_particles_2d.emitting = false
		Gamemaneger.remove_star(self)
		queue_free()
