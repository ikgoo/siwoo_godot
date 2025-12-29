extends Node
class_name RandomMapGenerator

## DST 스타일 맵 생성기 (실제 DST와 유사한 방식)

## 맵 생성 진행 상황 시그널
signal map_generation_progress(progress: float, status: String)

## 맵 크기 enum
enum MapSize {
	SMALL,   # 30x30
	MEDIUM,  # 50x50
	LARGE    # 80x80
}

## 맵 크기 설정
@export var map_size: MapSize = MapSize.MEDIUM

## 맵 크기
var map_width: int = 50
var map_height: int = 50

## Voronoi 지역 개수
var region_count: int = 10

## 생성된 맵 데이터
var generated_map: Array = []

## Voronoi 시드 포인트들
var seed_points: Array = []

## 각 타일이 속한 지역 ID
var region_map: Array = []

## 각 지역의 바이옴
var region_biomes: Dictionary = {}

## 각 지역의 크기 (타일 개수)
var region_sizes: Dictionary = {}

## FastNoiseLite for terrain generation (Godot 4)
var height_noise: FastNoiseLite

## 디버그 모드 (false: 일반 크기, true: 작은 맵으로 빠른 테스트)
@export var debug_mode: bool = false


func _ready():
	update_map_size()
	setup_noise_generator()


## FastNoiseLite 설정 (Godot 4)
func setup_noise_generator():
	height_noise = FastNoiseLite.new()
	height_noise.seed = randi()
	height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	height_noise.frequency = 1.0 / (float(min(map_width, map_height)) * 0.8)
	height_noise.fractal_octaves = 4
	height_noise.fractal_gain = 0.5
	
	if debug_mode:
		print("  🌊 Noise 생성기 설정: frequency=%.3f, octaves=%d" % [height_noise.frequency, height_noise.fractal_octaves])


## 맵 크기에 따라 설정 (개발자 모드 고려)
func update_map_size():
	if debug_mode:
		# 개발자 모드: 작은 맵으로 빠르게 테스트
		match map_size:
			MapSize.SMALL:
				map_width = 40
				map_height = 40
				region_count = randi_range(18, 25)
			MapSize.MEDIUM:
				map_width = 60
				map_height = 60
				region_count = randi_range(30, 40)
			MapSize.LARGE:
				map_width = 80
				map_height = 80
				region_count = randi_range(45, 60)
	else:
		# 일반 모드: 큰 맵으로 정상 플레이
		match map_size:
			MapSize.SMALL:
				map_width = 100
				map_height = 100
				region_count = randi_range(40, 55)
			MapSize.MEDIUM:
				map_width = 150
				map_height = 150
				region_count = randi_range(60, 80)
			MapSize.LARGE:
				map_width = 200
				map_height = 200
				region_count = randi_range(90, 120)
	
	# Noise frequency를 맵 크기에 맞게 조정 (Godot 4)
	if height_noise:
		height_noise.frequency = 1.0 / (float(min(map_width, map_height)) * 0.8)
	
	if debug_mode:
		print("  📏 맵 크기: %dx%d, 지역: %d개 (개발자 모드)" % [map_width, map_height, region_count])
	else:
		print("  📏 맵 크기: %dx%d, 지역: %d개 (일반 모드)" % [map_width, map_height, region_count])


