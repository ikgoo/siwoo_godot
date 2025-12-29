extends Node
class_name ChunkSpawner

## 청크 기반 Obsticle 지연 로딩 시스템
## 캐릭터가 근처에 가면 obsticle을 생성

## 청크 크기 (타일 단위)
@export var chunk_size: int = 10

## 로딩 범위 (청크 단위) - 캐릭터 주변 이 범위만 obsticle 생성
@export var load_range: int = 2  # 캐릭터 주변 2칸 청크 (약 20x20 타일)

## 언로딩 범위 (청크 단위) - 이 거리 이상 멀어지면 완전히 제거
@export var unload_range: int = 4  # 4칸 이상 멀어지면 완전히 제거 (메모리에서도 삭제)

## 프레임당 최대 생성 개수 (렉 방지)
@export var max_spawns_per_frame: int = 10

## obsticle 씬
const OBSTICLE_SCENE = preload("res://obsticle.tscn")

## GridMap 참조
var grid_map: GridMap = null

## 캐릭터 참조
var character: Node3D = null

## 로드된 청크 (청크 좌표 -> 생성된 obsticle 배열)
var loaded_chunks: Dictionary = {}

## 로딩 중인 청크 (청크 좌표 -> 빈 배열로 예약)
var loading_chunks: Dictionary = {}

## 청크별 스폰 데이터 (청크 좌표 -> 스폰 정보 배열)
var chunk_spawn_data: Dictionary = {}

## 이전 캐릭터 청크 위치
var previous_character_chunk: Vector2i = Vector2i(-9999, -9999)

## 로딩 큐 (로드할 청크들의 대기열)
var loading_queue: Array[Vector2i] = []

## 현재 로딩 중인 청크와 인덱스
var current_loading_chunk: Vector2i = Vector2i(-9999, -9999)
var current_spawn_index: int = 0

## 디버그 모드
@export var debug_mode: bool = false


func _ready():
	# GridMap 찾기
	grid_map = get_node_or_null("../Node3D2/GridMap")
	if not grid_map:
		push_error("[ChunkSpawner] GridMap을 찾을 수 없습니다!")
		return
	
	# 캐릭터 찾기
	character = get_node_or_null("../CharacterBody3D")
	if not character:
		push_error("[ChunkSpawner] 캐릭터를 찾을 수 없습니다!")
		return
	
	if debug_mode:
		print("[ChunkSpawner] 초기화 완료 - 청크 크기: %d, 로딩 범위: %d" % [chunk_size, load_range])


func _process(_delta):
	if not character or not grid_map:
		return
	
	# 캐릭터의 현재 청크 위치
	var character_chunk = world_to_chunk(character.global_position)
	
	# 청크가 변경되었을 때만 처리
	if character_chunk != previous_character_chunk:
		update_chunks(character_chunk)
		previous_character_chunk = character_chunk
	
	# 점진적 로딩 처리
	process_loading_queue()


## 월드 좌표를 청크 좌표로 변환
func world_to_chunk(world_pos: Vector3) -> Vector2i:
	var cell_size = grid_map.cell_size.x
	return Vector2i(
		int(floor(world_pos.x / (chunk_size * cell_size))),
		int(floor(world_pos.z / (chunk_size * cell_size)))
	)


## 청크 업데이트 (로드/언로드)
func update_chunks(character_chunk: Vector2i):
	# 로드해야 할 청크들
	var chunks_to_load = []
	for x in range(character_chunk.x - load_range, character_chunk.x + load_range + 1):
		for y in range(character_chunk.y - load_range, character_chunk.y + load_range + 1):
			var chunk_pos = Vector2i(x, y)
			# 로드되지 않았고, 로딩 중도 아니고, 큐에도 없으면 추가
			if not loaded_chunks.has(chunk_pos) and not loading_chunks.has(chunk_pos) and not loading_queue.has(chunk_pos):
				chunks_to_load.append(chunk_pos)
	
	# 언로드해야 할 청크들
	var chunks_to_unload = []
	for chunk_pos in loaded_chunks.keys():
		var distance = character_chunk.distance_to(chunk_pos)
		if distance > unload_range:
			chunks_to_unload.append(chunk_pos)
	
	# 청크를 로딩 큐에 추가 (거리순으로 정렬)
	chunks_to_load.sort_custom(func(a, b): return character_chunk.distance_to(a) < character_chunk.distance_to(b))
	for chunk_pos in chunks_to_load:
		loading_queue.append(chunk_pos)
		loading_chunks[chunk_pos] = []  # 예약 표시
	
	# 청크 언로드 (즉시 처리)
	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)
	
	if debug_mode and (chunks_to_load.size() > 0 or chunks_to_unload.size() > 0):
		print("[ChunkSpawner] 큐 추가: %d, 언로드: %d, 총 청크: %d, 큐 대기: %d" % [chunks_to_load.size(), chunks_to_unload.size(), loaded_chunks.size(), loading_queue.size()])


