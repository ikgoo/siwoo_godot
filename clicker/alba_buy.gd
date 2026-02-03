extends Node2D

## ========================================
## 알바 구매 시스템 - 리소스 기반
## ========================================
## AlbaData 리소스를 사용하여 알바를 판매합니다

# 알바 데이터 리소스
@export var alba_data: AlbaData

# Area2D 노드 참조
@onready var area_2d = $Area2D

# 알바 씬 (항상 alba.tscn 사용)
const ALBA_SCENE_PATH: String = "res://alba.tscn"
var alba_scene: PackedScene

# 이미 구매했는지 여부
var is_purchased: bool = false

# 시각 효과
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready():
	# 리소스 확인
	if not alba_data:
		print("⚠️ 경고: alba_data 리소스가 설정되지 않았습니다!")
		return
	
	# 알바 씬 로드
	alba_scene = load(ALBA_SCENE_PATH)
	if not alba_scene:
		print("❌ 오류: alba.tscn을 찾을 수 없습니다!")
		return
	
	# 스프라이트 텍스처 설정 (리소스에서)
	if sprite and alba_data.alba_texture:
		sprite.texture = alba_data.alba_texture
	
	# Area2D의 input_event 시그널 연결
	area_2d.input_event.connect(_on_area_2d_input_event)
	# Area2D의 body_entered/exited 시그널 연결
	area_2d.body_entered.connect(_on_area_2d_body_entered)
	area_2d.body_exited.connect(_on_area_2d_body_exited)
	
	# Globals Signal 구독
	Globals.money_changed.connect(_on_money_changed)

func _process(_delta):
	# 구매 가능 여부 시각 표시
	if not is_purchased:
		update_visual_feedback()
		
		# 플레이어가 영역 안에 있고 F키를 누르면 구매
		if is_character_inside and Input.is_action_just_pressed("f"):
			purchase_alba()


# 구매 가능 여부 시각 표시
func update_visual_feedback():
	if not sprite or not alba_data:
		return
	
	# 리소스에서 가격 확인
	var price = alba_data.initial_price
	
	# 구매 가능하면 밝게, 불가능하면 어둡게
	if Globals.money >= price:
		sprite.modulate = Color(1.2, 1.2, 1.2)
	else:
		sprite.modulate = Color(0.7, 0.7, 0.7)

# 돈 변경 시 호출
func _on_money_changed(_new_amount: int, _delta: int):
	update_visual_feedback()

# 알바 구매 함수
func purchase_alba():
	# 이미 구매했으면 무시
	if is_purchased or not alba_data:
		return
	
	# 리소스에서 가격 확인
	var price = alba_data.initial_price
	
	# 돈이 충분한지 확인
	if Globals.money >= price:
		# 돈 차감
		Globals.money -= price
		print("💎 알바 구매: ", alba_data.alba_name, " (", price, "원)")
		
		# 알바 인스턴스 생성
		var alba_instance = alba_scene.instantiate()
		
		# 리소스 데이터 전달
		alba_instance.alba_data = alba_data
		alba_instance.global_position = global_position
		
		# 부모 노드(보통 main 씬)에 추가
		get_tree().current_scene.add_child(alba_instance)
		
		# 구매 완료 표시
		is_purchased = true
		# 구매 후 숨기기 또는 비활성화 표시
		if sprite:
			sprite.modulate = Color(0.3, 0.3, 0.3, 0.5)
		# Area2D 비활성화 (더 이상 클릭 불가)
		area_2d.input_pickable = false
		# 액션 텍스트 숨김
		Globals.hide_action_text()
	else:
		print("💎 부족! 필요: 💎", price, ", 보유: 💎", Globals.money)

# Area2D 입력 이벤트 처리 (마우스 클릭)
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# 마우스 왼쪽 버튼 클릭 확인
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		purchase_alba()

# 플레이어 영역 감지용
var is_character_inside: bool = false

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

# 알바 구매 정보 텍스트 생성
func get_alba_buy_info_text() -> String:
	if not alba_data:
		return "알바 데이터 없음"
	
	return "%s 고용\n가격: 💎%d\n수입: 💎%d/초" % [alba_data.alba_name, alba_data.initial_price, alba_data.initial_income]

# 플레이어가 영역에 들어왔을 때
func _on_area_2d_body_entered(body):
	if body is CharacterBody2D and not is_purchased:
		is_character_inside = true
		# 액션 텍스트로 구매 정보 표시
		Globals.show_action_text(get_alba_buy_info_text())

# 플레이어가 영역에서 나갔을 때
func _on_area_2d_body_exited(body):
	if body is CharacterBody2D:
		is_character_inside = false
		# 액션 텍스트 숨김
		Globals.hide_action_text()
