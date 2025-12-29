extends Node3D

@onready var sprite_3d = $Sprite3D
const MAKING_NOTE = preload("uid://di76m0xa8r77h")
const OBSTICLE_SCENE = preload("res://obsticle.tscn")

## 타일 범위를 표시하는 MeshInstance3D 노드들을 저장하는 배열
var grid_indicators : Array[MeshInstance3D] = []

## 현재 위치가 다른 obsticle과 겹치는지 여부
var is_overlapping : bool = false

# 클릭 입력을 무시하기 위한 플래그
var ignore_next_click = false
var resipis : resipi

## 바로 obsticle을 생성하는 모드 (is_setable 아이템용)
var instant_place_mode : bool = false

## 캐릭터가 이동 중인지 여부 (is_setable 아이템용)
var waiting_for_character : bool = false

## 설치할 위치 저장 (is_setable 아이템용)
var pending_place_position : Vector3 = Vector3.ZERO

## 설치가 진행 중인지 여부 (중복 실행 방지)
var is_placing : bool = false

## 설치 가능 범위를 체크하는 임시 Area3D
var temp_setable_area : Area3D = null

## 캐릭터가 설치 범위 안에 있는지 여부
var character_in_setable_area : bool = false

@export var thing : obsticle:
	set(value):
		thing = value
		# thing이 설정되면 한 프레임 동안 클릭 입력 무시
		ignore_next_click = true
		# thing이 설정되면 Sprite3D 업데이트
		if thing and is_node_ready():
			update_sprite()
			update_grid_indicators()

func _ready():
	# 초기 thing이 있으면 스프라이트 업데이트
	if thing:
		update_sprite()
		update_grid_indicators()
	
## thing의 이미지를 Sprite3D에 표시하는 함수
func update_sprite():
	get_parent().is_click_move = false
	if sprite_3d and thing:
		if thing.img:
			sprite_3d.texture = thing.img
			# offset도 적용
			sprite_3d.offset.y = thing.offset
		elif not thing.growth_stages.is_empty() and thing.growth_stages[0].stage_img:
			# 기본 이미지가 없고 성장 단계가 있으면 첫 번째 단계 이미지 사용
			sprite_3d.texture = thing.growth_stages[0].stage_img
			# 첫 번째 단계의 offset 적용 (없으면 기본 offset)
			if thing.growth_stages[0].stage_offset != 0.0:
				sprite_3d.offset.y = thing.growth_stages[0].stage_offset
			else:
				sprite_3d.offset.y = thing.offset
		else:
			sprite_3d.texture = null
	elif sprite_3d:
		sprite_3d.texture = null

## 타일 범위 표시를 업데이트하는 함수
func update_grid_indicators():
	# 기존 인디케이터 제거
	clear_grid_indicators()
	
	if not thing:
		return
	
	var main_scene = get_parent()
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var cell_size = obstacle_grid.cell_size
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = thing.grid_width if "grid_width" in thing else 3
	var grid_height_tiles = thing.grid_height if "grid_height" in thing else 3
	
	# ObstacleGrid의 cell_size 사용
	var cell_size_x = cell_size.x
	var cell_size_z = cell_size.z
	
	# 중심을 기준으로 타일 생성
	var half_width = floor(grid_width_tiles / 2.0)
	var half_height = floor(grid_height_tiles / 2.0)
	
	for x in range(-half_width, grid_width_tiles - half_width):
		for z in range(-half_height, grid_height_tiles - half_height):
			create_tile_indicator(x * cell_size_x, z * cell_size_z, cell_size_x, cell_size_z)

## 단일 타일 인디케이터를 생성하는 함수
func create_tile_indicator(offset_x: float, offset_z: float, tile_size_x: float, tile_size_z: float):
	# MeshInstance3D 생성
	var mesh_instance = MeshInstance3D.new()
	
	# 평면 메쉬 생성 (바닥에 표시)
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(tile_size_x * 0.9, tile_size_z * 0.9)  # 타일보다 약간 작게
	plane_mesh.orientation = PlaneMesh.FACE_Y  # Y축을 향하도록 설정 (바닥에 평평하게)
	mesh_instance.mesh = plane_mesh
	
	# 머티리얼 생성 (기본 녹색, 겹침 체크 후 변경 가능)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.0, 1.0, 0.0, 0.3)  # 반투명 녹색
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED  # 양면 표시
	mesh_instance.material_override = material
	
	# 위치 설정 (로컬 좌표)
	mesh_instance.position = Vector3(offset_x, 0.01, offset_z)  # 바닥보다 약간 위
	
	# 자식으로 추가
	add_child(mesh_instance)
	grid_indicators.append(mesh_instance)