## DST 스타일 맵 생성 (메인 함수 - 비동기)
func generate_random_map() -> Array:
	if debug_mode:
		print("\n🗺️ [DST 스타일 맵 생성] 시작...")
	
	map_generation_progress.emit(0.0, "맵 크기 설정 중...")
	update_map_size()
	
	# Noise 생성기 초기화 (맵 크기 설정 후!)
	if not height_noise:
		setup_noise_generator()
	else:
		# 이미 있으면 frequency만 업데이트
		height_noise.frequency = 1.0 / (float(min(map_width, map_height)) * 0.8)
	
	# 1. 맵 초기화
	map_generation_progress.emit(10.0, "맵 초기화 중...")
	initialize_map()
	
	# 2. Voronoi 시드 포인트 생성 (전체 맵에 분산)
	map_generation_progress.emit(20.0, "바이옴 시드 생성 중...")
	generate_seed_points_scattered()
	
	# 3. Voronoi Diagram 생성
	map_generation_progress.emit(35.0, "Voronoi 다이어그램 생성 중...")
	generate_voronoi_diagram()
	
	# 4. 작은 지역 제거 및 병합
	map_generation_progress.emit(50.0, "작은 지역 병합 중...")
	merge_small_regions()
	
	# 5. 바다/육지 결정 (먼저!)
	map_generation_progress.emit(60.0, "바다와 육지 생성 중...")
	determine_land_and_sea()
	
	# 6. 육지 지역에만 바이옴 할당
	map_generation_progress.emit(70.0, "바이옴 할당 중...")
	assign_biomes_to_regions()
	
	# 7. 지역 바이옴을 맵에 적용
	map_generation_progress.emit(80.0, "바이옴 적용 중...")
	apply_biomes_to_map()
	
	# 8. 바이옴 간 연결 통로 생성 (DST 스타일)
	map_generation_progress.emit(92.0, "바이옴 연결 통로 생성 중...")
	create_biome_connections()
	
	# 9. 경계 부드럽게
	map_generation_progress.emit(96.0, "경계 다듬는 중...")
	smooth_boundaries()
	
	map_generation_progress.emit(100.0, "맵 생성 완료!")
	
	if debug_mode:
		print("🗺️ [DST 스타일 맵 생성] 완료!\n")
		print_biome_statistics()
	
	return generated_map


## 맵 초기화
func initialize_map():
	generated_map.clear()
	region_map.clear()
	seed_points.clear()
	region_biomes.clear()
	region_sizes.clear()
	
	for x in range(map_width):
		var row = []
		var region_row = []
		for y in range(map_height):
			row.append(0)
			region_row.append(-1)
		generated_map.append(row)
		region_map.append(region_row)
	
	if debug_mode:
		print("  ✅ 맵 초기화: %dx%d, 목표 지역: %d개" % [map_width, map_height, region_count])


## 시드 포인트 생성 (DST 스타일: 중앙 편향)
func generate_seed_points_scattered():
	var margin = 3
	var center = Vector2i(map_width / 2, map_height / 2)
	
	# Poisson Disk Sampling 방식으로 균등 분산
	var min_distance = sqrt((map_width * map_height) / region_count) * 0.8
	var attempts_per_point = 30
	
	# 첫 포인트는 중앙에 배치 (DST 스타일)
	seed_points.append(center)
	
	# 나머지 포인트들은 거리 유지하며 배치 (중앙 편향 적용)
	while seed_points.size() < region_count:
		var placed = false
		
		for _attempt in range(attempts_per_point):
			# DST 스타일: 중앙에 더 많은 포인트 생성 (40% 중앙 편향)
			var center_bias = randf_range(0.3, 0.5)
			var random_x = randi_range(margin, map_width - margin)
			var random_y = randi_range(margin, map_height - margin)
			var candidate = Vector2i(
				int(lerp(random_x, center.x, center_bias)),
				int(lerp(random_y, center.y, center_bias))
			)
			
			# 기존 포인트들과의 거리 체크
			var valid = true
			for existing in seed_points:
				if candidate.distance_to(existing) < min_distance:
					valid = false
					break
			
			if valid:
				seed_points.append(candidate)
				placed = true
				break
		
		if not placed:
			# 거리 조건을 만족하는 위치를 못 찾으면 그냥 랜덤 배치
			seed_points.append(Vector2i(
				randi_range(margin, map_width - margin),
				randi_range(margin, map_height - margin)
			))
	
	if debug_mode:
		print("  📍 시드 포인트 생성: %d개 (균등 분산)" % seed_points.size())


## Voronoi Diagram 생성
func generate_voronoi_diagram():
	for x in range(map_width):
		for y in range(map_height):
			var closest_region = -1
			var min_distance = INF
			
			for i in range(seed_points.size()):
				var seed = seed_points[i]
				var distance = Vector2(x, y).distance_to(Vector2(seed.x, seed.y))
				
				if distance < min_distance:
					min_distance = distance
					closest_region = i
			
			region_map[x][y] = closest_region
	
	# 지역 크기 계산
	for x in range(map_width):
		for y in range(map_height):
			var region = region_map[x][y]
			if not region_sizes.has(region):
				region_sizes[region] = 0
			region_sizes[region] += 1
	
	if debug_mode:
		print("  🗺️ Voronoi 생성: %d개 지역" % region_sizes.size())


