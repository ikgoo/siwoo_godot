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

# === map_1 노드 참조 ===
@onready var maps = $map_1/maps  # maps TileMap 참조
@onready var platform = $map_1/platform  # platform TileMap 참조
@onready var background = $map_1/background  # background TileMap 참조
@onready var cave_always = $map_1/cave_always  # 동굴 밖에서만 보이는 타일맵
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

# 반투명 타일들을 저장하는 별도 레이어
# layer 0, 2 = 원본 타일 (채굴 가능), layer 1, 3 = 반투명 타일
var transparent_layer_map: Dictionary = {
	0: 1,  # layer 0 → layer 1로 반투명 처리
	2: 3,  # layer 2 → layer 3로 반투명 처리
}

# 현재 반투명하게 처리된 타일들의 좌표 (각 TileMap별, 레이어별로 저장)
# TileMap -> {original_layer: Array[Vector2i]}
var current_transparent_tiles: Dictionary = {}

# 캐릭터가 이전 프레임에 타일 위에 있었는지 여부 (각 TileMap별로 저장)
var was_character_on_tile: Dictionary = {}  # TileMap -> bool

# 반투명 정도 (0.0 = 완전 투명, 1.0 = 완전 불투명)
var transparency_alpha: float = 0.5  # 반투명

# 타일 정보를 저장하기 위한 Dictionary (복원용, 각 TileMap별로 저장)
var tile_info_cache: Dictionary = {}  # TileMap -> {Vector2i -> {source_id, atlas_coords, alternative_tile}}

# cave_always 타일맵 표시 여부 (동굴 안에 있는지 추적)
var is_in_any_cave: bool = false

func _ready():
	# 부모 노드(main)에서 캐릭터 찾기
	var parent = get_parent()
	if parent:
		character = parent.get_node_or_null("character")
	
	# 모든 맵에서 동굴 TileMap들을 자동으로 찾기
	# "cave"가 이름에 포함된 TileMap들을 모두 수집
	var all_maps = [map_1, map_2]
	for map_node in all_maps:
		if not map_node:
			continue
		for child in map_node.get_children():
			# TileMap이고, 이름에 "cave"가 포함되어 있으면 추가
			# (cave_always는 제외 - 반투명 처리 안 함)
			if child is TileMap and "cave" in child.name.to_lower() and child.name != "cave_always":
				cave_tilemaps.append(child)
	
	# 각 TileMap 초기화
	for cave in cave_tilemaps:
		# 필요한 레이어들 생성 (layer 0, 1, 2, 3)
		while cave.get_layers_count() < 4:
			cave.add_layer(cave.get_layers_count())
		
		# 반투명 레이어들(layer 1, 3) 설정
		cave.set_layer_modulate(1, Color(1.0, 1.0, 1.0, transparency_alpha))
		cave.set_layer_modulate(3, Color(1.0, 1.0, 1.0, transparency_alpha))
		
		# 초기화 (레이어별로 저장)
		current_transparent_tiles[cave] = {0: [], 2: []}
		was_character_on_tile[cave] = false
		tile_info_cache[cave] = {0: {}, 2: {}}
	
	# 플랫폼 타일들의 Physics Layer 설정 확인
	check_platform_tiles_physics_layers()
	
	# 폭포 타일 찾기
	find_waterfall_tiles()
	
	# 맵 활성화 상태 적용
	_apply_all_maps()

func _unhandled_input(event):
	# 4번 키를 누르면 마우스 위치의 플랫폼/횃불 삭제
	if event is InputEventKey and event.pressed and event.keycode == KEY_4:
		delete_object_at_mouse()

## 마우스 위치의 플랫폼 또는 횃불을 삭제하는 함수
func delete_object_at_mouse():
	var mouse_pos = get_global_mouse_position()
	
	# 1. 먼저 횃불 삭제 시도
	if delete_torch_at_position(mouse_pos):
		return
	
	# 2. 플랫폼 타일 삭제 시도
	if delete_platform_at_position(mouse_pos):
		return

## 해당 위치의 횃불을 삭제하는 함수
## @param pos: 전역 좌표
## @returns: 삭제 성공 여부
func delete_torch_at_position(pos: Vector2) -> bool:
	var delete_radius = 20.0  # 삭제 감지 범위
	
	# map_1과 map_2의 torchs 노드들을 확인
	var torch_containers = []
	if map_1 and map_1.has_node("torchs"):
		torch_containers.append(map_1.get_node("torchs"))
	if map_2 and map_2.has_node("torchs"):
		torch_containers.append(map_2.get_node("torchs"))
	
	for container in torch_containers:
		for torch in container.get_children():
			if torch.global_position.distance_to(pos) < delete_radius:
				torch.queue_free()
				return true
	
	return false

