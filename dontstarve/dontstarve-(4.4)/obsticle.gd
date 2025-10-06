@tool
extends StaticBody3D
@onready var sprite = $Sprite3D
var times = 0  # 현재 채굴 횟수
var max_times = 0  # 최대 채굴 필요 횟수
var type = ''
@export var thing: obsticle = null:
	set(value):
		print("value:", value)
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
	print("채굴/벌목 진행: ", times, "/", max_times)
	
	# 시각적 피드백 - 채굴할 때마다 살짝 흔들리는 효과
	add_mining_effect()
	
	# 필요한 채굴 횟수에 도달했는지 확인
	if times >= max_times:
		print("채굴/벌목 완료!")
		drop_items()
		return true
	else:
		print("더 채굴이 필요합니다 (", (max_times - times), "번 더)")
		return false

# 아이템 드롭 시스템
func drop_items():
	if not thing or thing.things.is_empty():
		print("드롭할 아이템이 설정되지 않음")
		return
	
	print("=== 아이템 드롭 시작 ===")
	
	# 각 obsticle_get에 대해 확률적으로 아이템 생성
	for drop_info in thing.things:
		if drop_info.get_item == null:
			continue
		
		# 먼저 이 아이템이 드롭될지 확률적으로 결정
		if not drop_info.should_drop():
			print("아이템 드롭 실패 (확률): ", drop_info.get_item.name, " (", drop_info.drop_chance * 100, "%)")
			continue
			
		# min_count와 max_count 사이의 균등한 확률로 개수 결정
		var drop_count = drop_info.get_random_count()
		
		print("아이템 드롭 성공: ", drop_info.get_item.name, " x", drop_count, " (확률: ", drop_info.drop_chance * 100, "%)")
		
		# 드롭할 개수만큼 아이템 생성
		for i in range(drop_count):
			create_item_drop(drop_info.get_item)

# 개별 아이템을 땅에 드롭하는 함수
func create_item_drop(item: Item):
	# 아이템 복사본 생성
	var dropped_item = item.duplicate()
	dropped_item.count = 1  # 개별 아이템은 1개씩
	
	# 아이템 드롭 위치 계산 (장애물 주변 랜덤 위치)
	var drop_position = global_position
	drop_position.x += randf_range(-0.1, 0.1)  # X축 랜덤 오프셋
	drop_position.z += randf_range(-0.1, 0.1)  # Z축 랜덤 오프셋
	drop_position.y = global_position.y        # Y축은 동일하게
	
	# ItemGround 씬 로드 및 생성
	var item_ground_scene = preload("res://item_ground.tscn")
	var item_ground = item_ground_scene.instantiate()
	
	# 아이템 설정
	item_ground.thing = dropped_item
	item_ground.global_position = drop_position
	
	# 메인 씬에 추가
	get_tree().current_scene.add_child(item_ground)
	
	print("아이템 드롭 완료: ", dropped_item.name, " at ", drop_position)

func add_mining_effect():
	# 채굴 시 흔들림 효과 (Godot 4 트윈 애니메이션)
	var tween = create_tween()
	var original_position = sprite.position
	
	# 연속적인 흔들림 효과
	tween.tween_property(sprite, "position", original_position + Vector3(0.02, 0, 0), 0.05)
	tween.tween_property(sprite, "position", original_position - Vector3(0.02, 0, 0), 0.05)
	tween.tween_property(sprite, "position", original_position, 0.05)