## 겹침 여부를 체크하고 타일 색상을 업데이트하는 함수
func check_and_update_overlap():
	if not thing:
		return
	
	# 겹침 체크
	is_overlapping = check_overlap()
	
	# 타일 색상 업데이트
	var color = Color(0.0, 1.0, 0.0, 0.5) if not is_overlapping else Color(1.0, 0.0, 0.0, 0.5)  # 초록색 or 빨간색
	
	for indicator in grid_indicators:
		if indicator and indicator.material_override:
			indicator.material_override.albedo_color = color

## 현재 위치가 다른 obsticle과 겹치는지 확인하는 함수
func check_overlap() -> bool:
	if not thing:
		return false
	
	var main_scene = get_parent()
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return false
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = thing.grid_width if "grid_width" in thing else 3
	var grid_height_tiles = thing.grid_height if "grid_height" in thing else 3
	
	# 월드 좌표를 ObstacleGrid의 그리드 좌표로 변환
	var center_grid_pos = obstacle_grid.world_to_grid(global_position)
	
	# ObstacleGrid의 함수를 사용하여 영역 체크
	return obstacle_grid.has_obstacle_in_area(center_grid_pos, grid_width_tiles, grid_height_tiles)

## 모든 타일 인디케이터를 제거하는 함수
func clear_grid_indicators():
	for indicator in grid_indicators:
		if indicator:
			indicator.queue_free()
	grid_indicators.clear()

## 월드 좌표를 그리드에 스냅하는 함수
## world_pos: 월드 좌표 (Vector3)
## 반환값: 그리드에 스냅된 월드 좌표 (Vector3)
func snap_to_grid(world_pos: Vector3) -> Vector3:
	var main_scene = get_parent()
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return world_pos
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var cell_size = obstacle_grid.cell_size
	
	# ObstacleGrid의 실제 셀 크기 사용
	var tile_size_x = cell_size.x
	var tile_size_z = cell_size.z
	
	# X와 Z 좌표를 타일 그리드에 스냅 (타일 중앙에 맞춤)
	var snapped_x = floor(world_pos.x / tile_size_x) * tile_size_x + tile_size_x / 2.0
	var snapped_z = floor(world_pos.z / tile_size_z) * tile_size_z + tile_size_z / 2.0
	
	# Y좌표는 그대로 유지
	return Vector3(snapped_x, world_pos.y, snapped_z)

## ObstacleGrid에 obsticle 정보를 등록하는 함수
## obsticle_node: 설치된 obsticle 노드
## world_pos: obsticle의 월드 좌표
func register_obsticle_to_grid(obsticle_node: Node3D, world_pos: Vector3):
	var main_scene = get_parent()
	if not main_scene.has_node("ObstacleGrid"):
		print("[making_veiw] 경고: ObstacleGrid를 찾을 수 없어서 obsticle을 등록할 수 없습니다!")
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var obsticle_data = obsticle_node.thing
	
	if not obsticle_data:
		return
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = obsticle_data.grid_width if "grid_width" in obsticle_data else 3
	var grid_height_tiles = obsticle_data.grid_height if "grid_height" in obsticle_data else 3
	
	# 월드 좌표를 ObstacleGrid의 그리드 좌표로 변환
	var center_grid_pos = obstacle_grid.world_to_grid(world_pos)
	
	# ObstacleGrid에 영역 등록
	obstacle_grid.register_obstacle_area(center_grid_pos, grid_width_tiles, grid_height_tiles)
	
	print("[making_veiw] obsticle 등록: ", obsticle_data.name if "name" in obsticle_data else "unknown", " at ", center_grid_pos, " (타일 크기: %dx%d)" % [grid_width_tiles, grid_height_tiles])

## ObstacleGrid에서 obsticle 정보를 제거하는 함수
## obsticle_node: 제거할 obsticle 노드
## world_pos: obsticle의 월드 좌표
func unregister_obsticle_from_grid(obsticle_node: Node3D, world_pos: Vector3):
	var main_scene = get_parent()
	if not main_scene.has_node("ObstacleGrid"):
		print("[making_veiw] 경고: ObstacleGrid를 찾을 수 없어서 obsticle을 제거할 수 없습니다!")
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var obsticle_data = obsticle_node.thing
	
	if not obsticle_data:
		return
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = obsticle_data.grid_width if "grid_width" in obsticle_data else 3
	var grid_height_tiles = obsticle_data.grid_height if "grid_height" in obsticle_data else 3
	
	# 월드 좌표를 ObstacleGrid의 그리드 좌표로 변환
	var center_grid_pos = obstacle_grid.world_to_grid(world_pos)
	
	# ObstacleGrid에서 영역 제거
	obstacle_grid.unregister_obstacle_area(center_grid_pos, grid_width_tiles, grid_height_tiles)
	
	print("[making_veiw] obsticle 제거: ", obsticle_data.name if "name" in obsticle_data else "unknown", " at ", center_grid_pos, " (타일 크기: %dx%d)" % [grid_width_tiles, grid_height_tiles])