## 해당 위치의 플랫폼 타일을 삭제하는 함수
## @param pos: 전역 좌표
## @returns: 삭제 성공 여부
func delete_platform_at_position(pos: Vector2) -> bool:
	if not platform:
		return false
	
	# 전역 좌표를 타일맵 로컬 좌표로 변환
	var local_pos = platform.to_local(pos)
	var tile_pos = platform.local_to_map(local_pos)
	
	# 해당 위치에 타일이 있는지 확인
	var source_id = platform.get_cell_source_id(PLATFORM_LAYER_INDEX, tile_pos)
	if source_id != -1:
		# 타일 삭제
		platform.set_cell(PLATFORM_LAYER_INDEX, tile_pos, -1)
		return true
	
	return false

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
		
		# 원본 레이어(0, 2)와 반투명 레이어(1, 3) 모두 확인
		var is_character_on_tile = false
		for orig_layer in transparent_layer_map.keys():
			var trans_layer = transparent_layer_map[orig_layer]
			var source_id_original = cave.get_cell_source_id(orig_layer, character_tile_pos)
			var source_id_transparent = cave.get_cell_source_id(trans_layer, character_tile_pos)
			if source_id_original != -1 or source_id_transparent != -1:
				is_character_on_tile = true
				break
		
		# 동굴 안에 있는지 체크
		if is_character_on_tile:
			currently_in_cave = true
		
		# 상태가 변경되었을 때만 실행
		if is_character_on_tile and not was_character_on_tile[cave]:
			# 캐릭터가 타일에 처음 들어옴 - 연결된 모든 타일 찾기
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
# 모든 원본 레이어(0, 2)에 대해 처리
func find_and_make_transparent(cave: TileMap, start_tile_pos: Vector2i):
	# 먼저 이전 타일들을 복원
	restore_transparent_tiles(cave)
	
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
	
	# 각 원본 레이어에 대해 처리
	for orig_layer in transparent_layer_map.keys():
		var trans_layer = transparent_layer_map[orig_layer]
		
		# 연결된 모든 타일을 찾기 (BFS - Breadth First Search)
		var visited: Dictionary = {}
		var queue: Array[Vector2i] = []
		
		# 시작 타일을 큐에 추가
		queue.append(start_tile_pos)
		visited[start_tile_pos] = true
		
		# 먼저 모든 연결된 타일을 찾아서 리스트에 저장
		var tiles_to_process: Array[Vector2i] = []
		
		# BFS로 연결된 모든 타일 찾기
		while queue.size() > 0:
			var current_pos = queue.pop_front()
			
			# 현재 타일이 해당 레이어에 존재하는지 확인
			var source_id = cave.get_cell_source_id(orig_layer, current_pos)
			if source_id == -1:
				continue
			
			tiles_to_process.append(current_pos)
			
			# 인접한 타일들 확인
			for offset in adjacent_positions:
				var next_pos = current_pos + offset
				
				if next_pos in visited:
					continue
				
				visited[next_pos] = true
				
				var next_source_id = cave.get_cell_source_id(orig_layer, next_pos)
				if next_source_id != -1:
					queue.append(next_pos)
		
		# 찾은 모든 타일 정보 수집
		var tiles_data: Array = []
		for tile_pos in tiles_to_process:
			var source_id = cave.get_cell_source_id(orig_layer, tile_pos)
			var atlas_coords = cave.get_cell_atlas_coords(orig_layer, tile_pos)
			var alternative_tile = cave.get_cell_alternative_tile(orig_layer, tile_pos)
			
			# 타일 정보 캐시에 저장 (복원용)
			tile_info_cache[cave][orig_layer][tile_pos] = {
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
		
		# 반투명 레이어에 먼저 추가
		for tile_data in tiles_data:
			var tile_pos = tile_data["pos"]
			cave.set_cell(trans_layer, tile_pos, tile_data["source_id"], tile_data["atlas_coords"], tile_data["alternative_tile"])
			current_transparent_tiles[cave][orig_layer].append(tile_pos)
		
		# 원본 레이어에서 제거
		for tile_data in tiles_data:
			var tile_pos = tile_data["pos"]
			cave.set_cell(orig_layer, tile_pos, -1)

# 반투명 타일들을 모두 원본 레이어로 복원하는 함수
func restore_transparent_tiles(cave: TileMap):
	# 각 원본 레이어에 대해 처리
	for orig_layer in transparent_layer_map.keys():
		var trans_layer = transparent_layer_map[orig_layer]
		
		for tile_pos in current_transparent_tiles[cave][orig_layer]:
			# 캐시에서 타일 정보 가져오기
			if tile_pos in tile_info_cache[cave][orig_layer]:
				var tile_info = tile_info_cache[cave][orig_layer][tile_pos]
				# 원본 레이어에 복원
				cave.set_cell(orig_layer, tile_pos, tile_info["source_id"], tile_info["atlas_coords"], tile_info["alternative_tile"])
			
			# 반투명 레이어에서 제거
			cave.set_cell(trans_layer, tile_pos, -1)
		
		current_transparent_tiles[cave][orig_layer].clear()
		tile_info_cache[cave][orig_layer].clear()

# 반투명 타일들을 모두 제거하는 함수 (원본 레이어는 유지)
func clear_transparent_tiles(cave: TileMap):
	restore_transparent_tiles(cave)

# 플랫폼 타일들의 Physics Layer 설정 확인 함수
func check_platform_tiles_physics_layers():
	if platform == null:
		return
	
	var tile_set = platform.tile_set
	if tile_set == null:
		return

# === 폭포 애니메이션 함수들 ===

func find_waterfall_tiles():
	if not background or not background.tile_set:
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
				break
	
	if waterfall_source_id == -1 or not waterfall_atlas_source:
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
		else:
			# 동굴 밖으로 나감 - cave_always 보이기
			cave_always.visible = true

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
