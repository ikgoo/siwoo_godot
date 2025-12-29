@tool
extends StaticBody3D

@onready var sprite = $Sprite3D
var times = 0  # 현재 채굴 횟수
var max_times = 0  # 최대 채굴 필요 횟수
var type = ''

## 성장 관련 변수들
var current_age : int = 0  # 현재 나이 (성장 단계 인덱스)
var growth_timer : float = 0.0  # 성장 타이머
var growth_target_time : float = 0.0  # 현재 단계에서 다음 단계로 가는데 필요한 시간
var is_fully_grown : bool = false  # 완전히 성장했는지 여부

## 거리 기반 렌더링 설정
@export var render_distance : float = 15.0  # 렌더링 거리 (기본 15미터)
var player_node : Node3D = null  # 플레이어 노드 참조
var render_distance_timer: float = 0.0  # 거리 체크 타이머
const RENDER_DISTANCE_CHECK_INTERVAL: float = 0.3  # 0.3초마다 체크

## 카메라 기반 비활성화 설정
@export var is_node_get_unpowered_at_cam: bool = true  # 카메라에 안 보이면 비활성화
@export var camera_margin: float = 5.0  # 카메라 범위 밖 추가 렌더링 거리 (기본 5미터)
var camera_node: Camera3D = null  # 카메라 노드 참조
var check_visibility_timer: float = 0.0  # 가시성 체크 타이머
const VISIBILITY_CHECK_INTERVAL: float = 0.5  # 0.5초마다 체크

## 타일 범위 체크 타이머
var tile_range_check_timer: float = 0.0
const TILE_RANGE_CHECK_INTERVAL: float = 0.5  # 0.5초마다 체크

## 타일 범위 표시를 위한 노드들
var tile_indicators : Array[MeshInstance3D] = []
var show_tile_range : bool = false  # 타일 범위 표시 여부
# 아이템 드롭 설정
@export_group("아이템 드롭 설정")
@export var drop_range_min: float = 0.5  # 최소 드롭 범위
@export var drop_range_max: float = 2.0  # 최대 드롭 범위
@export var arc_height_min: float = 2.0   # 최소 포물선 높이
@export var arc_height_max: float = 4.0   # 최대 포물선 높이

@export var thing: obsticle = null:
	set(value):
		# 리소스를 복사하여 각 인스턴스가 독립적인 복사본을 가지도록 함
		thing = value.duplicate() if value else null
		if thing:
			max_times = thing.times_mine  # 최대 채굴 횟수 저장
			times = 0  # 현재 채굴 횟수 초기화
			type = thing.type
			if sprite:
				update_sprite_texture()
				sprite.offset.y = thing.offset
				# Area3D 크기 설정
				apply_area_size()

func _ready():
	# StaticBody3D의 마우스 입력을 비활성화 (Area3D만 마우스 이벤트 받도록)
	input_ray_pickable = false
	
	# "obsticle" 그룹에 추가 (entity의 raycast가 감지할 수 있도록)
	add_to_group("obsticle")
	
	if thing:
		max_times = thing.times_mine  # 최대 채굴 횟수 저장
		times = 0  # 현재 채굴 횟수 초기화
		type = thing.type
		
		# growable이고 growth_stages가 있으면 성장 시스템 사용
		if thing.is_growable and not thing.growth_stages.is_empty():
			current_age = 0
			growth_timer = 0.0
			is_fully_grown = false
			apply_growth_stage(current_age)
		else:
			# growable이 아니거나 growth_stages가 비어있으면 기본 설정 사용
			if sprite:
				update_sprite_texture()
				sprite.offset.y = thing.offset
		
		# Area3D 크기 설정
		apply_area_size()
	
	# 플레이어 노드 찾기
	if not Engine.is_editor_hint():
		find_player_node()
		find_camera_node()

