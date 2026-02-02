extends Node2D

## === 맵 활성화 설정 (Inspector에서 체크박스로 제어) ===
@export_group("Map Enable/Disable")

@export var map_1_enabled: bool = true:
	set(value):
		map_1_enabled = value
		if is_node_ready():
			_apply_map_state($map_1, value)

@export var map_2_enabled: bool = true:
	set(value):
		map_2_enabled = value
		if is_node_ready():
			_apply_map_state($map_2, value)

@onready var map_1 = $map_1
@onready var map_2 = $map_2

# map_1 동굴 타일맵
@onready var inside_cave = $map_1/inside_cave
@onready var inside_cave2 = $map_1/inside_cave2
@onready var inside_cave3 = $map_1/inside_cave3
@onready var inside_cave4 = $map_1/inside_cave4
@onready var maps = $map_1/maps  # maps TileMap 참조
@onready var platform = $map_1/platform  # platform TileMap 참조
@onready var background = $map_1/background  # background TileMap 참조
@onready var cave_always = $map_1/cave_always  # 동굴 밖에서만 보이는 타일맵

# map_2 동굴 타일맵
@onready var inside_cave_m2 = $map_2/inside_cave
@onready var inside_cave2_m2 = $map_2/inside_cave2
@onready var inside_cave3_m2 = $map_2/inside_cave3
# 캐릭터 참조 (부모 노드를 통해 접근)
var character: CharacterBody2D

# 모든 inside_cave TileMap들
var cave_tilemaps: Array[TileMap] = []

# === 폭포 애니메이션 관련 변수 ===
var waterfall_tiles: Array[Dictionary] = []
@export var waterfall_speed: float = 0.8  # 초당 프레임 변경 속도
@export var waterfall_animation_enabled: bool = false  # 애니메이션 활성화 여부
var waterfall_time: float = 0.0
const WATERFALL_LAYER: int = 0

# 플랫폼 레이어 인덱스 (platform TileMap의 layer_0)
const PLATFORM_LAYER_INDEX = 0

# 플랫폼 collision layer (2번 비트 = 4)
const PLATFORM_COLLISION_LAYER = 4

# === 플랫폼 타일 조건부 변경 설정 ===
# 플랫폼 타일의 source_id (TileSet에서 mine_clicker-16_platform.png = source 7)
# -1로 설정하면 모든 source의 플랫폼 타일에 적용
@export var platform_source_id: int = 7

# 플랫폼 타일 atlas 좌표 (mine_clicker-16_platform.png 기준)
# (1, 0): 공중용 (아래 블록 없음), (1, 1): 지지대용 (아래 블록 있음)
@export var platform_atlas_no_support: Vector2i = Vector2i(1, 1)  # 아래에 블록 없을 때 (공중용)
@export var platform_atlas_with_support: Vector2i = Vector2i(2, 1)  # 아래에 블록 있을 때 (지지대용)

# 반투명 타일들을 저장하는 별도 레이어 (1번 레이어 사용)
var transparent_layer_index: int = 1  # inside_cave의 두 번째 레이어 사용

# 현재 반투명하게 처리된 타일들의 좌표 (각 TileMap별로 저장)
var current_transparent_tiles: Dictionary = {}  # TileMap -> Array[Vector2i]

# 캐릭터가 이전 프레임에 타일 위에 있었는지 여부 (각 TileMap별로 저장)
var was_character_on_tile: Dictionary = {}  # TileMap -> bool

# 반투명 정도 (0.0 = 완전 투명, 1.0 = 완전 불투명)
var transparency_alpha: float = 0.5  # 반투명

# 타일 정보를 저장하기 위한 Dictionary (복원용, 각 TileMap별로 저장)
var tile_info_cache: Dictionary = {}  # TileMap -> {Vector2i -> {source_id, atlas_coords, alternative_tile}}

# cave_always 타일맵 표시 여부 (동굴 안에 있는지 추적)
var is_in_any_cave: bool = false

