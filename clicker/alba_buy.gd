extends Node2D

# 알바 씬 경로
@export var alba_scene_path : String = "res://alba.tscn"
# Area2D 노드 참조
@onready var area_2d = $Area2D
# 알바 씬을 로드한 PackedScene
var alba_scene : PackedScene
# 이미 구매했는지 여부
var is_purchased : bool = false

# 시각 효과
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready():
	# 알바 씬 로드
	alba_scene = load(alba_scene_path)
	# Area2D의 input_event 시그널 연결
	area_2d.input_event.connect(_on_area_2d_input_event)
	
	# Globals Signal 구독
	Globals.money_changed.connect(_on_money_changed)

func _process(_delta):
	# 구매 가능 여부 시각 표시
	if not is_purchased:
		update_visual_feedback()

# 구매 가능 여부 시각 표시
func update_visual_feedback():
	if not sprite:
		return
	
	# 임시로 알바 인스턴스 생성해서 가격 확인
	var alba_instance = alba_scene.instantiate()
	var price = alba_instance.price
	alba_instance.queue_free()
	
	# 구매 가능하면 밝게, 불가능하면 어둡게
	if Globals.money >= price:
		sprite.modulate = Color(1.2, 1.2, 1.2)
	else:
		sprite.modulate = Color(0.7, 0.7, 0.7)

# 돈 변경 시 호출
func _on_money_changed(_new_amount: int, _delta: int):
	update_visual_feedback()

# Area2D 입력 이벤트 처리
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# 이미 구매했으면 무시
	if is_purchased:
		return
	
	# 마우스 왼쪽 버튼 클릭 확인
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 알바 인스턴스 생성 (가격 확인을 위해 임시로 생성)
		var alba_instance = alba_scene.instantiate()
		
		# 알바의 export 변수에서 가격 가져오기
		var price = alba_instance.price
		
		# 돈이 충분한지 확인
		if Globals.money >= price:
			# 돈 차감
			Globals.money -= price
			print("돈 차감: ", price, "원, 남은 돈: ", Globals.money)
			
			# 현재 위치에 알바 배치
			alba_instance.global_position = global_position
			# 부모 노드(보통 main 씬)에 추가
			get_tree().current_scene.add_child(alba_instance)
			print("알바 생성 완료! 위치: ", global_position, ", 쿨타임: ", alba_instance.cooldown_time, "초, 돈: ", alba_instance.money_amount, "원")
			
			# 구매 완료 표시
			is_purchased = true
			# 구매 후 숨기기 또는 비활성화 표시
			if sprite:
				sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
			# Area2D 비활성화 (더 이상 클릭 불가)
			area_2d.input_pickable = false
		else:
			print("돈이 부족합니다! 필요: ", price, "원, 보유: ", Globals.money, "원")
			# 인스턴스 삭제 (구매하지 않았으므로)
			alba_instance.queue_free()

func _on_area_2d_mouse_entered():
	# 마우스 오버 시 약간 크게
	if sprite and not is_purchased:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.1, 1.1), 0.1)

func _on_area_2d_mouse_exited():
	# 마우스 나갈 때 원래 크기로
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.1)
