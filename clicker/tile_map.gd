extends Node2D

@onready var inside_cave = $inside_cave
@onready var maps = $maps  # maps TileMap 참조
@onready var platform = $platform  # platform TileMap 참조
# 캐릭터 참조 (부모 노드를 통해 접근)
var character: CharacterBody2D

# 플랫폼 레이어 인덱스 (platform TileMap의 layer_0)
const PLATFORM_LAYER_INDEX = 0

# 플랫폼 collision layer (2번 비트 = 4)
const PLATFORM_COLLISION_LAYER = 4

# 반투명 타일들을 저장하는 별도 레이어 (1번 레이어 사용)
var transparent_layer_index: int = 1  # inside_cave의 두 번째 레이어 사용

# 현재 반투명하게 처리된 타일들의 좌표
var current_transparent_tiles: Array[Vector2i] = []

# 캐릭터가 이전 프레임에 타일 위에 있었는지 여부
var was_character_on_tile: bool = false

# 반투명 정도 (0.0 = 완전 투명, 1.0 = 완전 불투명)
var transparency_alpha: float = 0.5

# 타일 정보를 저장하기 위한 Dictionary (복원용)
var tile_info_cache: Dictionary = {}  # Vector2i -> {source_id, atlas_coords, alternative_tile}

func _ready():
	# 부모 노드(main)에서 캐릭터 찾기
	var parent = get_parent()
	if parent:
		character = parent.get_node_or_null("character")
	
	# inside_cave에 두 번째 레이어가 없으면 생성
	if inside_cave.get_layers_count() <= transparent_layer_index:
		inside_cave.add_layer(transparent_layer_index)
	
	# 두 번째 레이어를 반투명하게 설정
	inside_cave.set_layer_modulate(transparent_layer_index, Color(1.0, 1.0, 1.0, transparency_alpha))
	
	# 플랫폼 타일들의 Physics Layer 설정 확인
	check_platform_tiles_physics_layers()

func _process(_delta):
	if not inside_cave or not character:
		return
	
	# 캐릭터의 현재 타일 좌표 계산 (전역 좌표를 로컬 좌표로 변환 후 타일 좌표로 변환)
	var character_local_pos = inside_cave.to_local(character.global_position)
	var character_tile_pos = inside_cave.local_to_map(character_local_pos)
	
	# 원본 레이어와 반투명 레이어 모두 확인
	var source_id_original = inside_cave.get_cell_source_id(0, character_tile_pos)
	var source_id_transparent = inside_cave.get_cell_source_id(transparent_layer_index, character_tile_pos)
	var is_character_on_tile = (source_id_original != -1 or source_id_transparent != -1)
	
	# 상태가 변경되었을 때만 실행
	if is_character_on_tile and not was_character_on_tile:
		# 캐릭터가 타일에 처음 들어옴 - 연결된 모든 타일 찾기
		# 반투명 레이어에 있는 타일이라도 원본 레이어 기준으로 확인
		if source_id_original != -1:
			find_and_make_transparent(character_tile_pos)
	elif not is_character_on_tile and was_character_on_tile:
		# 캐릭터가 타일에서 나감 - 한 번만 복원
		clear_transparent_tiles()
	
	# 상태 업데이트
	was_character_on_tile = is_character_on_tile

# 연결된 모든 타일을 찾아서 반투명하게 만드는 함수 (Flood Fill 방식)
func find_and_make_transparent(start_tile_pos: Vector2i):
	# 먼저 이전 타일들을 복원
	restore_transparent_tiles()
	
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
		var source_id = inside_cave.get_cell_source_id(0, current_pos)
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
			var next_source_id = inside_cave.get_cell_source_id(0, next_pos)
			if next_source_id != -1:
				# 큐에 추가
				queue.append(next_pos)
	
	# 이제 찾은 모든 타일을 한 번에 처리 (타일 이동)
	# 깜빡거림 방지를 위해 모든 타일 정보를 먼저 수집
	var tiles_data: Array = []
	for tile_pos in tiles_to_process:
		# 타일 정보 가져오기
		var source_id = inside_cave.get_cell_source_id(0, tile_pos)
		var atlas_coords = inside_cave.get_cell_atlas_coords(0, tile_pos)
		var alternative_tile = inside_cave.get_cell_alternative_tile(0, tile_pos)
		
		# 타일 정보 캐시에 저장 (복원용)
		tile_info_cache[tile_pos] = {
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
		inside_cave.set_cell(transparent_layer_index, tile_pos, tile_data["source_id"], tile_data["atlas_coords"], tile_data["alternative_tile"])
		current_transparent_tiles.append(tile_pos)
	
	# 모든 타일을 반투명 레이어에 추가한 후, 원본 레이어에서 제거
	for tile_data in tiles_data:
		var tile_pos = tile_data["pos"]
		# 원본 레이어에서 타일 제거
		inside_cave.set_cell(0, tile_pos, -1)

# 반투명 타일들을 모두 원본 레이어로 복원하는 함수
func restore_transparent_tiles():
	for tile_pos in current_transparent_tiles:
		# 캐시에서 타일 정보 가져오기
		if tile_pos in tile_info_cache:
			var tile_info = tile_info_cache[tile_pos]
			# 원본 레이어에 복원
			inside_cave.set_cell(0, tile_pos, tile_info["source_id"], tile_info["atlas_coords"], tile_info["alternative_tile"])
		
		# 반투명 레이어에서 제거
		inside_cave.set_cell(transparent_layer_index, tile_pos, -1)
	
	current_transparent_tiles.clear()
	tile_info_cache.clear()

# 반투명 타일들을 모두 제거하는 함수 (원본 레이어는 유지)
func clear_transparent_tiles():
	restore_transparent_tiles()

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