# Area3D의 CollisionShape 크기를 이미지 크기에 맞게 설정하는 함수
# thing.area_radius를 배율로 사용하여 크기 조정
# 각 obsticle마다 독립적인 Shape를 생성하여 다른 obsticle에 영향을 주지 않음
func apply_area_size():
	if not thing or not sprite:
		return
	
	# sprite의 Area3D 가져오기
	var area_3d = sprite.get_node_or_null("Area3D")
	if not area_3d:
		return
	
	# CollisionShape3D 가져오기
	var collision_shape_3d = area_3d.get_node_or_null("CollisionShape3D")
	if not collision_shape_3d:
		return
	
	# 텍스처가 없으면 리턴
	if not thing.img:
		return
	
	# 새로운 BoxShape3D 생성 (다른 obsticle과 공유하지 않도록)
	var new_box_shape = BoxShape3D.new()
	
	# 텍스처의 실제 크기 계산 (pixel_size 고려)
	var texture_size = thing.img.get_size() * sprite.pixel_size
	
	# area_radius를 배율로 사용하여 크기 조정
	new_box_shape.size = Vector3(
		texture_size.x * thing.area_radius,
		texture_size.y * thing.area_radius,
		0.01  # Z축은 얇은 평면 유지
	)
	
	# 새로운 Shape를 CollisionShape3D에 할당
	collision_shape_3d.shape = new_box_shape
	
	print("[obsticle] Area 크기 설정: ", thing.name, " - 텍스처: ", thing.img.get_size(), " x ", thing.area_radius, " = ", new_box_shape.size)

## 스프라이트 텍스처를 업데이트하는 함수
## collectable 타입이면 is_collectable 상태에 따라 이미지 변경
func update_sprite_texture():
	if not thing or not sprite:
		return

	# collectable 타입이고 수집 전/후 이미지가 설정되어 있으면
	if thing.type == obsticle.mineable.collectable:
		if thing.is_collectable == 1 and thing.img_before_collect:
			# 수집 전 이미지 사용
			sprite.texture = thing.img_before_collect
		elif thing.is_collectable == 0 and thing.img_after_collect:
			# 수집 후 이미지 사용
			sprite.texture = thing.img_after_collect
		elif thing.img:
			# 수집 전/후 이미지가 없으면 기본 이미지 사용
			sprite.texture = thing.img
	else:
		# collectable이 아니면 기본 이미지 사용
		if thing.img:
			sprite.texture = thing.img
	
	# 텍스처가 변경되었으므로 CollisionShape 크기도 업데이트
	if sprite.has_method("update_collision_shape_size"):
		sprite.update_collision_shape_size()

func mine_once() -> bool:
	# growable이면 현재 단계가 채굴 가능한지 확인
	if thing and thing.is_growable and not thing.growth_stages.is_empty():
		if current_age < thing.growth_stages.size():
			var current_stage = thing.growth_stages[current_age]
			if not current_stage.is_mineable:
				# 채굴 불가능한 단계
				var character = get_tree().get_first_node_in_group("player")
				if character and character.has_method("show_description_text"):
					character.show_description_text("아직 자라는 중입니다...", 2.0)
				return false
	
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
	
	# ObstacleGrid에서 이 obsticle 제거
	unregister_from_obstacle_grid()
	
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