## 점진적 로딩 처리 (매 프레임마다 일부만 생성)
func process_loading_queue():
	if loading_queue.is_empty():
		current_loading_chunk = Vector2i(-9999, -9999)
		current_spawn_index = 0
		return
	
	# 현재 로딩 중인 청크가 없으면 큐에서 가져오기
	if current_loading_chunk == Vector2i(-9999, -9999):
		current_loading_chunk = loading_queue.pop_front()
		current_spawn_index = 0
		
		# 스폰 데이터가 없으면 생성
		if not chunk_spawn_data.has(current_loading_chunk):
			generate_chunk_spawn_data(current_loading_chunk)
		
		if debug_mode:
			print("  🔄 청크 로딩 시작: %s (%d개 obsticle)" % [current_loading_chunk, chunk_spawn_data[current_loading_chunk].size()])
	
	# 현재 청크의 스폰 데이터
	var spawn_data = chunk_spawn_data[current_loading_chunk]
	var spawned_obsticles = loading_chunks[current_loading_chunk]
	
	# 이번 프레임에 생성할 개수
	var spawns_this_frame = 0
	while current_spawn_index < spawn_data.size() and spawns_this_frame < max_spawns_per_frame:
		var data = spawn_data[current_spawn_index]
		
		var obsticle_instance = OBSTICLE_SCENE.instantiate()
		obsticle_instance.thing = data.resource
		
		# 부모 노드에 추가
		get_parent().add_child(obsticle_instance)
		
		# 위치 설정
		obsticle_instance.global_position = data.position
		
		# ObstacleGrid에 등록
		register_to_obstacle_grid(obsticle_instance, data.position)
		
		spawned_obsticles.append(obsticle_instance)
		
		current_spawn_index += 1
		spawns_this_frame += 1
	
	# 현재 청크 로딩 완료
	if current_spawn_index >= spawn_data.size():
		loaded_chunks[current_loading_chunk] = spawned_obsticles
		loading_chunks.erase(current_loading_chunk)
		
		if debug_mode:
			print("  ✅ 청크 로드 완료: %s (%d개 obsticle)" % [current_loading_chunk, spawned_obsticles.size()])
		
		current_loading_chunk = Vector2i(-9999, -9999)
		current_spawn_index = 0


## 청크 언로드 (obsticle 완전히 제거)
func unload_chunk(chunk_pos: Vector2i):
	# 로딩 큐에서 제거
	if loading_queue.has(chunk_pos):
		loading_queue.erase(chunk_pos)
	
	# 로딩 중이면 취소
	if loading_chunks.has(chunk_pos):
		var obsticles = loading_chunks[chunk_pos]
		for obs_node in obsticles:
			if is_instance_valid(obs_node):
				unregister_from_obstacle_grid(obs_node)
				obs_node.queue_free()
		loading_chunks.erase(chunk_pos)
		
		# 현재 로딩 중인 청크라면 초기화
		if current_loading_chunk == chunk_pos:
			current_loading_chunk = Vector2i(-9999, -9999)
			current_spawn_index = 0
	
	# 로드 완료된 청크 제거
	if loaded_chunks.has(chunk_pos):
		var obsticles = loaded_chunks[chunk_pos]
		
		# obsticle 완전히 제거 (메모리에서도 삭제)
		for obs_node in obsticles:
			if is_instance_valid(obs_node):
				# ObstacleGrid에서도 제거
				unregister_from_obstacle_grid(obs_node)
				# 노드 제거
				obs_node.queue_free()
		
		# 청크 데이터에서 제거
		loaded_chunks.erase(chunk_pos)
		
		if debug_mode:
			print("  ❌ 청크 언로드: %s (%d개 obsticle 완전히 제거)" % [chunk_pos, obsticles.size()])


