extends GridMap

## shore 타일 ID (MeshLibrary에서 확인 필요)
@export var shore_tile_id: int = 6  # shore 타일 ID
@export var shore_underwater_tile_id: int = 7  # shore_underwater 타일 ID

## shore 변경 기능 활성화 여부
@export var enable_shore_change: bool = true

## shore 타일 위치들을 저장하는 배열
var shore_positions: Array[Vector3i] = []

## 현재 shore 상태 (true: 낮-shore, false: 밤-shore_underwater)
var is_shore_above_water: bool = true

## 이전 시간대 저장 (변화 감지용)
var previous_time: Globals.time_of_day = Globals.time_of_day.day

# Called when the node enters the scene tree for the first time.
func _ready():
	var grid = GridOn.grid
	for i in range(len(grid)):
		for j in range(len(grid[i])):
			var tile_id = grid[i][j]
			var pos = Vector3i(j, 0, i)
			set_cell_item(pos, tile_id)
	
	# GridMap에 실제로 배치된 타일에서 shore 찾기
	call_deferred("find_shore_tiles")

## GridMap이 완전히 준비된 후 shore 타일 찾기
func find_shore_tiles():
	shore_positions.clear()
	
	# GridMap의 모든 사용된 셀 가져오기
	var used_cells = get_used_cells()
	
	for cell_pos in used_cells:
		var tile_id = get_cell_item(cell_pos)
		
		# shore 타일이거나 shore_underwater 타일이면 위치 저장
		if tile_id == shore_tile_id or tile_id == shore_underwater_tile_id:
			shore_positions.append(cell_pos)
	
	print("🌊 [GridMap] shore 타일 개수: ", shore_positions.size())
	
	# 초기 시간대에 맞춰 shore 타일 설정
	check_and_update_shore_tiles()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# shore 변경 기능이 활성화되어 있을 때만 실행
	if not enable_shore_change:
		return
	
	# 시간대 변화 감지
	if Globals.now_time != previous_time:
		check_and_update_shore_tiles()
		previous_time = Globals.now_time


## 시간대에 따라 shore 타일을 업데이트하는 함수
## 낮(day, afternoon): shore 타일
## 밤(night, midnight): shore_underwater 타일
func check_and_update_shore_tiles():
	# 낮인지 밤인지 확인
	var should_be_above_water = (Globals.now_time == Globals.time_of_day.day or 
								  Globals.now_time == Globals.time_of_day.afternoon)
	
	print("🌊 [GridMap] 시간대 체크 - 현재: %s, 물 위 여부: %s -> %s" % [Globals.now_time, is_shore_above_water, should_be_above_water])
	
	# 상태가 변경되었으면 타일 업데이트
	if should_be_above_water != is_shore_above_water:
		is_shore_above_water = should_be_above_water
		update_all_shore_tiles()
	else:
		print("🌊 [GridMap] 상태 변경 없음 - 업데이트 생략")


## 모든 shore 타일을 현재 시간대에 맞게 업데이트
func update_all_shore_tiles():
	var target_tile_id = shore_tile_id if is_shore_above_water else shore_underwater_tile_id
	var state_name = "shore (물 위)" if is_shore_above_water else "shore_underwater (물 속)"
	
	for pos in shore_positions:
		set_cell_item(pos, target_tile_id)
	
	print("🌊 [GridMap] shore 타일 변경: %s (총 %d개)" % [state_name, shore_positions.size()])
