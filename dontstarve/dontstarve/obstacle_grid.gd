extends GridMap

## 장애물 설치 추적용 GridMap
## 각 타일에 장애물이 설치되어 있는지 추적합니다
## cell_item이 INVALID_CELL_ITEM이 아니면 해당 타일에 장애물이 있음을 의미합니다
## 
## cell_size = Vector3(0.125, 1, 0.125)
## 지형 GridMap2의 타일 1개(1m x 1m)에 ObstacleGrid 타일 8x8개가 들어갑니다

func _ready():
	# GridMap 초기화
	pass

## 월드 좌표를 그리드 좌표로 변환
## @param world_pos: 월드 좌표 (Vector3)
## @return: 그리드 좌표 (Vector3i)
func world_to_grid(world_pos: Vector3) -> Vector3i:
	var local_pos = to_local(world_pos)
	return Vector3i(
		int(floor(local_pos.x / cell_size.x)),
		int(floor(local_pos.y / cell_size.y)),
		int(floor(local_pos.z / cell_size.z))
	)

## 그리드 좌표를 월드 좌표로 변환 (타일의 중앙)
## @param grid_pos: 그리드 좌표 (Vector3i)
## @return: 월드 좌표 (Vector3)
func grid_to_world(grid_pos: Vector3i) -> Vector3:
	var local_pos = Vector3(
		grid_pos.x * cell_size.x + cell_size.x / 2.0,
		grid_pos.y * cell_size.y,
		grid_pos.z * cell_size.z + cell_size.z / 2.0
	)
	return to_global(local_pos)

## 특정 그리드 타일에 장애물이 있는지 확인
## @param grid_pos: 그리드 좌표 (Vector3i)
## @return: 장애물이 있으면 true, 없으면 false
func has_obstacle_at(grid_pos: Vector3i) -> bool:
	return get_cell_item(grid_pos) != GridMap.INVALID_CELL_ITEM

## 특정 영역에 장애물이 있는지 확인 (obsticle 크기 고려)
## @param center_grid_pos: 중심 그리드 좌표 (Vector3i)
## @param width: 너비 (타일 개수)
## @param height: 높이 (타일 개수)
## @return: 영역 내에 장애물이 하나라도 있으면 true
func has_obstacle_in_area(center_grid_pos: Vector3i, width: int, height: int) -> bool:
	var half_width = floor(width / 2.0)
	var half_height = floor(height / 2.0)
	
	for x in range(-half_width, width - half_width):
		for z in range(-half_height, height - half_height):
			var tile_pos = Vector3i(
				center_grid_pos.x + x,
				center_grid_pos.y,
				center_grid_pos.z + z
			)
			
			if has_obstacle_at(tile_pos):
				return true
	
	return false

## 특정 영역에 장애물 등록 (obsticle 크기 고려)
## @param center_grid_pos: 중심 그리드 좌표 (Vector3i)
## @param width: 너비 (타일 개수)
## @param height: 높이 (타일 개수)
func register_obstacle_area(center_grid_pos: Vector3i, width: int, height: int):
	var half_width = floor(width / 2.0)
	var half_height = floor(height / 2.0)
	
	for x in range(-half_width, width - half_width):
		for z in range(-half_height, height - half_height):
			var tile_pos = Vector3i(
				center_grid_pos.x + x,
				center_grid_pos.y,
				center_grid_pos.z + z
			)
			# 0으로 설정하여 장애물이 있음을 표시
			set_cell_item(tile_pos, 0, 0)

## 특정 영역의 장애물 제거 (obsticle 크기 고려)
## @param center_grid_pos: 중심 그리드 좌표 (Vector3i)
## @param width: 너비 (타일 개수)
## @param height: 높이 (타일 개수)
func unregister_obstacle_area(center_grid_pos: Vector3i, width: int, height: int):
	var half_width = floor(width / 2.0)
	var half_height = floor(height / 2.0)
	
	for x in range(-half_width, width - half_width):
		for z in range(-half_height, height - half_height):
			var tile_pos = Vector3i(
				center_grid_pos.x + x,
				center_grid_pos.y,
				center_grid_pos.z + z
			)
			# INVALID_CELL_ITEM으로 설정하여 타일을 비움
			set_cell_item(tile_pos, GridMap.INVALID_CELL_ITEM)
