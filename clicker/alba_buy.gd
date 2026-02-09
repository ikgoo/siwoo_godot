extends Node2D

# 알바 씬 경로
@export var alba_scene_path : String = "res://alba.tscn"
# 펫 추적 설정 (알바 구매 시 캐릭터 뒤를 따라다님)
@export var pet_offset: Vector2 = Vector2(-40, -10)  # 캐릭터 기준 뒤쪽 위치
@export var pet_follow_speed: float = 5.0  # 따라오는 속도 (높을수록 빠름)
@export var pet_texture: Texture2D  # 알바 펫 스킨 (없으면 알바 스프라이트 사용)
@export var pet_scale: Vector2 = Vector2(1.0, 1.0)  # 펫 크기 배율
# 알바 프리셋 선택 (가격/수입 테이블 설정용)
@export_enum("custom", "alba1", "alba2") var alba_preset: String = "custom"

# 커스텀 프리셋 값 (alba_preset = custom 일 때 사용)
@export_group("Custom Preset (preset=custom)")
@export var custom_price: int = 2000
@export var custom_money_amount: int = 50
@export var custom_upgrade_costs: Array[int] = [2000, 3000, 4000]
@export var custom_upgrade_incomes: Array[int] = [120, 200, 350]
@export_group("")
# Area2D 노드 참조
@onready var area_2d = $Area2D
# 알바 씬을 로드한 PackedScene
var alba_scene : PackedScene
# 이미 구매했는지 여부
var is_purchased : bool = false
# 생성된 펫 스프라이트
var pet_sprite: Sprite2D = null

# 시각 효과
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready():
	# 알바 씬 로드
	alba_scene = load(alba_scene_path)
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

# 알바 구매 함수
func purchase_alba():
	# 이미 구매했으면 무시
	if is_purchased:
		return
	
	# 알바 인스턴스 생성 (가격 확인을 위해 임시로 생성)
	var alba_instance = alba_scene.instantiate()
	
	# 알바의 export 변수에서 가격 가져오기
	var price = alba_instance.price
	
	# 돈이 충분한지 확인
	if Globals.money >= price:
		# 돈 차감
		Globals.money -= price
		
		# 프리셋 적용 후 알바 배치
		apply_preset_to_alba(alba_instance)
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
		# 인스턴스 삭제 (구매하지 않았으므로)
		alba_instance.queue_free()

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
	var alba_instance = alba_scene.instantiate()
	var buy_price = alba_instance.price
	var income = alba_instance.money_amount
	alba_instance.queue_free()
	
	return Globals.get_text("ALBA INFO") % [buy_price, income]

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

# === 프리셋 적용 ===
func apply_preset_to_alba(alba_instance: Node):
	# alba 스크립트에 alba_preset이 있으면 custom으로 맞춰 놓고 값을 직접 세팅
	if "alba_preset" in alba_instance:
		alba_instance.alba_preset = "custom"
	match alba_preset:
		"alba1":
			alba_instance.price = 2000
			alba_instance.money_amount = 50
			alba_instance.upgrade_costs = [2000, 3000, 4000]
			alba_instance.upgrade_incomes = [120, 200, 350]
		"alba2":
			alba_instance.price = 4000
			alba_instance.money_amount = 400
			alba_instance.upgrade_costs = [5000, 6000]
			alba_instance.upgrade_incomes = [600, 800]
		_:
			alba_instance.price = custom_price
			alba_instance.money_amount = custom_money_amount
			alba_instance.upgrade_costs = custom_upgrade_costs
			alba_instance.upgrade_incomes = custom_upgrade_incomes
	
	# 펫 텍스처는 상점에서 전달한다.
	if "pet_texture" in alba_instance:
		alba_instance.pet_texture = pet_texture
