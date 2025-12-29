extends Node
class_name TileSpawnConfig

## 지형별 스폰 설정을 관리하는 클래스
## 각 지형 타입에 대해 스폰 설정을 정의

## 지형별 스폰 설정 클래스
class SpawnSetting:
	var terrain_type: Globals.global_tiles  ## 지형 타입
	var tree_min: int  ## 최소 나무 개수
	var tree_max: int  ## 최대 나무 개수
	var stone_min: int  ## 최소 돌 개수
	var stone_max: int  ## 최대 돌 개수
	var spawn_objects: Array[obsticle]  ## 스폰 가능한 오브젝트 목록
	var min_spawn_distance: float  ## 오브젝트 간 최소 거리
	
	func _init(
		p_terrain_type: Globals.global_tiles,
		p_tree_min: int,
		p_tree_max: int,
		p_stone_min: int,
		p_stone_max: int,
		p_objects: Array[obsticle] = [],
		p_min_distance: float = 0.5
	):
		terrain_type = p_terrain_type
		tree_min = p_tree_min
		tree_max = p_tree_max
		stone_min = p_stone_min
		stone_max = p_stone_max
		spawn_objects = p_objects
		min_spawn_distance = p_min_distance


## 지형 타입별 스폰 설정 딕셔너리
static var terrain_settings: Dictionary = {}

## 타일 인덱스 -> 지형 타입 매핑 (기본값)
static var tile_to_terrain: Dictionary = {}

## 셀 위치 -> 지형 타입 매핑 (각 타일마다 개별 지형)
static var cell_to_terrain: Dictionary = {}


## 초기화 - 모든 지형 설정 등록
static func initialize() -> void:
	# 오브젝트 리소스 로드
	var tree = load("res://obsticle/obsticles/tree.tres") as obsticle
	var stone = load("res://obsticle/obsticles/stone.tres") as obsticle
	
	# === 지형별 스폰 설정 ===
	
	# 초원 지형 (grass): 나무 0~3개, 돌 0~1개
	terrain_settings[Globals.global_tiles.GRASS] = SpawnSetting.new(
		Globals.global_tiles.GRASS,
		0,  # 나무 최소 0개
		3,  # 나무 최대 3개
		0,  # 돌 최소 0개
		1,  # 돌 최대 1개
		[tree, stone],
		0.5  # 최소 거리 0.5 유닛
	)
	
	# 흙 지형 (dirt): 나무 0~2개, 돌 0~1개
	terrain_settings[Globals.global_tiles.DIRT] = SpawnSetting.new(
		Globals.global_tiles.DIRT,
		0,  # 나무 최소 0개
		2,  # 나무 최대 2개
		0,  # 돌 최소 0개
		1,  # 돌 최대 1개
		[tree, stone],
		0.5
	)
	
	# 모래 지형 (sand): 나무 0~1개, 돌 0~1개
	terrain_settings[Globals.global_tiles.SAND] = SpawnSetting.new(
		Globals.global_tiles.SAND,
		0,  # 나무 최소 0개
		1,  # 나무 최대 1개
		0,  # 돌 최소 0개
		1,  # 돌 최대 1개
		[tree, stone],
		0.5
	)
	
	# 돌 지형 (stone): 나무 0개, 돌 0개 (미사용)
	terrain_settings[Globals.global_tiles.STONE] = SpawnSetting.new(
		Globals.global_tiles.STONE,
		0,  # 나무 없음
		0,
		0,  # 돌 없음
		0,
		[],
		0.5
	)
	
	# 눈 지형 (snow): 나무 0개, 돌 0개 (미사용)
	terrain_settings[Globals.global_tiles.SNOW] = SpawnSetting.new(
		Globals.global_tiles.SNOW,
		0,  # 나무 없음
		0,
		0,  # 돌 없음
		0,
		[],
		0.5
	)
	
	# 아무것도 없음 (nothing): 스폰 없음
	terrain_settings[Globals.global_tiles.NOTHING] = SpawnSetting.new(
		Globals.global_tiles.NOTHING,
		0,  # 나무 없음
		0,
		0,  # 돌 없음
		0,
		[],
		0.5
	)
	
	# 바다 (sea): 스폰 없음
	terrain_settings[Globals.global_tiles.SEA] = SpawnSetting.new(
		Globals.global_tiles.SEA,
		0,  # 나무 없음
		0,
		0,  # 돌 없음
		0,
		[],
		0.5
	)
	
	# 해변 (shore): 나무 0~1개, 돌 0개
	terrain_settings[Globals.global_tiles.SHORE] = SpawnSetting.new(
		Globals.global_tiles.SHORE,
		0,  # 나무 최소 0개
		1,  # 나무 최대 1개
		0,  # 돌 없음
		0,
		[tree],
		0.5
	)
	
	# === 타일 인덱스 -> 지형 타입 매핑 ===
	# GridMap의 실제 타일 인덱스에 맞춰 매핑
	tile_to_terrain[0] = Globals.global_tiles.GRASS    # 타일 0 = MeshInstance3D (풀)
	tile_to_terrain[1] = Globals.global_tiles.GRASS    # 타일 1 = grass (풀) - 나무 0~3개, 돌 0~1개
	tile_to_terrain[2] = Globals.global_tiles.DIRT     # 타일 2 = dirt (흙) - 나무 0~2개, 돌 0~1개
	tile_to_terrain[3] = Globals.global_tiles.SAND     # 타일 3 = sand (모래) - 나무 0~1개, 돌 0~1개
	tile_to_terrain[4] = Globals.global_tiles.NOTHING  # 타일 4 = nothing (아무것도 안 나옴)
	tile_to_terrain[5] = Globals.global_tiles.SEA      # 타일 5 = sea (바다, 아무것도 안 나옴)
	tile_to_terrain[6] = Globals.global_tiles.SHORE    # 타일 6 = Shore (해변) - 나무 0~1개, 돌 0개
	tile_to_terrain[7] = Globals.global_tiles.SHORE    # 타일 7 = shore_underwater (물속 해변) - 나무 0~1개, 돌 0개