## 작은 지역 제거 및 병합 (DST 스타일: 더 공격적)
func merge_small_regions():
	# 최소 크기를 2배로 증가 (더 큰 바이옴 덩어리)
	var min_region_size = (map_width * map_height) / (region_count * 1.5)
	var merged_count = 0
	var max_iterations = 3  # 여러 번 반복하여 고립된 섬 제거
	
	for _iteration in range(max_iterations):
		var regions_to_merge = []
		
		for region in region_sizes.keys():
			if region_sizes[region] < min_region_size:
				regions_to_merge.append(region)
		
		if regions_to_merge.is_empty():
			break
		
		for region in regions_to_merge:
			# 인접한 가장 큰 지역에 병합
			var neighbor_region = find_largest_neighbor_region(region)
			if neighbor_region != -1:
				merge_regions(region, neighbor_region)
				merged_count += 1
	
	if debug_mode:
		print("  🔗 작은 지역 병합: %d개 병합됨 (더 큰 바이옴)" % merged_count)


## 인접한 가장 큰 지역 찾기
func find_largest_neighbor_region(target_region: int) -> int:
	var neighbors = {}
	
	for x in range(map_width):
		for y in range(map_height):
			if region_map[x][y] == target_region:
				# 4방향 체크
				for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
						var neighbor = region_map[nx][ny]
						if neighbor != target_region:
							if not neighbors.has(neighbor):
								neighbors[neighbor] = 0
							neighbors[neighbor] += 1
	
	# 가장 큰 인접 지역 반환
	var largest_neighbor = -1
	var max_size = 0
	for neighbor in neighbors.keys():
		if region_sizes.get(neighbor, 0) > max_size:
			max_size = region_sizes[neighbor]
			largest_neighbor = neighbor
	
	return largest_neighbor


## 지역 병합
func merge_regions(from_region: int, to_region: int):
	for x in range(map_width):
		for y in range(map_height):
			if region_map[x][y] == from_region:
				region_map[x][y] = to_region
	
	# 크기 업데이트
	if region_sizes.has(to_region):
		region_sizes[to_region] += region_sizes.get(from_region, 0)
	region_sizes.erase(from_region)


## 바다/육지 결정 (DST 스타일: Noise 기반)
func determine_land_and_sea():
	var land_count = 0
	var sea_count = 0
	
	for x in range(map_width):
		for y in range(map_height):
			var noise_value = calculate_land_noise(x, y)
			
			# 해수면 임계값 (0.35로 바다 20-30%)
			if noise_value < 0.35:
				region_map[x][y] = -1  # 바다로 표시
				generated_map[x][y] = 5  # 바다 타일
				sea_count += 1
			else:
				land_count += 1
	
	var total = map_width * map_height
	if debug_mode:
		print("  🌊 바다/육지 생성: 바다 %d (%.1f%%), 육지 %d (%.1f%%)" % [
			sea_count, sea_count * 100.0 / total,
			land_count, land_count * 100.0 / total
		])


## 복합 노이즈 계산 (DST + OpenSimplexNoise)
func calculate_land_noise(x: int, y: int) -> float:
	var center = Vector2(map_width / 2.0, map_height / 2.0)
	var pos = Vector2(x, y)
	
	# 1. 중심으로부터의 거리 (중앙 육지)
	var distance_from_center = pos.distance_to(center)
	var max_distance = min(map_width, map_height) / 2.0
	var normalized_distance = distance_from_center / max_distance
	# 2.2제곱으로 적당히 급격하게
	var distance_factor = 1.0 - pow(normalized_distance, 2.2)
	
	# 2. OpenSimplexNoise (자연스러운 해안선)
	var noise_value = height_noise.get_noise_2d(x, y)
	
	# 3. 혼합 (70% 거리, 30% Noise)
	var final_value = distance_factor * 0.7 + noise_value * 0.3
	
	# 0~1 범위로 클램프
	return clampf(final_value, 0.0, 1.0)


