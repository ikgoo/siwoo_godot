@tool
extends StaticBody3D

# 설명 텍스트 표시를 위한 시그널
signal show_description_requested(description_text: String, duration: float)

@onready var sprite = $Sprite3D
var times = 0  # 현재 채굴 횟수
var max_times = 0  # 최대 채굴 필요 횟수
var type = ''
var text_timer: Timer = null  # 텍스트 표시를 위한 타이머
var is_entered = false
# 아이템 드롭 설정
@export_group("아이템 드롭 설정")
@export var drop_range_min: float = 0.5  # 최소 드롭 범위
@export var drop_range_max: float = 2.0  # 최대 드롭 범위
@export var arc_height_min: float = 2.0   # 최소 포물선 높이
@export var arc_height_max: float = 4.0   # 최대 포물선 높이

@export var thing: obsticle = null:
	set(value):
		thing = value
		if thing:
			max_times = thing.times_mine  # 최대 채굴 횟수 저장
			times = 0  # 현재 채굴 횟수 초기화
			type = thing.type
			if thing.img:
				if sprite:
					sprite.texture = thing.img
					sprite.offset.y = value.offset
# Called when the node enters the scene tree for the first time.
func _ready():
	if thing:
		max_times = thing.times_mine  # 최대 채굴 횟수 저장
		times = 0  # 현재 채굴 횟수 초기화
		type = thing.type
		if thing.img:
			if sprite:
				sprite.texture = thing.img
				sprite.offset.y = thing.offset

func mine_once() -> bool:
	if max_times <= 0:
		# times_mine이 0이면 즉시 벌목
		drop_items()
		return true
	
	times += 1
	
	# 시각적 피드백 - 채굴할 때마다 살짝 흔들리는 효과
	add_mining_effect()
	
	# 필요한 채굴 횟수에 도달했는지 확인
	if times >= max_times:
		drop_items()
		return true
	else:
		return false

# 아이템 드롭 시스템
func drop_items():
	if not thing or thing.things.is_empty():
		return
	
	# 각 obsticle_get에 대해 확률적으로 아이템 생성
	for drop_info in thing.things:
		if drop_info.get_item == null:
			continue
		
		# 먼저 이 아이템이 드롭될지 확률적으로 결정
		if not drop_info.should_drop():
			continue
			
		# min_count와 max_count 사이의 균등한 확률로 개수 결정
		var drop_count = drop_info.get_random_count()
		
		# 드롭할 개수만큼 아이템 생성
		for i in range(drop_count):
			create_item_drop(drop_info.get_item)

# 개별 아이템을 땅에 드롭하는 함수
func create_item_drop(item: Item):
	# 아이템 복사본 생성
	var dropped_item = item.duplicate()
	dropped_item.count = 1  # 개별 아이템은 1개씩
	
	# 시작 위치 (obsticle 위치)
	var start_position = global_position
	
	# 목표 위치 계산 (장애물 주변 랜덤 위치)
	var target_position = global_position
	target_position.x += randf_range(-drop_range_max, drop_range_max)  # X축 랜덤 오프셋
	target_position.z += randf_range(-drop_range_max, drop_range_max)  # Z축 랜덤 오프셋
	target_position.y = global_position.y        # Y축은 동일하게
	
	# ItemGround 씬 로드 및 생성
	var item_ground_scene = preload("res://item_ground.tscn")
	var item_ground = item_ground_scene.instantiate()
	
	# 아이템 설정
	item_ground.thing = dropped_item
	
	# 메인 씬에 추가
	get_tree().current_scene.add_child(item_ground)
	
	# 포물선 비행 시작 (거리에 따라 자동으로 비행 시간 계산)
	var distance = start_position.distance_to(target_position)
	var flight_time = distance * 0.3 + 0.5  # 거리에 비례한 비행 시간 (최소 0.5초)
	var arc_height = randf_range(arc_height_min, arc_height_max)     # 랜덤 포물선 높이
	item_ground.flying_item(start_position, target_position, flight_time, arc_height)