func _ready():
	# tile_map_manager 그룹에 추가 (breakable_tile에서 찾을 수 있도록)
	add_to_group("tile_map_manager")
	
	# 부모 노드(main)에서 캐릭터 찾기
	var parent = get_parent()
	if parent:
		character = parent.get_node_or_null("character")
	
	# 모든 inside_cave TileMap들을 배열에 추가 (map_1)
	if inside_cave:
		cave_tilemaps.append(inside_cave)
	if inside_cave2:
		cave_tilemaps.append(inside_cave2)
	if inside_cave3:
		cave_tilemaps.append(inside_cave3)
	if inside_cave4:
		cave_tilemaps.append(inside_cave4)
	
	# map_2의 inside_cave들도 추가
	if inside_cave_m2:
		cave_tilemaps.append(inside_cave_m2)
	if inside_cave2_m2:
		cave_tilemaps.append(inside_cave2_m2)
	if inside_cave3_m2:
		cave_tilemaps.append(inside_cave3_m2)
	
	# 각 TileMap 초기화
	for cave in cave_tilemaps:
		# 두 번째 레이어가 없으면 생성
		if cave.get_layers_count() <= transparent_layer_index:
			cave.add_layer(transparent_layer_index)
		
		# 두 번째 레이어를 반투명하게 설정
		cave.set_layer_modulate(transparent_layer_index, Color(1.0, 1.0, 1.0, transparency_alpha))
		
		# 초기화
		current_transparent_tiles[cave] = []
		was_character_on_tile[cave] = false
		tile_info_cache[cave] = {}
	
	# 플랫폼 타일들의 Physics Layer 설정 확인
	check_platform_tiles_physics_layers()
	
	# 폭포 타일 찾기
	find_waterfall_tiles()
	
	# 맵 활성화 상태 적용
	_apply_all_maps()
	
	# 플랫폼 타일 초기화 (아래 블록 유무에 따라 atlas 설정)
	# 약간의 딜레이 후 실행 (다른 노드들이 준비된 후)
	await get_tree().process_frame
	initialize_all_platform_tiles()
	
	# inside_cave 입구 타일을 breakable_tile로 이전 (terrain 연결을 위해)
	await get_tree().process_frame
	migrate_cave_entrance_tiles()

func _process(_delta):
	if not character:
		return
	
	# 캐릭터가 동굴 안에 있는지 확인
	var currently_in_cave = false
	
	# 각 TileMap에 대해 처리
	for cave in cave_tilemaps:
		if not cave:
			continue
		
		# 캐릭터의 현재 타일 좌표 계산 (전역 좌표를 로컬 좌표로 변환 후 타일 좌표로 변환)
		var character_local_pos = cave.to_local(character.global_position)
		var character_tile_pos = cave.local_to_map(character_local_pos)
		
		# 원본 레이어와 반투명 레이어 모두 확인
		var source_id_original = cave.get_cell_source_id(0, character_tile_pos)
		var source_id_transparent = cave.get_cell_source_id(transparent_layer_index, character_tile_pos)
		var is_character_on_tile = (source_id_original != -1 or source_id_transparent != -1)
		
		# 동굴 안에 있는지 체크
		if is_character_on_tile:
			currently_in_cave = true
		
		# 상태가 변경되었을 때만 실행
		if is_character_on_tile and not was_character_on_tile[cave]:
			# 캐릭터가 타일에 처음 들어옴 - 연결된 모든 타일 찾기
			if source_id_original != -1:
				find_and_make_transparent(cave, character_tile_pos)
		elif not is_character_on_tile and was_character_on_tile[cave]:
			# 캐릭터가 타일에서 나감 - 한 번만 복원
			clear_transparent_tiles(cave)
		
		# 상태 업데이트
		was_character_on_tile[cave] = is_character_on_tile
	
	# cave_always 타일맵 표시/숨김 처리
	update_cave_always_visibility(currently_in_cave)
	
	# 폭포 애니메이션
	animate_waterfall(_delta)

