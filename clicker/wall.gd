extends StaticBody2D

@export var require_tier : int  # 오타 수정: requier → require
# CollisionShape2D 노드 참조
@onready var collision_shape = $CollisionShape2D
# 애니메이션 플레이어 참조
@onready var animation_player: AnimationPlayer = $AnimationPlayer
# 스프라이트 노드 참조 (진동 효과용)
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var door_down: Sprite2D = $door_down
# 벽이 열렸는지 여부
var is_opened : bool = false

# 진동 관련 변수
var is_vibrating: bool = false  # 진동 중인지
var vibration_strength: float = 0.0  # 진동 강도
var original_door_down_position: Vector2 = Vector2.ZERO  # door_down 원래 위치

func _ready():
	# Globals의 tier_up Signal 구독 (매 프레임 체크 대신)
	Globals.tier_up.connect(_on_tier_up)
	
	# Globals의 money_changed Signal도 구독 (초기 체크용)
	Globals.money_changed.connect(_on_money_changed)
	
	# 초기 티어 체크 (다음 프레임에 실행하여 모든 노드가 준비된 후 체크)
	call_deferred("check_tier")
	
	# door_down 원래 위치 저장
	if door_down:
		original_door_down_position = door_down.position

func _process(_delta):
	# 진동 효과 업데이트
	if is_vibrating:
		update_vibration()

# 티어가 올라갔을 때 호출되는 콜백
func _on_tier_up(_new_tier: int):
	check_tier()

# 돈이 변경될 때 호출되는 콜백 (초기 체크용)
func _on_money_changed(_new_amount: int, _delta: int):
	check_tier()

func check_tier():
	# 이미 열린 벽은 다시 체크하지 않음
	if is_opened:
		return
	
	print("벽 티어 체크: require_tier=", require_tier, ", Globals.max_tier=", Globals.max_tier, ", Globals.current_tier=", Globals.current_tier)
	
	# 현재 최대 티어가 필요한 티어보다 크거나 같으면 벽 열기
	if Globals.max_tier >= require_tier:
		open_wall()

func open_wall():
	is_opened = true
	
	# UI 숨기기
	hide_ui()
	
	# 문을 중심으로 카메라를 이동 및 클로즈업
	await focus_camera_on_wall()
	
	# 진동 효과 시작
	vibration(3.0)
	await get_tree().create_timer(0.8).timeout  # 0.8초간 진동
	vib_end()
	
	# 카메라가 도착한 후 문 열기 애니메이션 실행
	if animation_player:
		animation_player.play("open")
		# 애니메이션이 끝날 때까지 대기
		await animation_player.animation_finished
	
	# 잠시 대기 (문이 완전히 열린 모습 보여주기)
	await get_tree().create_timer(1.0).timeout
	
	# 카메라 줌 아웃 및 고정 해제
	var cameras = get_tree().get_nodes_in_group("camera")
	if not cameras.is_empty():
		var cam = cameras[0]
		if cam:
			# 줌 아웃
			if cam.has_method("zoom_out"):
				cam.zoom_out(1.0)
				await cam.wait_until_zoom_reached(0.1, 2.0)
			
			# 카메라 고정 해제
			if cam.has_method("unlock_from_target"):
				cam.unlock_from_target()
	
	# UI 다시 표시
	show_ui()
	
	print("벽 열림! 티어 ", require_tier, " 필요, 현재 최대 티어: ", Globals.max_tier)

func focus_camera_on_wall():
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.is_empty():
		return
	var cam = cameras[0]
	if not cam:
		return
	
	# 카메라를 문 위치로 고정
	if cam.has_method("lock_to_target"):
		cam.lock_to_target(global_position)
	
	# 카메라가 도착할 때까지 대기
	if cam.has_method("wait_until_arrived"):
		await cam.wait_until_arrived(5.0, 5.0)
	else:
		# fallback: 단순 시간 대기
		await get_tree().create_timer(1.5).timeout
	
	# 카메라 클로즈업 (확대)
	if cam.has_method("zoom_in"):
		cam.zoom_in(Vector2(3.5, 3.5), 0.8)  # 3.5배 확대, 0.8초 동안
		await cam.wait_until_zoom_reached(0.1, 2.0)

# UI 숨기기
func hide_ui():
	var ui_nodes = get_tree().get_nodes_in_group("ui")
	for ui in ui_nodes:
		if ui is CanvasLayer or ui is Control:
			ui.visible = false

# UI 표시하기
func show_ui():
	var ui_nodes = get_tree().get_nodes_in_group("ui")
	for ui in ui_nodes:
		if ui is CanvasLayer or ui is Control:
			ui.visible = true

# === 진동 효과 함수들 ===

func vibration(strength: float = 2.0):
	if not door_down:
		return
	
	is_vibrating = true
	vibration_strength = strength
	print("벽 진동 시작! 강도: ", strength)

func vib_end():
	if not door_down:
		return
	
	is_vibrating = false
	vibration_strength = 0.0
	
	# door_down을 원래 위치로 복원
	door_down.position = original_door_down_position
	print("벽 진동 종료!")


func update_vibration():
	if not door_down or not is_vibrating:
		return
	
	# 랜덤 오프셋 생성 (-강도 ~ +강도)
	var offset = Vector2(
		randf_range(-vibration_strength, vibration_strength),
		randf_range(-vibration_strength, vibration_strength)
	)
	
	# door_down 원래 위치 + 오프셋으로 이동
	door_down.position = original_door_down_position + offset