## 청크의 스폰 데이터 생성
func generate_chunk_spawn_data(chunk_pos: Vector2i):
	var spawn_data = []
	var cell_size = grid_map.cell_size.x
	
	# 청크 내의 모든 타일 순회
	for local_x in range(chunk_size):
		for local_y in range(chunk_size):
			# 월드 좌표 계산
			var world_x = (chunk_pos.x * chunk_size + local_x) * cell_size
			var world_z = (chunk_pos.y * chunk_size + local_y) * cell_size
			
			# GridMap 셀 좌표
			var cell_pos = Vector3i(
				chunk_pos.x * chunk_size + local_x,
				0,
				chunk_pos.y * chunk_size + local_y
			)
			
			# 타일 ID 가져오기
			var tile_id = grid_map.get_cell_item(cell_pos)
			if tile_id == GridMap.INVALID_CELL_ITEM:
				continue
			
			# 지형 타입 가져오기
			var terrain_type = TileSpawnConfig.get_terrain_type(tile_id)
			
			# 나무 개수
			var tree_count = TileSpawnConfig.get_random_tree_count_by_terrain(terrain_type)
			for i in range(tree_count):
				var tree_resource = TileSpawnConfig.get_object_by_terrain(terrain_type, true)
				if tree_resource:
					var pos = get_random_position_in_cell(Vector3(world_x, 0, world_z), cell_size)
					spawn_data.append({
						"resource": tree_resource,
						"position": pos
					})
			
			# 돌 개수
			var stone_count = TileSpawnConfig.get_random_stone_count_by_terrain(terrain_type)
			for i in range(stone_count):
				var stone_resource = TileSpawnConfig.get_object_by_terrain(terrain_type, false)
				if stone_resource:
					var pos = get_random_position_in_cell(Vector3(world_x, 0, world_z), cell_size)
					spawn_data.append({
						"resource": stone_resource,
						"position": pos
					})
	
	chunk_spawn_data[chunk_pos] = spawn_data


## 셀 내부의 랜덤 위치
func get_random_position_in_cell(cell_center: Vector3, cell_size: float) -> Vector3:
	var margin = 0.1
	var half_size = cell_size * 0.5 * (1.0 - margin)
	
	return cell_center + Vector3(
		randf_range(-half_size, half_size),
		0.05,
		randf_range(-half_size, half_size)
	)


## ObstacleGrid에 등록
func register_to_obstacle_grid(obsticle_node: Node3D, world_pos: Vector3):
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var obsticle_data = obsticle_node.thing
	
	if not obsticle_data:
		return
	
	var grid_width_tiles = obsticle_data.grid_width if "grid_width" in obsticle_data else 3
	var grid_height_tiles = obsticle_data.grid_height if "grid_height" in obsticle_data else 3
	
	var center_grid_pos = obstacle_grid.world_to_grid(world_pos)
	obstacle_grid.register_obstacle_area(center_grid_pos, grid_width_tiles, grid_height_tiles)


## ObstacleGrid에서 제거
func unregister_from_obstacle_grid(obsticle_node: Node3D):
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var obsticle_data = obsticle_node.thing
	
	if not obsticle_data:
		return
	
	var world_pos = obsticle_node.global_position
	var grid_width_tiles = obsticle_data.grid_width if "grid_width" in obsticle_data else 3
	var grid_height_tiles = obsticle_data.grid_height if "grid_height" in obsticle_data else 3
	
	var center_grid_pos = obstacle_grid.world_to_grid(world_pos)
	
	# ObstacleGrid에서 해당 영역 클리어
	for x in range(-int(grid_width_tiles/2), int(grid_width_tiles/2) + 1):
		for z in range(-int(grid_height_tiles/2), int(grid_height_tiles/2) + 1):
			var grid_pos = center_grid_pos + Vector3i(x, 0, z)
			if obstacle_grid.has_method("clear_cell"):
				obstacle_grid.clear_cell(grid_pos)


## 모든 청크 데이터 미리 생성 (게임 시작 시 호출)
func pregenerate_all_chunk_data():
	if not grid_map:
		return
	
	var start_time = Time.get_ticks_msec()
	
	# GridMap의 범위 계산
	var used_cells = grid_map.get_used_cells()
	if used_cells.size() == 0:
		return
	
	var min_x = INF
	var max_x = -INF
	var min_z = INF
	var max_z = -INF
	
	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_z = min(min_z, cell.z)
		max_z = max(max_z, cell.z)
	
	# 청크 범위 계산
	var min_chunk_x = int(floor(float(min_x) / chunk_size))
	var max_chunk_x = int(floor(float(max_x) / chunk_size))
	var min_chunk_y = int(floor(float(min_z) / chunk_size))
	var max_chunk_y = int(floor(float(max_z) / chunk_size))
	
	# 모든 청크 데이터 생성
	var total_chunks = 0
	for chunk_x in range(min_chunk_x, max_chunk_x + 1):
		for chunk_y in range(min_chunk_y, max_chunk_y + 1):
			var chunk_pos = Vector2i(chunk_x, chunk_y)
			generate_chunk_spawn_data(chunk_pos)
			total_chunks += 1
	
	var elapsed_time = Time.get_ticks_msec() - start_time
	
	if debug_mode:
		print("[ChunkSpawner] 모든 청크 데이터 생성 완료: %d개 청크, %.2f초" % [total_chunks, elapsed_time / 1000.0])