# 연결된 모든 타일을 찾아서 반투명하게 만드는 함수 (Flood Fill 방식)
func find_and_make_transparent(cave: TileMap, start_tile_pos: Vector2i):
	# 먼저 이전 타일들을 복원
	restore_transparent_tiles(cave)
	
	# 연결된 모든 타일을 찾기 (BFS - Breadth First Search)
	var visited: Dictionary = {}  # 이미 확인한 타일들
	var queue: Array[Vector2i] = []  # 확인할 타일들의 큐
	
	# 시작 타일을 큐에 추가
	queue.append(start_tile_pos)
	visited[start_tile_pos] = true
	
	# 인접한 타일들의 방향 (상, 하, 좌, 우, 대각선)
	var adjacent_positions = [
		Vector2i(0, -1),   # 위
		Vector2i(0, 1),    # 아래
		Vector2i(-1, 0),   # 왼쪽
		Vector2i(1, 0),    # 오른쪽
		Vector2i(-1, -1),  # 왼쪽 위
		Vector2i(1, -1),   # 오른쪽 위
		Vector2i(-1, 1),   # 왼쪽 아래
		Vector2i(1, 1),    # 오른쪽 아래
	]
	
	# 먼저 모든 연결된 타일을 찾아서 리스트에 저장 (타일 이동 전에)
	var tiles_to_process: Array[Vector2i] = []
	
	# BFS로 연결된 모든 타일 찾기 (타일 이동 전에)
	while queue.size() > 0:
		var current_pos = queue.pop_front()
		
		# 현재 타일이 원본 레이어에 존재하는지 확인
		var source_id = cave.get_cell_source_id(0, current_pos)
		if source_id == -1:
			continue  # 타일이 없으면 스킵
		
		tiles_to_process.append(current_pos)
		
		# 인접한 타일들 확인
		for offset in adjacent_positions:
			var next_pos = current_pos + offset
			
			# 이미 확인했으면 스킵
			if next_pos in visited:
				continue
			
			visited[next_pos] = true
			
			# 인접한 타일이 원본 레이어에 존재하는지 확인
			var next_source_id = cave.get_cell_source_id(0, next_pos)
			if next_source_id != -1:
				# 큐에 추가
				queue.append(next_pos)
	
	# 이제 찾은 모든 타일을 한 번에 처리 (타일 이동)
	# 깜빡거림 방지를 위해 모든 타일 정보를 먼저 수집
	var tiles_data: Array = []
	for tile_pos in tiles_to_process:
		# 타일 정보 가져오기
		var source_id = cave.get_cell_source_id(0, tile_pos)
		var atlas_coords = cave.get_cell_atlas_coords(0, tile_pos)
		var alternative_tile = cave.get_cell_alternative_tile(0, tile_pos)
		
		# 타일 정보 캐시에 저장 (복원용)
		tile_info_cache[cave][tile_pos] = {
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		}
		
		tiles_data.append({
			"pos": tile_pos,
			"source_id": source_id,
			"atlas_coords": atlas_coords,
			"alternative_tile": alternative_tile
		})
	
	# 모든 타일을 한 번에 이동 (반투명 레이어에 먼저 추가한 후 원본에서 제거)
	for tile_data in tiles_data:
		var tile_pos = tile_data["pos"]
		# 반투명 레이어에 타일 추가
		cave.set_cell(transparent_layer_index, tile_pos, tile_data["source_id"], tile_data["atlas_coords"], tile_data["alternative_tile"])
		current_transparent_tiles[cave].append(tile_pos)
	
	# 모든 타일을 반투명 레이어에 추가한 후, 원본 레이어에서 제거
	for tile_data in tiles_data:
		var tile_pos = tile_data["pos"]
		# 원본 레이어에서 타일 제거
		cave.set_cell(0, tile_pos, -1)

# 반투명 타일들을 모두 원본 레이어로 복원하는 함수
func restore_transparent_tiles(cave: TileMap):
	for tile_pos in current_transparent_tiles[cave]:
		# 캐시에서 타일 정보 가져오기
		if tile_pos in tile_info_cache[cave]:
			var tile_info = tile_info_cache[cave][tile_pos]
			# 원본 레이어에 복원
			cave.set_cell(0, tile_pos, tile_info["source_id"], tile_info["atlas_coords"], tile_info["alternative_tile"])
		
		# 반투명 레이어에서 제거
		cave.set_cell(transparent_layer_index, tile_pos, -1)
	
	current_transparent_tiles[cave].clear()
	tile_info_cache[cave].clear()

# 반투명 타일들을 모두 제거하는 함수 (원본 레이어는 유지)
func clear_transparent_tiles(cave: TileMap):
	restore_transparent_tiles(cave)

# 플랫폼 타일들의 Physics Layer 설정 확인 함수
func check_platform_tiles_physics_layers():
	if platform == null:
		print("platform TileMap을 찾을 수 없습니다!")
		return
	
	var tile_set = platform.tile_set
	if tile_set == null:
		print("TileSet을 찾을 수 없습니다!")
		return
	
	# 플랫폼 레이어에서 사용되는 타일들 가져오기
	var used_cells = platform.get_used_cells(PLATFORM_LAYER_INDEX)
	print("플랫폼 레이어에 사용된 타일 개수: ", used_cells.size())
	
	# 사용된 타일들의 physics layer 확인
	var processed_tiles: Dictionary = {}
	for cell_pos in used_cells:
		var source_id = platform.get_cell_source_id(PLATFORM_LAYER_INDEX, cell_pos)
		var atlas_coords = platform.get_cell_atlas_coords(PLATFORM_LAYER_INDEX, cell_pos)
		
		# 이미 확인한 타일은 스킵
		var tile_key = str(source_id) + "_" + str(atlas_coords)
		if tile_key in processed_tiles:
			continue
		processed_tiles[tile_key] = true
		
		# TileSet에서 타일 소스 가져오기
		var tile_source = tile_set.get_source(source_id)
		if tile_source == null:
			continue
		
		# TileSetAtlasSource인 경우
		if tile_source is TileSetAtlasSource:
			var atlas_source = tile_source as TileSetAtlasSource
			# alternative_tile 0번의 tile_data 가져오기
			var tile_data = atlas_source.get_tile_data(atlas_coords, 0)
			if tile_data:
				# Physics Layer 0과 1의 사용 여부 확인
				var has_physics_0 = tile_data.get_collision_polygons_count(0) > 0
				var has_physics_1 = tile_data.get_collision_polygons_count(1) > 0
				print("타일 ", atlas_coords, " (source_id: ", source_id, "): Physics Layer 0 사용: ", has_physics_0, ", Physics Layer 1 사용: ", has_physics_1)
				
				# Physics Layer 1의 설정 확인
				if has_physics_1:
					# TileSet에서 Physics Layer 1의 collision_layer 확인
					var physics_layer_1_collision = tile_set.get_physics_layer_collision_layer(1)
					print("  Physics Layer 1의 collision_layer: ", physics_layer_1_collision, " (예상: 4)")
					print("  ✅ Physics Layer 1이 활성화되어 있습니다!")
				
				if has_physics_0:
					print("  ⚠️ 경고: 이 타일은 Physics Layer 0을 사용하고 있습니다! Physics Layer 0은 비활성화해야 합니다.")
				if not has_physics_1:
					print("  ⚠️ 경고: 이 타일은 Physics Layer 1을 사용하지 않습니다! Physics Layer 1을 활성화해야 합니다.")
					print("  💡 팁: TileSet에서 이 타일을 선택하고 Physics Layer 1에 collision polygon을 추가하세요.")

