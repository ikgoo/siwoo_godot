extends Node
class_name GridMapSpawner

## GridMap의 각 타일에 확률에 따라 오브젝트를 스폰하는 클래스
## 게임 시작 시 딱 한 번만 실행되어 초기 지형을 구성합니다.

## obsticle 씬 프리로드
const OBSTICLE_SCENE = preload("res://obsticle.tscn")

## 디버그 모드
@export var debug_mode: bool = false

## 스폰된 오브젝트 총 개수
var total_spawned: int = 0

## 타일별 스폰 통계
var spawn_stats: Dictionary = {}

## 스폰 완료 플래그 (중복 실행 방지)
var spawned: bool = false


## 씬이 준비되면 자동으로 스폰 실행 (딱 한 번만)
func _ready():
	# 이미 스폰되었으면 실행하지 않음
	if spawned:
		return
	
	# GridMap 자식 노드 찾기
	var gridmap_node = get_node_or_null("GridMap")
	if not gridmap_node:
		return
	
	# 부모 노드 (main 씬)에 오브젝트 스폰
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# 오브젝트 스폰 실행 (확률 기반)
	spawn_all_tiles(gridmap_node, parent_node)
	
	# 스폰 완료 플래그 설정
	spawned = true


## GridMap의 각 타일에 확률에 따라 오브젝트 스폰
## 각 타일마다 설정된 확률(min~max)에 따라 나무와 돌을 랜덤 배치
## grid_map: 대상 GridMap
## parent_node: 스폰된 오브젝트의 부모 노드
func spawn_all_tiles(grid_map: Node, parent_node: Node = null) -> void:
	# GridMap 타입 체크
	if not grid_map:
		push_error("[GridMapSpawner] GridMap이 null입니다!")
		return
	
	if not grid_map is GridMap:
		push_error("[GridMapSpawner] 전달된 노드가 GridMap이 아닙니다! (타입: %s)" % grid_map.get_class())
		return
	
	# 부모 노드 설정
	if parent_node == null:
		parent_node = grid_map.get_parent()
	
	if parent_node == null:
		push_error("[GridMapSpawner] 부모 노드를 찾을 수 없습니다!")
		return
	
	# 초기화
	total_spawned = 0
	spawn_stats.clear()
	
	# TileSpawnConfig 초기화
	TileSpawnConfig.initialize()
	
	# GridMap의 모든 사용된 셀 가져오기
	var used_cells = grid_map.get_used_cells()
	
	# 타일 인덱스별로 셀 그룹화
	var cells_by_tile: Dictionary = {}
	for cell_pos in used_cells:
		var tile_index = grid_map.get_cell_item(cell_pos)
		if tile_index != GridMap.INVALID_CELL_ITEM:
			if not cells_by_tile.has(tile_index):
				cells_by_tile[tile_index] = []
			cells_by_tile[tile_index].append(cell_pos)
	
	# 각 타일 타입별로 스폰
	for tile_index in cells_by_tile.keys():
		spawn_for_tile_type(grid_map, tile_index, cells_by_tile[tile_index], parent_node)