func _process(delta):
	# 픽셀 퍼펙트는 main.gd를 통해서만 실행되므로 여기서는 초기화하지 않음
	
	# 거리 기반 렌더링 체크 (에디터가 아닐 때만)
	if not Engine.is_editor_hint():
		# 성장 시스템 업데이트
		if thing and thing.is_growable and not is_fully_grown:
			update_growth(delta)
		
		# 거리 체크 (0.3초마다)
		render_distance_timer += delta
		if render_distance_timer >= RENDER_DISTANCE_CHECK_INTERVAL:
			render_distance_timer = 0.0
			check_render_distance()
		
		# 타일 범위 체크 (0.5초마다)
		tile_range_check_timer += delta
		if tile_range_check_timer >= TILE_RANGE_CHECK_INTERVAL:
			tile_range_check_timer = 0.0
			check_tile_range_visibility()
		
		# 카메라 가시성 체크 (is_node_get_unpowered_at_cam이 true일 때만)
		if is_node_get_unpowered_at_cam:
			check_visibility_timer += delta
			if check_visibility_timer >= VISIBILITY_CHECK_INTERVAL:
				check_visibility_timer = 0.0
				check_camera_visibility()

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
		
		# collectable 타입이면서 is_collectable이 1인 경우 - 이동해서 수집
		if thing and thing.type == obsticle.mineable.collectable and thing.is_collectable == 1:
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				handle_collectable_click()
				get_viewport().set_input_as_handled()
		# 제작대인 경우 제작 UI 열기
		elif thing and thing.type == obsticle.mineable.craft_table:
			open_craft_table_ui()
			get_viewport().set_input_as_handled()
		# 채굴 가능한 타입인 경우 - main.gd에서 처리하도록 이벤트 통과
		elif thing and (thing.type == obsticle.mineable.tree or thing.type == obsticle.mineable.stone or 
						thing.type == obsticle.mineable.moon_tree or thing.type == obsticle.mineable.moon_stone):
			# 이벤트를 통과시켜서 main.gd에서 채굴 처리하도록 함
			return
		# 그 외의 경우 설명 표시
		elif thing and not thing.sulmung.is_empty():
			# 캐릭터 찾기
			var character = get_tree().get_first_node_in_group("player")
			if not character:
				var main_scene = get_tree().current_scene
				if main_scene:
					character = main_scene.get_node_or_null("CharacterBody3D")
			
			# 캐릭터에게 설명 표시 요청
			if character and character.has_method("show_description_text"):
				character.show_description_text(thing.sulmung, 5.0)
			get_viewport().set_input_as_handled()

## collectable 타입 obsticle 클릭 처리 함수
## 캐릭터를 이동시키고 space_area에 도달하면 아이템 수집
func handle_collectable_click():
	if not thing or thing.type != obsticle.mineable.collectable:
		return
	
	print("📦 [수집 가능] 클릭 - ", thing.name)
	
	# 캐릭터 찾기
	var character = get_tree().get_first_node_in_group("player")
	if not character:
		var main_scene = get_tree().current_scene
		if main_scene:
			character = main_scene.get_node_or_null("CharacterBody3D")
	
	if not character:
		print("❌ 캐릭터를 찾을 수 없습니다")
		return
	
	# 캐릭터의 space_area 안에 있는지 확인
	if character.has_method("is_in_space_area"):
		if character.is_in_space_area(self):
			# 이미 범위 안에 있으면 즉시 수집
			collect_items()
		else:
			# 범위 밖이면 이동 시작
			character.on_item = self
			character.move_to_position(global_position)
			print("  🚶 범위 밖 - 이동 시작")


## collectable_thing 배열의 아이템들을 드롭하는 함수
## obsticle은 부서지지 않고 is_collectable만 0으로 변경됨
func collect_items():
	if not thing or thing.type != obsticle.mineable.collectable:
		return
	
	# is_collectable이 0이면 이미 수집됨
	if thing.is_collectable == 0:
		print("⚠️ [수집 불가] 이미 수집된 obsticle입니다")
		return
	
	print("✅ [수집 시작] ", thing.name)
	
	# collectable_thing 배열의 아이템들을 드롭
	if thing.collectable_thing and not thing.collectable_thing.is_empty():
		for collectable_item in thing.collectable_thing:
			if collectable_item:
				# 아이템 드롭 (채굴과 동일한 방식)
				create_item_drop(collectable_item)
				print("  📦 아이템 드롭: ", collectable_item.name, " x", collectable_item.count)
	else:
		print("  ⚠️ collectable_thing 배열이 비어있습니다")
	
	# is_collectable을 0으로 설정 (더 이상 수집 불가)
	thing.is_collectable = 0
	print("  🔒 is_collectable = 0 (수집 완료)")
	
	# 이미지 업데이트 (수집 후 이미지로 변경)
	update_sprite_texture()
	
	# 재생성 타이머 시작
	start_respawn_timer()