## 특정 지형 타입의 스폰 설정 가져오기
## terrain_type: 지형 타입 enum
## 반환값: SpawnSetting 또는 null
static func get_terrain_setting(terrain_type: Globals.global_tiles) -> SpawnSetting:
	if terrain_settings.is_empty():
		initialize()
	
	if terrain_settings.has(terrain_type):
		return terrain_settings[terrain_type]
	
	return null


## 특정 타일 인덱스의 지형 타입 가져오기
## tile_index: GridMap 타일 인덱스
## 반환값: 지형 타입 enum 또는 null
static func get_terrain_type(tile_index: int) -> Globals.global_tiles:
	if tile_to_terrain.is_empty():
		initialize()
	
	if tile_to_terrain.has(tile_index):
		return tile_to_terrain[tile_index]
	
	return Globals.global_tiles.GRASS  # 기본값


## 특정 타일 인덱스의 스폰 설정 가져오기
## tile_index: GridMap 타일 인덱스
## 반환값: SpawnSetting 또는 null
static func get_setting(tile_index: int) -> SpawnSetting:
	var terrain_type = get_terrain_type(tile_index)
	return get_terrain_setting(terrain_type)


## 특정 지형에 스폰할 나무 개수 랜덤 결정
## terrain_type: 지형 타입
## 반환값: 나무 스폰 개수
static func get_random_tree_count_by_terrain(terrain_type: Globals.global_tiles) -> int:
	var setting = get_terrain_setting(terrain_type)
	if setting == null:
		return 0
	
	return randi_range(setting.tree_min, setting.tree_max)


## 특정 지형에 스폰할 돌 개수 랜덤 결정
## terrain_type: 지형 타입
## 반환값: 돌 스폰 개수
static func get_random_stone_count_by_terrain(terrain_type: Globals.global_tiles) -> int:
	var setting = get_terrain_setting(terrain_type)
	if setting == null:
		return 0
	
	return randi_range(setting.stone_min, setting.stone_max)


## 특정 타일에 스폰할 나무 개수 랜덤 결정
## tile_index: GridMap 타일 인덱스
## 반환값: 나무 스폰 개수
static func get_random_tree_count(tile_index: int) -> int:
	var terrain_type = get_terrain_type(tile_index)
	return get_random_tree_count_by_terrain(terrain_type)


## 특정 타일에 스폰할 돌 개수 랜덤 결정
## tile_index: GridMap 타일 인덱스
## 반환값: 돌 스폰 개수
static func get_random_stone_count(tile_index: int) -> int:
	var terrain_type = get_terrain_type(tile_index)
	return get_random_stone_count_by_terrain(terrain_type)


## 나무 또는 돌 오브젝트 가져오기
## terrain_type: 지형 타입
## is_tree: true면 나무, false면 돌
## 반환값: obsticle 리소스
static func get_object_by_terrain(terrain_type: Globals.global_tiles, is_tree: bool) -> obsticle:
	var setting = get_terrain_setting(terrain_type)
	if setting == null or setting.spawn_objects.is_empty():
		return null
	
	# 오브젝트 목록에서 나무 또는 돌 찾기
	for obj in setting.spawn_objects:
		if obj:
			var obj_name = obj.name.to_lower()
			if is_tree and ("tree" in obj_name or "나무" in obj_name):
				return obj
			elif not is_tree and ("stone" in obj_name or "돌" in obj_name or "rock" in obj_name):
				return obj
	
	# 못 찾으면 첫 번째 오브젝트 반환
	return setting.spawn_objects[0]


## 나무 또는 돌 오브젝트 가져오기
## tile_index: 타일 인덱스
## is_tree: true면 나무, false면 돌
## 반환값: obsticle 리소스
static func get_object(tile_index: int, is_tree: bool) -> obsticle:
	var terrain_type = get_terrain_type(tile_index)
	return get_object_by_terrain(terrain_type, is_tree)


## 타일 인덱스에 지형 타입 설정 (기본값용)
## tile_index: GridMap 타일 인덱스
## terrain_type: 지형 타입
static func set_tile_terrain(tile_index: int, terrain_type: Globals.global_tiles) -> void:
	if terrain_settings.is_empty():
		initialize()
	
	tile_to_terrain[tile_index] = terrain_type


## 특정 셀 위치에 지형 타입 설정 (개별 타일용)
## cell_pos: GridMap 셀 위치 (Vector3i)
## terrain_type: 지형 타입
static func set_cell_terrain(cell_pos: Vector3i, terrain_type: Globals.global_tiles) -> void:
	if terrain_settings.is_empty():
		initialize()
	
	cell_to_terrain[cell_pos] = terrain_type


## 특정 셀 위치의 지형 타입 가져오기
## cell_pos: GridMap 셀 위치 (Vector3i)
## 반환값: 지형 타입 또는 null
static func get_cell_terrain(cell_pos: Vector3i) -> Globals.global_tiles:
	if cell_to_terrain.has(cell_pos):
		return cell_to_terrain[cell_pos]
	
	return Globals.global_tiles.GRASS  # 기본값


## 모든 설정 출력 (디버깅용)
static func print_all_settings() -> void:
	pass