## 각 지역에 바이옴 할당 (DST 스타일: 다양한 바이옴)
func assign_biomes_to_regions():
	var biome_weights = {
		1: 30,  # grass (초원) - 가장 흔함
		2: 25,  # forest (숲) - 두 번째로 흔함
		3: 15,  # desert (사막)
		6: 10,  # swamp (늪)
		7: 10,  # snow (설원)
		4: 10   # rocky (바위 지대)
	}
	
	var adjacency = build_adjacency_map()
	var assigned_regions = []
	
	# 가장 큰 지역부터 시작
	var sorted_regions = region_sizes.keys()
	sorted_regions.sort_custom(func(a, b): return region_sizes[a] > region_sizes[b])
	
	for region in sorted_regions:
		if region == -1:  # 바다 제외
			continue
		
		# 이 지역이 바다인지 확인 (대부분 바다 타일인 경우)
		if check_if_sea_region(region):
			continue  # 바다 지역은 건너뛰기
		
		# 인접 지역의 바이옴 확인
		var neighbor_biomes = {}
		if adjacency.has(region):
			for neighbor in adjacency[region]:
				if region_biomes.has(neighbor):
					var biome = region_biomes[neighbor]
					if not neighbor_biomes.has(biome):
						neighbor_biomes[biome] = 0
					neighbor_biomes[biome] += 1
		
		# 인접 지역과 같은 바이옴일 확률 60%
		if neighbor_biomes.size() > 0 and randf() < 0.6:
			# 가장 많은 인접 바이옴 선택
			var most_common_biome = 1
			var max_count = 0
			for biome in neighbor_biomes.keys():
				if neighbor_biomes[biome] > max_count:
					max_count = neighbor_biomes[biome]
					most_common_biome = biome
			region_biomes[region] = most_common_biome
		else:
			# 가중치 기반 랜덤 선택
			region_biomes[region] = weighted_random_biome(biome_weights)
		
		assigned_regions.append(region)
	
	# 바다는 sea(5)로 설정
	region_biomes[-1] = 5
	
	if debug_mode:
		print("  🎨 바이옴 할당: %d개 지역" % assigned_regions.size())


## 지역이 대부분 바다인지 확인
func check_if_sea_region(region: int) -> bool:
	var sea_count = 0
	var total_count = 0
	
	for x in range(map_width):
		for y in range(map_height):
			if region_map[x][y] == region:
				total_count += 1
				if generated_map[x][y] == 5:  # 바다 타일
					sea_count += 1
	
	if total_count == 0:
		return false
	
	# 70% 이상이 바다면 바다 지역으로 간주
	return (sea_count * 100.0 / total_count) > 70.0


## 인접 지역 맵 생성
func build_adjacency_map() -> Dictionary:
	var adjacency = {}
	
	for x in range(1, map_width - 1):
		for y in range(1, map_height - 1):
			var region = region_map[x][y]
			if region == -1:
				continue
			
			if not adjacency.has(region):
				adjacency[region] = []
			
			for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
				var nx = x + dir.x
				var ny = y + dir.y
				var neighbor = region_map[nx][ny]
				
				if neighbor != -1 and neighbor != region:
					if not adjacency[region].has(neighbor):
						adjacency[region].append(neighbor)
	
	return adjacency


## 가중치 기반 랜덤 바이옴
func weighted_random_biome(weights: Dictionary) -> int:
	var total = 0
	for w in weights.values():
		total += w
	
	var rand = randf() * total
	var cumulative = 0.0
	
	for biome in weights.keys():
		cumulative += weights[biome]
		if rand <= cumulative:
			return biome
	
	return 1


## 지역 바이옴을 맵에 적용
func apply_biomes_to_map():
	for x in range(map_width):
		for y in range(map_height):
			var region = region_map[x][y]
			if region_biomes.has(region):
				generated_map[x][y] = region_biomes[region]
	
	if debug_mode:
		print("  ✅ 바이옴 적용 완료")


## 바이옴 간 연결 통로 생성 (DST 스타일)
func create_biome_connections():
	var adjacency = build_adjacency_map()
	var connection_count = 0
	
	# 각 바이옴 지역의 중심점 계산
	var region_centers = {}
	for region in region_sizes.keys():
		if region == -1:  # 바다 제외
			continue
		region_centers[region] = calculate_region_center(region)
	
	# 인접한 바이옴 사이에 통로 생성
	for region in adjacency.keys():
		if region == -1 or not region_centers.has(region):
			continue
		
		for neighbor in adjacency[region]:
			if neighbor == -1 or not region_centers.has(neighbor):
				continue
			
			# 이미 처리한 쌍은 건너뛰기 (양방향 중복 방지)
			if region > neighbor:
				continue
			
			# 두 바이옴 중심 사이에 통로 생성
			create_path_between_regions(region_centers[region], region_centers[neighbor])
			connection_count += 1
	
	if debug_mode:
		print("  🛤️ 바이옴 연결 통로: %d개 생성" % connection_count)