## pending_place_position에 obsticle을 설치하는 함수
func place_obsticle_at_pending_position():
	# 중복 실행 방지
	if is_placing:
		return
	
	if not thing:
		return
	
	if not InventoryManeger.now_hand:
		return
	
	# 설치 시작 플래그
	is_placing = true
	
	# thing을 미리 저장 (아이템 소모 후에도 사용하기 위해)
	var obsticle_to_place = thing
	
	# 손에 든 아이템 1개 소모 (obsticle 생성 전에 먼저 소모)
	InventoryManeger.now_hand.count -= 1
	
	if InventoryManeger.now_hand.count <= 0:
		# 아이템이 다 소모되면 null로 설정
		InventoryManeger.now_hand = null
		thing = null
		instant_place_mode = false
		visible = false
	
	# 시그널 발생 (UI 업데이트)
	InventoryManeger.change_now_hand.emit(InventoryManeger.now_hand)
	
	# obsticle 생성 (저장해둔 obsticle_to_place 사용)
	var new_obsticle = OBSTICLE_SCENE.instantiate()
	new_obsticle.thing = obsticle_to_place
	
	# pending_place_position은 이미 raycast 충돌 지점의 좌표
	new_obsticle.global_position = pending_place_position
	get_parent().add_child(new_obsticle)
	
	# grid_map2에 obsticle 좌표 정보 저장
	register_obsticle_to_grid(new_obsticle, pending_place_position)
	
	# 상태 초기화
	update_sprite()
	
	# 아이템이 남아있으면 타일 인디케이터 유지, 없으면 제거
	if thing:
		update_grid_indicators()  # 타일 인디케이터 다시 생성
	else:
		clear_grid_indicators()
	
	get_parent().is_click_move = true
	pending_place_position = Vector3.ZERO
	is_placing = false
	character_in_setable_area = false
	
	# 임시 Area3D 제거
	remove_temp_setable_area()

## 설치를 취소하는 함수 (WASD로 중단했을 때)
func cancel_placement():
	waiting_for_character = false
	pending_place_position = Vector3.ZERO
	is_placing = false
	character_in_setable_area = false
	get_parent().is_click_move = true
	
	# 임시 Area3D 제거
	remove_temp_setable_area()
	
	# making_veiw를 다시 마우스를 따라다니도록 설정
	# instant_place_mode는 유지 (아직 손에 아이템이 있으므로)

## 임시 is_setable_area를 생성하는 함수
func create_temp_setable_area(target_position: Vector3):
	# 기존 임시 Area3D가 있으면 제거
	remove_temp_setable_area()
	
	# 새로운 Area3D 생성
	temp_setable_area = Area3D.new()
	temp_setable_area.global_position = target_position
	temp_setable_area.collision_layer = 0
	temp_setable_area.collision_mask = 128  # 캐릭터의 Area3D와 충돌
	
	# CollisionShape3D 생성 (making_note의 is_setable_area와 동일한 크기)
	var collision_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = 0.50878906
	cylinder_shape.radius = 0.106933594
	collision_shape.shape = cylinder_shape
	
	temp_setable_area.add_child(collision_shape)
	get_parent().add_child(temp_setable_area)
	
	# 신호 연결
	temp_setable_area.area_entered.connect(_on_temp_setable_area_entered)
	temp_setable_area.area_exited.connect(_on_temp_setable_area_exited)
	
	print("임시 is_setable_area 생성됨: ", target_position)

## 임시 is_setable_area를 제거하는 함수
func remove_temp_setable_area():
	if temp_setable_area:
		temp_setable_area.queue_free()
		temp_setable_area = null
		print("임시 is_setable_area 제거됨")

## 캐릭터가 임시 is_setable_area에 들어왔을 때
func _on_temp_setable_area_entered(area: Area3D):
	# 캐릭터의 Area3D인지 확인
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		character_in_setable_area = true
		print("캐릭터가 설치 범위에 진입함")

## 캐릭터가 임시 is_setable_area에서 나갔을 때
func _on_temp_setable_area_exited(area: Area3D):
	# 캐릭터의 Area3D인지 확인
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		character_in_setable_area = false
		print("캐릭터가 설치 범위에서 벗어남")