## 특정 타일 타입의 모든 셀에 확률 기반으로 오브젝트 스폰
## 각 셀마다 설정된 min~max 범위에서 랜덤하게 개수를 결정하여 스폰
## grid_map: GridMap 노드
## tile_index: 타일 인덱스
## cells: 해당 타일의 셀 위치 배열
## parent_node: 부모 노드
func spawn_for_tile_type(grid_map: GridMap, tile_index: int, cells: Array, parent_node: Node) -> void:
	var spawned_count = 0
	var terrain_stats: Dictionary = {}  # 지형별 스폰 통계
	
	# 각 셀마다 개별적으로 확률 기반 스폰
	for cell_pos in cells:
		# 각 셀의 개별 지형 타입 가져오기
		var terrain_type = TileSpawnConfig.get_cell_terrain(cell_pos)
		var setting = TileSpawnConfig.get_terrain_setting(terrain_type)
		
		if setting == null:
			continue
		
		# 지형별 통계 초기화
		if not terrain_stats.has(terrain_type):
			terrain_stats[terrain_type] = 0
		
		# 확률 기반: 해당 지형의 min~max 범위에서 랜덤하게 나무 개수 결정
		var tree_count = TileSpawnConfig.get_random_tree_count_by_terrain(terrain_type)
		# 확률 기반: 해당 지형의 min~max 범위에서 랜덤하게 돌 개수 결정
		var stone_count = TileSpawnConfig.get_random_stone_count_by_terrain(terrain_type)
		
		# 셀의 월드 위치 계산
		var cell_world_pos = grid_map.map_to_local(cell_pos)
		var cell_global_pos = grid_map.to_global(cell_world_pos)
		
		# 나무 스폰
		for i in range(tree_count):
			var tree_obj = TileSpawnConfig.get_object_by_terrain(terrain_type, true)
			if tree_obj:
				var spawn_pos = get_random_position_in_cell(cell_global_pos, grid_map.cell_size)
				spawn_object(tree_obj, spawn_pos, parent_node)
				spawned_count += 1
				terrain_stats[terrain_type] += 1
		
		# 돌 스폰
		for i in range(stone_count):
			var stone_obj = TileSpawnConfig.get_object_by_terrain(terrain_type, false)
			if stone_obj:
				var spawn_pos = get_random_position_in_cell(cell_global_pos, grid_map.cell_size)
				spawn_object(stone_obj, spawn_pos, parent_node)
				spawned_count += 1
				terrain_stats[terrain_type] += 1
	
	# 통계 저장 (타일 인덱스 기준)
	spawn_stats[tile_index] = spawned_count
	total_spawned += spawned_count


## 셀 내부의 랜덤 위치 계산
## cell_center: 셀의 중심 위치 (월드 좌표)
## cell_size: 셀 크기
## 반환값: 랜덤 월드 좌표	
func get_random_position_in_cell(cell_center: Vector3, cell_size: Vector3) -> Vector3:
	# 셀 크기의 80% 범위 내에서 랜덤 위치 생성 (경계에서 약간 떨어지게)
	var margin = 0.1
	var half_size = cell_size * 0.5 * (1.0 - margin)
	
	var random_offset = Vector3(
		randf_range(-half_size.x, half_size.x),
		0,  # Y는 0으로 유지 (지면 높이)
		randf_range(-half_size.z, half_size.z)
	)
	
	return cell_center + random_offset


## 오브젝트 생성 및 배치
## obstacle_data: obsticle 리소스
## position: 스폰 위치
## parent_node: 부모 노드
func spawn_object(obstacle_data: obsticle, position: Vector3, parent_node: Node) -> void:
	if not obstacle_data:
		push_error("[GridMapSpawner] obstacle_data가 null입니다!")
		return
	
	var obstacle_instance = OBSTICLE_SCENE.instantiate()
	
	# thing 설정
	obstacle_instance.thing = obstacle_data
	
	# Y 위치를 약간 올려서 타일 위에 배치
	var adjusted_position = position
	adjusted_position.y += 0.05
	
	# 먼저 씬 트리에 추가
	parent_node.add_child(obstacle_instance)
	
	# 트리에 추가된 후 global_position 설정
	obstacle_instance.global_position = adjusted_position
	
	# ObstacleGrid에 등록
	register_obsticle_to_grid(obstacle_instance, adjusted_position)


## 스폰 통계 출력
func print_spawn_stats() -> void:
	pass


## 총 스폰 개수 반환
func get_total_spawned() -> int:
	return total_spawned

## ObstacleGrid에 obsticle 정보를 등록하는 함수
func register_obsticle_to_grid(obsticle_node: Node3D, world_pos: Vector3):
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
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


## 특정 타일의 스폰 개수 반환
func get_spawned_count(tile_index: int) -> int:
	return spawn_stats.get(tile_index, 0)