## 지역의 중심점 계산
func calculate_region_center(region: int) -> Vector2i:
	var sum_x = 0
	var sum_y = 0
	var count = 0
	
	for x in range(map_width):
		for y in range(map_height):
			if region_map[x][y] == region:
				sum_x += x
				sum_y += y
				count += 1
	
	if count == 0:
		return Vector2i(map_width / 2, map_height / 2)
	
	return Vector2i(sum_x / count, sum_y / count)


## 두 지점 사이에 통로 생성
func create_path_between_regions(from: Vector2i, to: Vector2i):
	var steps = int(from.distance_to(to) * 0.5)  # 중간 지점만 연결
	
	for step in range(steps + 1):
		var t = float(step) / float(steps) if steps > 0 else 0.0
		var pos = Vector2i(
			int(lerp(from.x, to.x, t)),
			int(lerp(from.y, to.y, t))
		)
		
		# 통로 폭 (2~3 타일)
		var path_width = 1
		
		for dx in range(-path_width, path_width + 1):
			for dy in range(-path_width, path_width + 1):
				var x = pos.x + dx
				var y = pos.y + dy
				
				if x >= 0 and x < map_width and y >= 0 and y < map_height:
					# 바다만 육지로 변경 (기존 바이옴은 유지)
					if generated_map[x][y] == 5:
						# 인접한 육지 바이옴 타입 사용
						var nearby_biome = get_nearby_land_biome(x, y)
						if nearby_biome != 5:
							generated_map[x][y] = nearby_biome


## 주변 육지 바이옴 찾기
func get_nearby_land_biome(x: int, y: int) -> int:
	for radius in range(1, 4):
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				var nx = x + dx
				var ny = y + dy
				if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
					var biome = generated_map[nx][ny]
					if biome != 5:  # 바다가 아니면
						return biome
	return 1  # 기본값: grass


## 경계 부드럽게 (DST 스타일: 육지 연결성 강화)
func smooth_boundaries(iterations: int = 5):  # 3 → 5회로 증가
	for _i in range(iterations):
		var new_map = []
		
		for x in range(map_width):
			var row = []
			for y in range(map_height):
				row.append(generated_map[x][y])
			new_map.append(row)
		
		for x in range(1, map_width - 1):
			for y in range(1, map_height - 1):
				if generated_map[x][y] == 5:  # 바다는 건드리지 않음
					continue
				
				# 스무딩 확률 증가 (0.25 → 0.4)
				if randf() < 0.4:
					var most_common = get_most_common_neighbor(x, y)
					if most_common != 5:
						new_map[x][y] = most_common
		
		generated_map = new_map
	
	if debug_mode:
		print("  ✨ 경계 부드럽게: %d회 반복" % iterations)


## 주변 타일 중 가장 많은 타입
func get_most_common_neighbor(x: int, y: int) -> int:
	var counts = {}
	
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			
			var nx = x + dx
			var ny = y + dy
			
			if nx >= 0 and nx < map_width and ny >= 0 and ny < map_height:
				var biome = generated_map[nx][ny]
				if not counts.has(biome):
					counts[biome] = 0
				counts[biome] += 1
	
	var most_common = generated_map[x][y]
	var max_count = 0
	
	for biome in counts.keys():
		if counts[biome] > max_count:
			max_count = counts[biome]
			most_common = biome
	
	return most_common


## 바이옴 통계
func print_biome_statistics():
	var counts = {}
	
	for x in range(map_width):
		for y in range(map_height):
			var biome = generated_map[x][y]
			if not counts.has(biome):
				counts[biome] = 0
			counts[biome] += 1
	
	print("\n📊 [바이옴 통계]")
	var biome_names = {
		0: "빈 공간",
		1: "grass (초원)",
		2: "dirt (흙)",
		3: "sand (모래)",
		4: "nothing (빈 타일)",
		5: "sea (바다)",
		6: "shore (해변)"
	}
	
	for biome in counts.keys():
		var name = biome_names.get(biome, "알 수 없음")
		var count = counts[biome]
		var percentage = (float(count) / (map_width * map_height)) * 100.0
		print("  %s: %d 타일 (%.1f%%)" % [name, count, percentage])
	print("")