## 매 프레임 호출되는 함수 - 마우스 위치를 추적합니다
## delta: 프레임 간 경과 시간
func _process(_delta):
	# 캐릭터 이동 완료 확인
	if waiting_for_character:
		# pending_place_position이 유효한지 확인 (취소되지 않았는지)
		if pending_place_position == Vector3.ZERO:
			waiting_for_character = false
			return
		
		# 캐릭터가 is_setable_area 안에 들어왔는지 확인
		if character_in_setable_area:
			# 범위 안에 들어왔으면 캐릭터 이동을 중단하고 obsticle 설치
			var player = get_parent().get_node_or_null("CharacterBody3D")
			if player:
				# 이동 중단
				player.is_moving_to_target = false
				player.manual_input_disabled = false
				# velocity 초기화
				player.velocity.x = 0
				player.velocity.z = 0
				# idle 애니메이션으로 전환
				player.anime(Vector3.ZERO)
			
			# obsticle 설치
			place_obsticle_at_pending_position()
			waiting_for_character = false
			
			# 임시 Area3D 제거
			remove_temp_setable_area()
			return
		return  # 이동 중에는 마우스 추적 중단
	
	# 마우스 화면 좌표를 월드 좌표로 변환
	var mouse_pos = get_viewport().get_mouse_position()

	
	if Globals.mouse_pos != Vector3.ZERO:
		# 타일에 스냅된 위치로 이동 (부드럽게 움직이지 않고 딱 타일에 맞춤)
		# Globals.mouse_pos는 이미 raycast로 GridMap과 충돌한 지점
		var snapped_pos = snap_to_grid(Globals.mouse_pos)
		
		position.x = snapped_pos.x
		position.y = snapped_pos.y  # raycast 충돌 지점의 Y좌표 사용
		position.z = snapped_pos.z
		
		# 겹침 체크 및 타일 색상 업데이트
		if thing:
			check_and_update_overlap()
	
	# 우클릭 입력 처리 (구조물 설치)
	if Input.is_action_just_pressed("r_click"):
		if thing:
			# 제작 버튼 클릭 직후라면 이번 클릭 무시 (instant_place_mode가 아닐 때만)
			if ignore_next_click and not instant_place_mode:
				ignore_next_click = false
				print("제작 버튼 클릭 무시됨")
				return
			
			# instant_place_mode일 때는 ignore_next_click을 무시하고 바로 클리어
			if ignore_next_click and instant_place_mode:
				ignore_next_click = false
			
			# 겹침 여부 확인 - 다른 obsticle과 겹치면 설치 불가
			if is_overlapping:
				print("❌ 다른 obsticle과 겹쳐서 설치할 수 없습니다!")
				return
			
			# tier 체크 - resipis가 있고 required_tier가 설정되어 있으면 확인
			if resipis and resipis.required_tier > 0:
				if resipis.required_tier > InventoryManeger.highest_nearby_tier:
					print("❌ tier ", resipis.required_tier, " 제작대가 필요합니다! (현재: ", InventoryManeger.highest_nearby_tier, ")")
					# 캐릭터에게 메시지 표시
					var player = get_parent().get_node_or_null("CharacterBody3D")
					if player and player.has_method("show_description_text"):
						player.show_description_text("tier " + str(resipis.required_tier) + " 제작대가 필요합니다!", 3.0)
					return
			
			# instant_place_mode면 캐릭터를 해당 위치로 이동시킴
			if instant_place_mode:
				print("is_setable 아이템 - 우클릭으로 설치 시작")
				# making_veiw를 현재 위치에 고정
				waiting_for_character = true
				pending_place_position = global_position
				
				# 임시 is_setable_area 생성
				create_temp_setable_area(pending_place_position)
				
				# 클릭 이동을 비활성화 (캐릭터가 도착할 때까지)
				get_parent().is_click_move = false
				
				# 캐릭터를 해당 위치로 이동
				var player = get_parent().get_node_or_null("CharacterBody3D")
				if player:
					player.move_to_position(pending_place_position)
			else:
				# 기존 로직: making_note 생성
				print("obsticle 설치됨")
				var a = MAKING_NOTE.instantiate()
				a.thing = thing
				a.global_position = global_position
				a.resipis = resipis
				get_parent().add_child(a)
				
				# grid_map2에 obsticle 좌표 정보 저장
				register_obsticle_to_grid(a, global_position)
				
				thing = null
				update_sprite()
				clear_grid_indicators()  # 타일 범위 표시 제거
				get_parent().is_click_move = true