func add_mining_effect():
	# 채굴 시 흔들림 효과 (Godot 4 트윈 애니메이션)
	var tween = create_tween()
	var original_position = sprite.position
	
	# 연속적인 흔들림 효과
	tween.tween_property(sprite, "position", original_position + Vector3(0.02, 0, 0), 0.05)
	tween.tween_property(sprite, "position", original_position - Vector3(0.02, 0, 0), 0.05)
	tween.tween_property(sprite, "position", original_position, 0.05)

 


func _on_mouse_entered():
	is_entered = true
	sprite.modulate = Color(0.784, 0.784, 0.784, 1.0)
	


func _on_mouse_exited():
	is_entered = false
	sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _process(_delta):
	if is_entered:
		if Input.is_action_just_pressed("clicks"):
			# 클릭 시 설명 표시 시그널 발생
			if thing and not thing.sulmung.is_empty():
				show_description_requested.emit(thing.sulmung, 5.0)

# 마우스 클릭 처리 함수
# _camera: 클릭한 카메라 (사용하지 않음)
# event: 입력 이벤트
# _event_position: 클릭 위치 (사용하지 않음)
# _normal: 충돌 표면의 법선 벡터 (사용하지 않음)
# _shape_idx: 충돌한 shape 인덱스 (사용하지 않음)
func _on_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int):
	# 마우스 클릭 이벤트인지 확인
	if event is InputEventMouseButton:
		# 왼쪽 클릭이고 눌렀을 때 (released가 아님)
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# UI 위에서 클릭했는지 확인
			var viewport = get_viewport()
			var control_under_mouse = viewport.gui_get_hovered_control()
			if control_under_mouse:
				# UI 위에서 클릭하면 이벤트를 통과시킴 (인벤토리 등)
				return
			
			# Shift 키가 눌려있으면 이동 (이벤트 통과시킴)
			if Input.is_key_pressed(KEY_SHIFT):
				return  # 이벤트를 통과시켜서 main.gd에서 처리하도록 함
			else:
				# Shift 키가 안 눌려있으면 설명 표시 시그널 발생
				if thing and not thing.sulmung.is_empty():
					show_description_requested.emit(thing.sulmung, 5.0)
				# 이벤트 소비하여 main.gd로 전달되지 않도록 함
				get_viewport().set_input_as_handled()


# 캐릭터의 Label3D에 설명 텍스트를 5초간 표시하는 함수
func show_description_on_character():
	# thing이 없거나 sulmung이 비어있으면 무시
	if not thing or thing.sulmung.is_empty():
		return
	
	# 씬에서 CharacterBody3D 찾기
	var character = get_tree().get_first_node_in_group("player")
	if not character:
		# group이 없으면 직접 찾기
		var main_scene = get_tree().current_scene
		if main_scene:
			character = main_scene.get_node_or_null("CharacterBody3D")
	
	if not character:
		print("캐릭터를 찾을 수 없습니다!")
		return
	
	# Label3D 노드 찾기
	var label3d = character.get_node_or_null("Label3D")
	if not label3d:
		print("Label3D를 찾을 수 없습니다!")
		return
	
	# 텍스트 설정
	label3d.text = thing.sulmung
	label3d.visible = true
	
	# 기존 타이머가 있으면 제거
	if text_timer:
		text_timer.stop()
		text_timer.queue_free()
		text_timer = null
	
	# 5초 후 텍스트를 지우는 타이머 생성
	text_timer = Timer.new()
	text_timer.wait_time = 5.0
	text_timer.one_shot = true
	text_timer.timeout.connect(_on_text_timer_timeout.bind(label3d))
	add_child(text_timer)
	text_timer.start()


# 타이머 완료 시 텍스트를 지우는 함수
# label: 지울 Label3D 노드
func _on_text_timer_timeout(label: Label3D):
	if label:
		label.text = ""
		label.visible = false
	
	# 타이머 정리
	if text_timer:
		text_timer.queue_free()
		text_timer = null