## 제작대 UI를 여는 함수
func open_craft_table_ui():
	if not thing or thing.type != obsticle.mineable.craft_table:
		return
	
	print("🔨 [제작대] 제작대 클릭 - tier: ", thing.tier)
	
	# 캐릭터 찾기
	var character = get_tree().get_first_node_in_group("player")
	if not character:
		var main_scene = get_tree().current_scene
		if main_scene:
			character = main_scene.get_node_or_null("CharacterBody3D")
	
	# 캐릭터와의 거리 확인 (너무 멀면 열지 않음)
	if character:
		var distance = global_position.distance_to(character.global_position)
		if distance > 3.0:  # 3미터 이상 떨어져 있으면
			if character.has_method("show_description_text"):
				character.show_description_text("너무 멀어요!", 2.0)
			return
	
	# 제작대 근처에 있으면 제작 UI 열기
	# (이미 _on_area_3d_body_entered에서 InventoryManeger에 등록됨)
	if character.has_method("show_description_text"):
		character.show_description_text("제작대를 사용합니다 (tier " + str(thing.tier) + ")", 2.0)
	
	print("  ✅ 제작대 사용 가능 - 현재 최고 tier: ", InventoryManeger.highest_nearby_tier)

## 플레이어 노드를 찾는 함수 (캐싱 포함)
func find_player_node():
	# 이미 유효한 노드가 있으면 재검색 안 함
	if player_node and is_instance_valid(player_node):
		return
	
	# "player" 그룹에서 플레이어 찾기
	player_node = get_tree().get_first_node_in_group("player")
	
	if not player_node:
		# 그룹이 없으면 직접 찾기 (한 번만)
		var main_scene = get_tree().current_scene
		if main_scene:
			player_node = main_scene.get_node_or_null("CharacterBody3D")

## 카메라 노드를 찾는 함수 (캐싱 포함)
func find_camera_node():
	# 이미 유효한 노드가 있으면 재검색 안 함
	if camera_node and is_instance_valid(camera_node):
		return
	
	camera_node = get_viewport().get_camera_3d()

## 플레이어와의 거리를 체크하여 렌더링 여부를 결정하는 함수
func check_render_distance():
	if not sprite:
		return
	
	# 플레이어 노드 확인 (없거나 유효하지 않으면 찾기)
	if not player_node or not is_instance_valid(player_node):
		find_player_node()
		if not player_node:  # 찾기 실패하면 리턴
			return

	# 플레이어와의 거리 계산
	var distance = global_position.distance_to(player_node.global_position)
	
	# 거리에 따라 sprite 표시/숨김
	sprite.visible = distance <= render_distance

## 카메라 가시성을 체크하여 노드 활성화/비활성화
func check_camera_visibility():
	if not sprite:
		return
	
	# 카메라 노드 확인 (없거나 유효하지 않으면 찾기)
	if not camera_node or not is_instance_valid(camera_node):
		find_camera_node()
		if not camera_node:  # 찾기 실패하면 리턴
			return
	
	# 카메라의 frustum 안에 있는지 체크
	var in_frustum = camera_node.is_position_in_frustum(global_position)
	
	# frustum 밖이면 추가로 거리 체크 (margin 범위 내면 렌더링)
	var should_render = in_frustum
	if not in_frustum and camera_margin > 0:
		var distance_to_camera = global_position.distance_to(camera_node.global_position)
		# 카메라와의 거리가 margin 범위 내면 렌더링
		should_render = distance_to_camera <= camera_margin
	
	# 가시성에 따라 sprite와 자식 노드들만 활성화/비활성화
	# (자기 자신의 _process는 계속 실행되어야 체크가 가능)
	if should_render:
		# 보이면 활성화
		sprite.visible = true
		# 자식 노드들 활성화
		for child in get_children():
			if child != sprite:  # sprite는 이미 처리했으므로 제외
				child.process_mode = Node.PROCESS_MODE_INHERIT
	else:
		# 안 보이면 비활성화
		sprite.visible = false
		# 자식 노드들 비활성화
		for child in get_children():
			if child != sprite:  # sprite는 이미 처리했으므로 제외
				child.process_mode = Node.PROCESS_MODE_DISABLED

