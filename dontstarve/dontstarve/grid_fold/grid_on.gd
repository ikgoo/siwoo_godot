extends Node

## 지형 타입 저장용 2차원 배열
## GridMap 타일 ID와 동일하게 매핑:
## 0: MeshInstance3D (기본)
## 1: grass (풀)
## 2: dirt (흙)
## 3: sand (모래)
## 4: nothing (빈 타일)
## 5: sea (바다)
var grid: Array = []

## 맵 크기 enum (RandomMapGenerator와 동일)
enum MapSize { SMALL, MEDIUM, LARGE }

## 맵 크기 설정
@export var map_size: MapSize = MapSize.LARGE

## 그리드 크기 (맵 크기에 따라 자동 설정됨)
var grid_width: int = 50
var grid_height: int = 50

## 랜덤 맵 생성 사용 여부
@export var use_random_generation: bool = true

## obsticle 씬 프리로드
const OBSTICLE_SCENE = preload("res://obsticle.tscn")

## 나무 리소스 프리로드
var tree_resource: obsticle = null

## 돌 리소스 프리로드
var stone_resource: obsticle = null

## 스폰 완료 플래그
var spawned: bool = false

## 디버그 모드 (false로 설정하면 print 출력 안 함)
var debug_mode: bool = false

func _ready():
	# 게임 시작 시 자동으로 초기화
	initialize_grid()
	
	# 나무 리소스 로드
	tree_resource = load("res://obsticle/obsticles/tree.tres") as obsticle
	
	# 돌 리소스 로드
	stone_resource = load("res://obsticle/obsticles/stone.tres") as obsticle
	
	# 랜덤 맵 생성 또는 테스트 지형 사용
	if use_random_generation:
		generate_random_terrain()
	else:
		setup_test_terrain()

## grid 2차원 배열 초기화 함수
func initialize_grid():
	grid.clear()
	
	# 2차원 배열 생성 (모두 0으로 초기화)
	for x in range(grid_width):
		var row = []
		for y in range(grid_height):
			row.append(0)  # 0: 아무것도 없음
		grid.append(row)
	
	if debug_mode:
		print("[GridOn] grid 초기화 완료: %dx%d" % [grid_width, grid_height])

## 특정 위치의 지형 타입 설정
## @param x: X 좌표 (그리드 인덱스)
## @param y: Y 좌표 (그리드 인덱스)
## @param terrain_type: 지형 타입 (0: MeshInstance3D, 1: grass, 2: dirt, 3: sand, 4: nothing, 5: sea)
func set_terrain(x: int, y: int, terrain_type: int):
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		push_error("[GridOn] 범위 초과: (%d, %d)" % [x, y])
		return
	
	grid[x][y] = terrain_type

## 특정 위치의 지형 타입 가져오기
## @param x: X 좌표 (그리드 인덱스)
## @param y: Y 좌표 (그리드 인덱스)
## @return: 지형 타입 (0: MeshInstance3D, 1: grass, 2: dirt, 3: sand, 4: nothing, 5: sea)
func get_terrain(x: int, y: int) -> int:
	if x < 0 or x >= grid_width or y < 0 or y >= grid_height:
		push_error("[GridOn] 범위 초과: (%d, %d)" % [x, y])
		return 0
	
	return grid[x][y]

## 월드 좌표를 grid 인덱스로 변환
## @param world_pos: 월드 좌표 (Vector3)
## @return: 그리드 인덱스 (Vector2i)
func world_to_grid_index(world_pos: Vector3) -> Vector2i:
	# 월드 좌표를 그리드 인덱스로 변환 (중앙을 원점으로)
	var grid_x = int(floor(world_pos.x)) + int(grid_width / 2)
	var grid_y = int(floor(world_pos.z)) + int(grid_height / 2)
	
	return Vector2i(grid_x, grid_y)

## 그리드 인덱스를 월드 좌표로 변환
## @param grid_x: X 그리드 인덱스
## @param grid_y: Y 그리드 인덱스
## @return: 월드 좌표 (Vector3)
func grid_index_to_world(grid_x: int, grid_y: int) -> Vector3:
	# 그리드 인덱스를 월드 좌표로 변환 (중앙을 원점으로)
	var world_x = float(grid_x - int(grid_width / 2))
	var world_z = float(grid_y - int(grid_height / 2))
	
	return Vector3(world_x, 0, world_z)

## 특정 영역의 지형 타입 일괄 설정
## @param start_x: 시작 X 좌표
## @param start_y: 시작 Y 좌표
## @param width: 너비
## @param height: 높이
## @param terrain_type: 지형 타입
func set_terrain_area(start_x: int, start_y: int, width: int, height: int, terrain_type: int):
	for x in range(start_x, start_x + width):
		for y in range(start_y, start_y + height):
			set_terrain(x, y, terrain_type)