# === 폭포 애니메이션 함수들 ===

func find_waterfall_tiles():
	if not background or not background.tile_set:
		print("background TileMap을 찾을 수 없습니다!")
		return
	
	var tile_set = background.tile_set
	var waterfall_source_id: int = -1
	var waterfall_atlas_source: TileSetAtlasSource = null
	
	# TileSet에서 폭포 텍스처를 사용하는 소스 찾기
	for source_id in tile_set.get_source_count():
		var source = tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			var atlas_source = source as TileSetAtlasSource
			if atlas_source.texture and "warterfall" in atlas_source.texture.resource_path:
				waterfall_source_id = source_id
				waterfall_atlas_source = atlas_source
				print("✅ 폭포 텍스처 발견! Source ID: ", source_id)
				break
	
	if waterfall_source_id == -1 or not waterfall_atlas_source:
		print("❌ 폭포 텍스처를 찾을 수 없습니다!")
		return
	
	# 사용 가능한 atlas 좌표들을 x별로 그룹화 (각 x 좌표별로 사용 가능한 y 좌표들)
	var available_coords_by_x: Dictionary = {}  # x -> Array[y]
	
	# TileSetAtlasSource에서 모든 타일 좌표 가져오기
	var atlas_grid_size = waterfall_atlas_source.get_atlas_grid_size()
	for x in range(-10, atlas_grid_size.x + 10):  # 음수 좌표도 확인
		for y in range(atlas_grid_size.y):
			var coords = Vector2i(x, y)
			if waterfall_atlas_source.has_tile(coords):
				if not x in available_coords_by_x:
					available_coords_by_x[x] = []
				available_coords_by_x[x].append(y)
	
	# 각 x 좌표별로 y 좌표 정렬 및 순서 조정
	for x in available_coords_by_x.keys():
		var y_coords = available_coords_by_x[x]
		y_coords.sort()
		
		# 올바른 흐름 순서로 재배치: 1→2→3 순서가 되도록
		# 현재 [0, 1, 2]를 [0, 2, 1]로 변경 (1→3→2 패턴을 1→2→3으로 수정)
		if y_coords.size() == 3:
			available_coords_by_x[x] = [y_coords[0], y_coords[2], y_coords[1]]
	
	print("📋 사용 가능한 폭포 타일 좌표 (x별): ", available_coords_by_x)
	print("📊 각 x 좌표별 y 패턴:")
	for x in available_coords_by_x.keys():
		print("  x=", x, " → y 좌표들: ", available_coords_by_x[x])
	
	# background에서 폭포 타일을 사용하는 셀 찾기
	var used_cells = background.get_used_cells(WATERFALL_LAYER)
	for cell_pos in used_cells:
		var source_id = background.get_cell_source_id(WATERFALL_LAYER, cell_pos)
		
		if source_id == waterfall_source_id:
			var atlas_coords = background.get_cell_atlas_coords(WATERFALL_LAYER, cell_pos)
			var alternative_tile = background.get_cell_alternative_tile(WATERFALL_LAYER, cell_pos)
			
			# 현재 타일의 x 좌표에서 사용 가능한 y 좌표들 가져오기
			var x = atlas_coords.x
			if x in available_coords_by_x:
				var available_y_coords = available_coords_by_x[x]
				
				waterfall_tiles.append({
					"cell_pos": cell_pos,
					"source_id": source_id,
					"atlas_x": x,  # x 좌표는 고정
					"available_y": available_y_coords,  # 순환할 y 좌표들
					"alternative": alternative_tile
				})
	
	print("💧 폭포 타일 개수: ", waterfall_tiles.size())