## making_veiw가 활성화되어 있는지 체크하여 타일 범위 표시
func check_tile_range_visibility():
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
	
	var making_veiw = main_scene.get_node_or_null("making_veiw")
	if not making_veiw:
		return
	
	# making_veiw에 thing이 있으면 타일 범위 표시
	var should_show = making_veiw.thing != null
	
	if should_show != show_tile_range:
		show_tile_range = should_show
		if show_tile_range:
			create_tile_indicators()
		else:
			clear_tile_indicators()

## 타일 범위 인디케이터 생성
func create_tile_indicators():
	clear_tile_indicators()
	
	if not thing:
		return
	
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var cell_size = obstacle_grid.cell_size
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width = thing.grid_width if "grid_width" in thing else 3
	var grid_height = thing.grid_height if "grid_height" in thing else 3
	
	var tile_size_x = cell_size.x
	var tile_size_z = cell_size.z
	
	# 중심을 기준으로 타일 생성
	var half_width = floor(grid_width / 2.0)
	var half_height = floor(grid_height / 2.0)
	
	for x in range(-half_width, grid_width - half_width):
		for z in range(-half_height, grid_height - half_height):
			var mesh_instance = MeshInstance3D.new()
			
			var plane_mesh = PlaneMesh.new()
			plane_mesh.size = Vector2(tile_size_x * 0.9, tile_size_z * 0.9)
			plane_mesh.orientation = PlaneMesh.FACE_Y
			mesh_instance.mesh = plane_mesh
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 1.0, 0.0, 0.2)  # 반투명 노란색
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh_instance.material_override = material
			
			mesh_instance.position = Vector3(x * tile_size_x, 0.005, z * tile_size_z)
			
			add_child(mesh_instance)
			tile_indicators.append(mesh_instance)

## 타일 범위 인디케이터 제거
func clear_tile_indicators():
	for indicator in tile_indicators:
		if indicator:
			indicator.queue_free()
	tile_indicators.clear()

## ObstacleGrid에서 이 obsticle을 제거하는 함수
func unregister_from_obstacle_grid():
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	
	if not thing:
		return
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = thing.grid_width if "grid_width" in thing else 3
	var grid_height_tiles = thing.grid_height if "grid_height" in thing else 3
	
	# 월드 좌표를 ObstacleGrid의 그리드 좌표로 변환
	var center_grid_pos = obstacle_grid.world_to_grid(global_position)
	
	# ObstacleGrid에서 영역 제거
	obstacle_grid.unregister_obstacle_area(center_grid_pos, grid_width_tiles, grid_height_tiles)
	
	print("[obsticle] ObstacleGrid에서 제거: ", thing.name if "name" in thing else "unknown", " at ", center_grid_pos, " (타일 크기: %dx%d)" % [grid_width_tiles, grid_height_tiles])


## main.gd에서 호출하는 픽셀 퍼펙트 체크 함수
## main.gd의 raycast 충돌 지점을 직접 사용하여 픽셀 퍼펙트를 실행
## detected_area: main.gd의 raycast가 감지한 Area3D 객체
## collision_point: main.gd의 raycast 충돌 지점 (월드 좌표)
## 반환값: 픽셀 퍼펙트 성공 시 true, 실패 시 false
func check_pixel_perfect_from_main(detected_area: Area3D, collision_point: Vector3) -> bool:
	if not sprite:
		return false
	
	# sprite의 Area3D 가져오기
	var area_3d = sprite.get_node_or_null("Area3D")
	if not area_3d:
		return false
	
	# 감지된 Area가 내 Area가 아니면 false (다른 obsticle의 Area)
	if detected_area != area_3d:
		return false
	
	# sprite에 픽셀 퍼펙트 체크 함수가 있는지 확인
	if not sprite.has_method("check_pixel_perfect_at_point"):
		return false
	
	# sprite의 픽셀 퍼펙트 체크 함수 호출 (충돌 지점 전달)
	var pixel_check = sprite.check_pixel_perfect_at_point(collision_point)
	
	if pixel_check:
		# 성공: 빨간색으로 표시
		if sprite.has_method("set_red_highlight"):
			sprite.set_red_highlight()
		return true
	else:
		# 실패: 원래 색상으로 복원
		if sprite.has_method("update_hover_effect"):
			sprite.is_hovered = false
			sprite.update_hover_effect()
		return false