## 디버그: 특정 영역의 지형 출력
## @param center_x: 중심 X 좌표
## @param center_y: 중심 Y 좌표
## @param radius: 반경
func print_terrain_area(center_x: int, center_y: int, radius: int):
	print("\n=== 지형 정보 (중심: %d, %d, 반경: %d) ===" % [center_x, center_y, radius])
	for y in range(center_y - radius, center_y + radius + 1):
		var line = ""
		for x in range(center_x - radius, center_x + radius + 1):
			var terrain = get_terrain(x, y)
			line += str(terrain) + " "
		print(line)
	print("================\n")

## 랜덤 지형 생성 (Voronoi 기반)
func generate_random_terrain():
	if debug_mode:
		print("[GridOn] Voronoi 기반 지형 생성 시작...")
	
	# Progress Bar 표시
	var progress_ui = get_tree().root.get_node_or_null("map_make_progress")
	if progress_ui and progress_ui.has_method("show_progress"):
		progress_ui.show_progress()
	
	# 맵 크기 업데이트
	update_grid_size()
	
	# 랜덤 맵 생성기 생성
	var map_generator = RandomMapGenerator.new()
	map_generator.map_size = map_size
	map_generator.debug_mode = debug_mode
	
	# 진행 상황 시그널 연결
	if progress_ui:
		map_generator.map_generation_progress.connect(func(progress: float, status: String):
			if progress_ui.has_method("update_progress"):
				progress_ui.update_progress(progress, status)
		)
	
	# 랜덤 맵 생성 (일반 모드에서는 시간이 걸림)
	var start_time = Time.get_ticks_msec()
	var random_map = map_generator.generate_random_map()
	var elapsed_time = (Time.get_ticks_msec() - start_time) / 1000.0
	
	print("⏱️ 맵 생성 완료: %.2f초 소요 (크기: %dx%d)" % [elapsed_time, map_generator.map_width, map_generator.map_height])
	
	# 생성된 맵을 grid에 복사
	grid = random_map
	
	# 그리드 크기도 업데이트
	grid_width = map_generator.map_width
	grid_height = map_generator.map_height
	
	# Progress Bar 숨기기 (일반 모드에서는 더 오래 표시)
	if progress_ui and progress_ui.has_method("hide_progress"):
		var min_display_time = 2.0 if not debug_mode else 0.5
		# 생성 시간이 짧으면 최소 표시 시간만큼 대기
		if elapsed_time < min_display_time:
			await get_tree().create_timer(min_display_time - elapsed_time).timeout
		else:
			await get_tree().create_timer(0.5).timeout
		progress_ui.hide_progress()
	
	if debug_mode:
		print("[GridOn] Voronoi 기반 지형 생성 완료!")


## 맵 크기에 따라 그리드 크기 업데이트 (최적화됨)
func update_grid_size():
	match map_size:
		MapSize.SMALL:
			grid_width = 60
			grid_height = 60
		MapSize.MEDIUM:
			grid_width = 90
			grid_height = 90
		MapSize.LARGE:
			grid_width = 120
			grid_height = 120

## 테스트용 지형 데이터 설정
## 실제 게임에서는 다른 방식으로 지형 데이터를 설정할 수 있음
func setup_test_terrain():
	if debug_mode:
		print("[GridOn] 테스트 지형 데이터 설정 시작...")
	
	# 전체 영역을 grass로 설정
	set_terrain_area(0, 0, grid_width, grid_height, 1)  # 1 = grass
	
	# 중앙 일부 영역을 dirt로 설정
	var center_x = grid_width / 2 - 2
	var center_y = grid_height / 2 - 2
	set_terrain_area(center_x, center_y, 4, 4, 2)  # 2 = dirt
	
	# 모래 영역 추가
	set_terrain_area(grid_width - 5, grid_height - 5, 3, 3, 3)  # 3 = sand
	
	if debug_mode:
		print("[GridOn] 테스트 지형 데이터 설정 완료")