func animate_waterfall(delta: float):
	if waterfall_tiles.is_empty() or not waterfall_animation_enabled:
		return
	
	waterfall_time += delta * waterfall_speed
	
	# 각 x 좌표별로 가장 아래에 있는 타일의 y 위치 찾기
	var bottom_tiles_by_x: Dictionary = {}  # x -> max_y
	for tile_info in waterfall_tiles:
		var cell_pos = tile_info["cell_pos"]
		var x = cell_pos.x
		if not x in bottom_tiles_by_x or cell_pos.y > bottom_tiles_by_x[x]:
			bottom_tiles_by_x[x] = cell_pos.y
	
	# 각 폭포 타일 업데이트
	for i in range(waterfall_tiles.size()):
		var tile_info = waterfall_tiles[i]
		var cell_pos = tile_info["cell_pos"]
		var available_y = tile_info["available_y"]
		
		if available_y.is_empty():
			continue
		
		var new_y: int
		
		# 각 x 좌표에서 가장 아래에 있는 타일인지 확인
		var is_bottom_tile = (cell_pos.x in bottom_tiles_by_x and cell_pos.y == bottom_tiles_by_x[cell_pos.x])
		# 끝부분 바로 위 타일인지 확인
		var is_second_bottom_tile = (cell_pos.x in bottom_tiles_by_x and cell_pos.y == bottom_tiles_by_x[cell_pos.x] - 1)
		
		if is_bottom_tile:
			# 끝부분(맨 아래) 타일은 3번 프레임으로 고정 (available_y의 마지막 인덱스)
			new_y = available_y[available_y.size() - 1] if available_y.size() > 0 else available_y[0]
		elif is_second_bottom_tile and available_y.size() >= 2:
			# 끝부분 바로 위 타일은 2번 프레임으로 고정 (available_y의 두 번째 인덱스)
			new_y = available_y[1]
		else:
			# 나머지 타일들은 1번 프레임만 사용 (애니메이션 없음)
			new_y = available_y[0]
		
		var new_atlas = Vector2i(tile_info["atlas_x"], new_y)
		
		# 타일 업데이트
		background.set_cell(
			WATERFALL_LAYER,
			cell_pos,
			tile_info["source_id"],
			new_atlas,
			tile_info["alternative"]
		)

# cave_always 타일맵의 표시/숨김 처리
func update_cave_always_visibility(currently_in_cave: bool):
	if not cave_always:
		return
	
	# 상태가 변경되었을 때만 처리
	if currently_in_cave != is_in_any_cave:
		is_in_any_cave = currently_in_cave
		
		if is_in_any_cave:
			# 동굴 안에 들어감 - cave_always 숨기기
			cave_always.visible = false
			print("🚪 동굴 진입: cave_always 타일맵 숨김")
		else:
			# 동굴 밖으로 나감 - cave_always 보이기
			cave_always.visible = true
			print("🌞 동굴 탈출: cave_always 타일맵 표시")

# === 맵 전체 켜기/끄기 ===

## 특정 맵(Node2D)의 상태를 적용합니다
## @param map_node: 대상 Node2D (map_1 또는 map_2)
## @param enabled: 활성화 여부
func _apply_map_state(map_node: Node2D, enabled: bool):
	if not map_node:
		return
	
	map_node.visible = enabled
	map_node.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
	
	# TileMap의 collision을 끄려면 y_sort나 z_index 아래로 이동시키는 대신
	# 각 TileMap의 레이어별로 collision을 제어
	for child in map_node.get_children():
		if child is TileMap:
			# TileMap의 모든 레이어 순회
			for layer_idx in range(child.get_layers_count()):
				child.set_layer_enabled(layer_idx, enabled)

## 모든 맵의 상태를 적용합니다
func _apply_all_maps():
	_apply_map_state($map_1, map_1_enabled)
	_apply_map_state($map_2, map_2_enabled)

# ========================================
# 플랫폼 타일 조건부 변경 시스템
# ========================================
# 아래 블록 유무에 따라 플랫폼 타일의 텍스처를 변경합니다.
# - 아래에 블록 있음 → atlas (1, 0) 지지대용
# - 아래에 블록 없음 → atlas (0, 0) 공중용
# ========================================