## 색상을 원래대로 복원하는 함수
func reset_color():
	if sprite and sprite.has_method("update_hover_effect"):
		sprite.is_hovered = false
		sprite.update_hover_effect()


## 재생성 타이머를 시작하는 함수
func start_respawn_timer():
	# Timer 노드 찾기
	var timer = get_node_or_null("Timer")
	if not timer:
		print("  ⚠️ Timer 노드를 찾을 수 없습니다")
		return
	
	# 타이머가 이미 실행 중이면 중단
	if timer.time_left > 0:
		timer.stop()
	
	# 타이머 시작
	timer.start()
	print("  ⏱️ 재생성 타이머 시작 - ", timer.wait_time, "초 후 재생성")


## 타이머 타임아웃 시 호출되는 함수
func _on_timer_timeout():
	if not thing or thing.type != obsticle.mineable.collectable:
		return
	
	print("🔄 [재생성] ", thing.name, " 재생성 완료")
	
	# is_collectable을 1로 되돌림 (다시 수집 가능)
	thing.is_collectable = 1
	print("  🔓 is_collectable = 1 (수집 가능)")
	
	# 이미지 업데이트 (수집 전 이미지로 변경)
	update_sprite_texture()


## 성장 업데이트 함수
## delta: 프레임 시간 (초)
func update_growth(delta: float):
	if not thing or thing.growth_stages.is_empty():
		return
	
	# 마지막 단계면 성장 중단
	if current_age >= thing.growth_stages.size() - 1:
		is_fully_grown = true
		return
	
	# 타이머 증가
	growth_timer += delta
	
	# 다음 단계로 성장할 시간이 되었는지 확인
	if growth_timer >= growth_target_time:
		growth_timer = 0.0
		current_age += 1
		apply_growth_stage(current_age)


## 특정 성장 단계를 적용하는 함수
## stage_index: 적용할 성장 단계 인덱스
func apply_growth_stage(stage_index: int):
	if not thing or thing.growth_stages.is_empty():
		return
	
	if stage_index < 0 or stage_index >= thing.growth_stages.size():
		return
	
	var stage = thing.growth_stages[stage_index]
	
	# 이미지 변경 (null이면 기본 img 사용)
	if sprite:
		if stage.stage_img:
			sprite.texture = stage.stage_img
		else:
			sprite.texture = thing.img  # 기본 이미지 사용
		
		# 오프셋 (0이면 기본 offset 사용)
		if stage.stage_offset != 0.0:
			sprite.offset.y = stage.stage_offset
		else:
			sprite.offset.y = thing.offset
		
		# 텍스처가 변경되었으므로 CollisionShape 크기도 업데이트
		if sprite.has_method("update_collision_shape_size"):
			sprite.update_collision_shape_size()
	
	# 채굴 횟수 (0이면 기본 times_mine 사용)
	if stage.stage_times_mine > 0:
		max_times = stage.stage_times_mine
	else:
		max_times = thing.times_mine
	times = 0  # 성장 단계가 올라가면 채굴 횟수 초기화
	
	# 드롭 아이템 (비어있으면 기본 things 사용)
	if not stage.stage_drops.is_empty():
		thing.things = stage.stage_drops.duplicate()
	# else: 기본 things 유지
	
	# suitable_tool 업데이트 (현재 단계의 suitable_tool 적용)
	thing.suitable_tool = stage.suitable_tool
	
	# 다음 단계로 성장하는데 걸리는 시간 설정 (랜덤)
	growth_target_time = stage.get_random_growth_time()