## 2차원 배열을 순회하여 지형별로 obsticle 스폰
## @param parent_node: obsticle을 스폰할 부모 노드 (main 씬)
## @param objects_per_tile: 각 타일당 스폰할 오브젝트 개수
func spawn_trees_on_grass(parent_node: Node, objects_per_tile: int = 3):
	if spawned:
		if debug_mode:
			print("[GridOn] 이미 obsticle 스폰 완료됨. 건너뜀.")
		return
	
	if not tree_resource or not stone_resource:
		push_error("[GridOn] 리소스가 로드되지 않았습니다!")
		return
	
	if not parent_node:
		push_error("[GridOn] 부모 노드가 null입니다!")
		return
	
	if debug_mode:
		print("[GridOn] 지형별 obsticle 스폰 시작...")
	
	var grass_count = 0
	var dirt_count = 0
	var sand_count = 0
	var tree_count = 0
	var stone_count = 0
	
	# 2차원 배열을 순회
	for x in range(grid_width):
		for y in range(grid_height):
			var terrain_type = grid[x][y]
			var world_pos = grid_index_to_world(x, y)
			
			# grass 타일 (ID: 1): 나무 많이 스폰 (70% 나무, 30% 돌)
			if terrain_type == 1:
				grass_count += 1
				for i in range(objects_per_tile):
					# 70% 확률로 나무, 30% 확률로 돌
					if randf() < 0.7:
						spawn_obsticle_at_tile(parent_node, world_pos, x, y, tree_resource)
						tree_count += 1
					else:
						spawn_obsticle_at_tile(parent_node, world_pos, x, y, stone_resource)
						stone_count += 1
			
			# dirt 타일 (ID: 2): 돌 위주 스폰 (30% 나무, 70% 돌)
			elif terrain_type == 2:
				dirt_count += 1
				for i in range(objects_per_tile):
					# 30% 확률로 나무, 70% 확률로 돌
					if randf() < 0.3:
						spawn_obsticle_at_tile(parent_node, world_pos, x, y, tree_resource)
						tree_count += 1
					else:
						spawn_obsticle_at_tile(parent_node, world_pos, x, y, stone_resource)
						stone_count += 1
			
			# sand 타일 (ID: 3): 돌만 스폰
			elif terrain_type == 3:
				sand_count += 1
				for i in range(objects_per_tile):
					spawn_obsticle_at_tile(parent_node, world_pos, x, y, stone_resource)
					stone_count += 1
	
	spawned = true
	
	if debug_mode:
		print("[GridOn] obsticle 스폰 완료!")
		print("  - grass 타일 개수: %d" % grass_count)
		print("  - dirt 타일 개수: %d" % dirt_count)
		print("  - sand 타일 개수: %d" % sand_count)
		print("  - 스폰된 나무 개수: %d" % tree_count)
		print("  - 스폰된 돌 개수: %d" % stone_count)

## 특정 타일 위치에 obsticle 스폰
## @param parent_node: 부모 노드
## @param tile_world_pos: 타일의 월드 좌표 (중심)
## @param _grid_x: 그리드 X 인덱스 (미사용)
## @param _grid_y: 그리드 Y 인덱스 (미사용)
## @param obsticle_resource: 스폰할 obsticle 리소스
func spawn_obsticle_at_tile(parent_node: Node, tile_world_pos: Vector3, _grid_x: int, _grid_y: int, obsticle_resource: obsticle):
	# 타일 크기 (1x1)
	var tile_size = Vector3(1.0, 1.0, 1.0)
	
	# 타일 내부의 랜덤 위치 계산 (경계에서 10% 떨어진 범위)
	var random_pos = get_random_position_in_tile(tile_world_pos, tile_size)
	
	# obsticle 인스턴스 생성
	var obsticle_instance = OBSTICLE_SCENE.instantiate()
	obsticle_instance.thing = obsticle_resource
	
	# 씬 트리에 추가
	parent_node.add_child(obsticle_instance)
	
	# 위치 설정 (ITEM 소환과 동일하게 Y축 조정 없음)
	obsticle_instance.global_position = random_pos
	
	# ObstacleGrid에 등록
	register_to_obstacle_grid(parent_node, obsticle_instance, random_pos)

## 타일 내부의 랜덤 위치 계산
## @param tile_center: 타일 중심 위치 (월드 좌표)
## @param tile_size: 타일 크기
## @return: 랜덤 월드 좌표
func get_random_position_in_tile(tile_center: Vector3, tile_size: Vector3) -> Vector3:
	# 타일 크기의 80% 범위 내에서 랜덤 위치 생성 (경계에서 약간 떨어지게)
	var margin = 0.1
	var half_size = tile_size * 0.5 * (1.0 - margin)
	
	var random_offset = Vector3(
		randf_range(-half_size.x, half_size.x),
		0,  # Y는 0으로 유지 (지면 높이)
		randf_range(-half_size.z, half_size.z)
	)
	
	return tile_center + random_offset

## ObstacleGrid에 obsticle 등록
## @param parent_node: 부모 노드 (main 씬)
## @param obsticle_node: obsticle 노드
## @param world_pos: 월드 좌표
func register_to_obstacle_grid(parent_node: Node, obsticle_node: Node3D, world_pos: Vector3):
	# ObstacleGrid 찾기
	var obstacle_grid = parent_node.get_node_or_null("ObstacleGrid")
	if not obstacle_grid:
		if debug_mode:
			print("[GridOn] 경고: ObstacleGrid를 찾을 수 없습니다!")
		return
	
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