## 특정 위치의 플랫폼 타일을 아래 블록 유무에 따라 업데이트합니다.
## @param tile_pos: 플랫폼 타일의 좌표
## @param platform_tilemap: 대상 platform TileMap (null이면 기본 platform 사용)
func update_platform_tile_at(tile_pos: Vector2i, platform_tilemap: TileMap = null) -> void:
	var target_platform = platform_tilemap if platform_tilemap else platform
	if not target_platform:
		return
	
	# 현재 타일 정보 가져오기
	var source_id = target_platform.get_cell_source_id(PLATFORM_LAYER_INDEX, tile_pos)
	if source_id == -1:
		return  # 타일이 없음
	
	# 플랫폼 source_id 체크 (설정된 경우에만)
	if platform_source_id != -1 and source_id != platform_source_id:
		return  # 다른 타일셋의 타일
	
	var current_atlas = target_platform.get_cell_atlas_coords(PLATFORM_LAYER_INDEX, tile_pos)
	var alternative = target_platform.get_cell_alternative_tile(PLATFORM_LAYER_INDEX, tile_pos)
	
	# 아래 타일 확인 (platform 좌표 기준)
	var below_pos = tile_pos + Vector2i(0, 1)
	var has_block_below = check_block_at_position(below_pos, target_platform)
	
	# 새로운 atlas 좌표 결정
	var new_atlas = platform_atlas_with_support if has_block_below else platform_atlas_no_support
	
	# 변경이 필요한 경우에만 업데이트
	if current_atlas != new_atlas:
		target_platform.set_cell(PLATFORM_LAYER_INDEX, tile_pos, source_id, new_atlas, alternative)
		print("🔧 플랫폼 타일 업데이트: ", tile_pos, " → atlas ", new_atlas, " (아래 블록: ", has_block_below, ")")

## 특정 위치에 블록이 있는지 확인합니다 (breakable_tile, maps 등).
## @param tile_pos: 확인할 타일 좌표 (platform TileMap 기준)
## @param platform_tilemap: 기준이 되는 platform TileMap
## @returns: 블록이 있으면 true
func check_block_at_position(tile_pos: Vector2i, platform_tilemap: TileMap) -> bool:
	# platform의 월드 좌표 계산
	var world_pos = platform_tilemap.to_global(platform_tilemap.map_to_local(tile_pos))
	
	# breakable_tile 그룹에서 모든 파괴 가능 타일맵 확인
	var breakable_tiles = get_tree().get_nodes_in_group("breakable_tiles")
	for breakable in breakable_tiles:
		if breakable is TileMap:
			var local_pos = breakable.to_local(world_pos)
			var check_tile_pos = breakable.local_to_map(local_pos)
			
			# 모든 레이어에서 타일 확인
			for layer_idx in range(breakable.get_layers_count()):
				var source_id = breakable.get_cell_source_id(layer_idx, check_tile_pos)
				if source_id != -1:
					return true  # 블록 발견
	
	# maps TileMap 확인
	if maps:
		var local_pos = maps.to_local(world_pos)
		var check_tile_pos = maps.local_to_map(local_pos)
		
		for layer_idx in range(maps.get_layers_count()):
			var source_id = maps.get_cell_source_id(layer_idx, check_tile_pos)
			if source_id != -1:
				return true  # 블록 발견
	
	return false

## 특정 위치 위에 있는 플랫폼 타일을 업데이트합니다.
## breakable_tile에서 블록 파괴 시 호출됩니다.
## @param world_pos: 파괴된 블록의 월드 좌표
func update_platform_above(world_pos: Vector2) -> void:
	# map_1의 platform 확인
	if platform:
		_check_and_update_platform_above(platform, world_pos)
	
	# map_2의 platform 확인 (있다면)
	var platform_m2 = get_node_or_null("map_2/platform")
	if platform_m2:
		_check_and_update_platform_above(platform_m2, world_pos)

## 특정 platform TileMap에서 주어진 위치 위의 플랫폼을 확인하고 업데이트합니다.
func _check_and_update_platform_above(platform_tilemap: TileMap, world_pos: Vector2) -> void:
	if not platform_tilemap or not platform_tilemap.tile_set:
		return
	
	# 파괴된 블록 위치를 플랫폼 타일 좌표로 변환
	var local_pos = platform_tilemap.to_local(world_pos)
	var base_tile_pos = platform_tilemap.local_to_map(local_pos)
	
	# 주변 3x3 범위의 플랫폼 타일 체크 (타일 크기 차이 보정)
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var check_pos = base_tile_pos + Vector2i(dx, dy)
			
			# 해당 위치에 플랫폼 타일이 있으면 업데이트
			var source_id = platform_tilemap.get_cell_source_id(PLATFORM_LAYER_INDEX, check_pos)
			if source_id != -1:
				update_platform_tile_at(check_pos, platform_tilemap)

