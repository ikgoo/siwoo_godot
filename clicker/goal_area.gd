extends Node2D

# 피버 설정
@export var fever_multiplier: float = 2.0  # 피버 배율 (2.0 = 2배)
@export var fever_duration: float = 10.0  # 피버 지속 시간 (초)
@export var teleport_position: Vector2 = Vector2.ZERO  # 텔레포트 목적지 (글로벌 좌표)

# Area2D 노드 참조
@onready var area_2d = $Area2D

# 피버 타이머
var fever_timer: Timer

func _ready():
	# Area2D의 body_entered 시그널 연결
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	
	# 피버 타이머 생성
	fever_timer = Timer.new()
	fever_timer.one_shot = true
	fever_timer.timeout.connect(_on_fever_timeout)
	add_child(fever_timer)

# 캐릭터가 영역에 들어왔을 때
func _on_area_2d_body_entered(body):
	# CharacterBody2D인지 확인 (플레이어)
	if body is CharacterBody2D:
		activate_fever()
		# 텔레포트 (teleport_position이 설정되어 있으면)
		if teleport_position != Vector2.ZERO:
			teleport_character(body)

# 피버 활성화
func activate_fever():
	# 이미 피버 중이면 타이머만 리셋
	if Globals.is_fever_active:
		fever_timer.start(fever_duration)
		print("🔥 피버 시간 연장! ", fever_duration, "초")
		return
	
	# 피버 활성화
	Globals.is_fever_active = true
	Globals.fever_multiplier = fever_multiplier
	fever_timer.start(fever_duration)
	
	print("🔥🔥🔥 피버 모드 시작! ", fever_multiplier, "배 수입, ", fever_duration, "초 동안 지속")

# 캐릭터 텔레포트
func teleport_character(character):
	# 텔레포트 이펙트 (파티클)
	spawn_teleport_effect(character.global_position)
	
	# 캐릭터를 목적지로 이동
	character.global_position = teleport_position
	
	# 도착 지점에도 이펙트
	spawn_teleport_effect(teleport_position)
	
	print("🌀 텔레포트! ", teleport_position)

# 텔레포트 이펙트 생성
func spawn_teleport_effect(pos: Vector2):
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.gravity = Vector2(0, 0)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 6
	particles.color = Color(0.5, 0.8, 1.0)  # 파란색 (텔레포트)
	particles.global_position = pos
	get_tree().current_scene.add_child(particles)
	particles.emitting = true
	
	# 파티클이 끝나면 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

# 피버 종료
func _on_fever_timeout():
	Globals.is_fever_active = false
	Globals.fever_multiplier = 1.0
	print("피버 모드 종료")