## 모든 플랫폼 타일을 초기화합니다 (게임 시작 시 호출).
## 각 플랫폼 타일의 아래 블록 유무를 확인하여 적절한 atlas로 설정합니다.
func initialize_all_platform_tiles() -> void:
	print("🔧 모든 플랫폼 타일 초기화 중...")
	
	# map_1 platform
	if platform:
		_initialize_platform_tilemap(platform)
	
	# map_2 platform
	var platform_m2 = get_node_or_null("map_2/platform")
	if platform_m2:
		_initialize_platform_tilemap(platform_m2)
	
	print("✅ 플랫폼 타일 초기화 완료")

## 특정 platform TileMap의 모든 타일을 초기화합니다.
func _initialize_platform_tilemap(platform_tilemap: TileMap) -> void:
	var used_cells = platform_tilemap.get_used_cells(PLATFORM_LAYER_INDEX)
	for tile_pos in used_cells:
		update_platform_tile_at(tile_pos, platform_tilemap)

# ========================================
# Inside Cave 입구 타일 이전 시스템
# ========================================
# inside_cave 타일 중 breakable_tile과 인접한 것들을 breakable_tile로 이전합니다.
# 이렇게 하면 terrain 시스템이 같은 TileMap 내에서 작동하여 자연스러운 지형 변경이 됩니다.
# ========================================

## inside_cave 입구 타일을 breakable_tile로 이전합니다.
## breakable_tile과 인접한 inside_cave 타일을 찾아서 breakable_tile로 복사 후 삭제합니다.
func migrate_cave_entrance_tiles() -> void:
	# breakable_tiles 그룹에서 모든 breakable TileMap 찾기
	var breakable_tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	if breakable_tilemaps.is_empty():
		return
	
	var total_migrated = 0
	
	# 각 inside_cave TileMap에 대해 처리
	for cave in cave_tilemaps:
		if not cave or not cave.tile_set:
			continue
		
		# 이 cave와 가장 가까운 breakable_tile 찾기 (같은 부모 아래)
		var target_breakable: TileMap = null
		for breakable in breakable_tilemaps:
			if _is_same_map_group(cave, breakable):
				target_breakable = breakable
				break
		
		if not target_breakable:
			continue
		
		# inside_cave의 모든 타일을 확인
		var tiles_to_migrate: Array[Vector2i] = []
		var used_cells = cave.get_used_cells(0)
		
		for tile_pos in used_cells:
			# 이 타일이 breakable_tile과 인접한지 확인
			if _is_adjacent_to_breakable(cave, tile_pos, target_breakable):
				tiles_to_migrate.append(tile_pos)
		
		if tiles_to_migrate.is_empty():
			continue
		
		# breakable_tile의 terrain 정보 미리 가져오기
		var breakable_cells = target_breakable.get_used_cells(0)
		var b_terrain_set = -1
		var b_terrain = -1
		for cell in breakable_cells:
			var td = target_breakable.get_cell_tile_data(0, cell)
			if td and td.terrain_set >= 0:
				b_terrain_set = td.terrain_set
				b_terrain = td.terrain
				break
		
		# 이전할 breakable 좌표 수집
		var new_tile_positions: Array[Vector2i] = []
		
		for cave_tile_pos in tiles_to_migrate:
			# cave 타일의 월드 좌표 → breakable 타일 좌표
			var world_pos = cave.to_global(cave.map_to_local(cave_tile_pos))
			var breakable_tile_pos = target_breakable.local_to_map(target_breakable.to_local(world_pos))
			
			# 이미 타일이 있으면 스킵
			if target_breakable.get_cell_source_id(0, breakable_tile_pos) != -1:
				continue
			
			# inside_cave에서 타일 제거
			cave.set_cell(0, cave_tile_pos, -1)
			new_tile_positions.append(breakable_tile_pos)
			total_migrated += 1
		
		# terrain으로 타일 추가
		if new_tile_positions.size() > 0 and b_terrain_set >= 0:
			target_breakable.set_cells_terrain_connect(0, new_tile_positions, b_terrain_set, b_terrain, true)
	
	if total_migrated > 0:
		print("✅ 입구 타일 이전: ", total_migrated, "개")

## 두 노드가 같은 map 그룹(map_1 또는 map_2) 아래에 있는지 확인합니다.
func _is_same_map_group(node1: Node, node2: Node) -> bool:
	# map_1 또는 map_2 부모 찾기
	var map_parent1 = _find_map_parent(node1)
	var map_parent2 = _find_map_parent(node2)
	
	# 둘 다 map 부모가 있고 같으면 true
	if map_parent1 and map_parent2:
		return map_parent1 == map_parent2
	
	# map 부모가 없는 경우 (map_2에만 breakable_tile이 있을 수 있음)
	# breakable_tile이 map_2 아래에 있는지 확인
	if map_parent1 and map_parent1.name == "map_2":
		return true  # map_2의 cave는 breakable_tile과 매칭
	
	# map_1의 cave도 map_2의 breakable_tile과 매칭 시도
	if map_parent1 and map_parent1.name == "map_1":
		# map_2에 breakable_tile이 있으면 매칭
		return true
	
	return false

## 노드의 map_1 또는 map_2 부모를 찾습니다.
func _find_map_parent(node: Node) -> Node:
	var current = node
	while current:
		if current.name == "map_1" or current.name == "map_2":
			return current
		current = current.get_parent()
	return null

## inside_cave 타일이 breakable_tile과 인접한지 확인합니다.
func _is_adjacent_to_breakable(cave: TileMap, cave_tile_pos: Vector2i, breakable: TileMap) -> bool:
	# 4방향 확인 (상하좌우)
	var directions = [
		Vector2i(0, -1),  # 위
		Vector2i(0, 1),   # 아래
		Vector2i(-1, 0),  # 왼쪽
		Vector2i(1, 0)    # 오른쪽
	]
	
	for dir in directions:
		var neighbor_cave_pos = cave_tile_pos + dir
		
		# 인접 위치의 월드 좌표 계산
		var world_pos = cave.to_global(cave.map_to_local(neighbor_cave_pos))
		
		# breakable_tile의 타일 좌표로 변환
		var breakable_local = breakable.to_local(world_pos)
		var breakable_tile_pos = breakable.local_to_map(breakable_local)
		
		# breakable_tile에 타일이 있는지 확인
		var source_id = breakable.get_cell_source_id(0, breakable_tile_pos)
		if source_id != -1:
			return true  # breakable_tile과 인접함
	
	return false

## breakable_tile의 terrain을 업데이트합니다 (이전된 타일 주변).
func _update_breakable_terrain(breakable: TileMap, migrated_tiles: Array[Dictionary]) -> void:
	if migrated_tiles.is_empty():
		return
	
	# 이전된 타일들과 그 주변 타일들의 좌표 수집
	var tiles_to_update: Array[Vector2i] = []
	var terrain_set = -1
	var terrain = -1
	
	for tile_info in migrated_tiles:
		var cave_tile_pos = tile_info["cave_tile_pos"]
		
		# 이 타일의 breakable 좌표 계산 (대략적)
		# 정확한 변환을 위해 다시 계산
		if tile_info["terrain_set"] >= 0:
			terrain_set = tile_info["terrain_set"]
			terrain = tile_info["terrain"]
	
	if terrain_set < 0 or terrain < 0:
		return
	
	# 모든 breakable 타일의 terrain 업데이트
	var all_cells = breakable.get_used_cells(0)
	var cells_with_terrain: Array[Vector2i] = []
	
	for cell_pos in all_cells:
		var tile_data = breakable.get_cell_tile_data(0, cell_pos)
		if tile_data and tile_data.terrain_set == terrain_set:
			cells_with_terrain.append(cell_pos)
	
	if cells_with_terrain.size() > 0:
		breakable.set_cells_terrain_connect(0, cells_with_terrain, terrain_set, terrain, false)

## 특정 월드 좌표 주변의 inside_cave 타일들의 terrain을 업데이트합니다.
## @param world_pos: 파괴된 블록의 월드 좌표
func update_inside_cave_terrain_around(world_pos: Vector2) -> void:
	# 이제 입구 타일이 breakable_tile로 이전되었으므로
	# breakable_tile 자체의 terrain 업데이트만 필요
	var breakable_tilemaps = get_tree().get_nodes_in_group("breakable_tiles")
	
	for breakable in breakable_tilemaps:
		if not breakable is TileMap:
			continue
		
		var local_pos = breakable.to_local(world_pos)
		var center_tile_pos = breakable.local_to_map(local_pos)
		
		# 주변 타일들 수집
		var neighbors = [
			Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1),
			Vector2i(-1, 0),                   Vector2i(1, 0),
			Vector2i(-1, 1),  Vector2i(0, 1),  Vector2i(1, 1)
		]
		
		var tiles_to_update: Array[Vector2i] = []
		var terrain_set = -1
		var terrain = -1
		
		for offset in neighbors:
			var check_pos = center_tile_pos + offset
			var source_id = breakable.get_cell_source_id(0, check_pos)
			if source_id != -1:
				var tile_data = breakable.get_cell_tile_data(0, check_pos)
				if tile_data and tile_data.terrain_set >= 0:
					terrain_set = tile_data.terrain_set
					terrain = tile_data.terrain
					tiles_to_update.append(check_pos)
		
		if tiles_to_update.size() > 0 and terrain_set >= 0 and terrain >= 0:
			breakable.set_cells_terrain_connect(0, tiles_to_update, terrain_set, terrain, false)
