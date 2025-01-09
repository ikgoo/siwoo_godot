extends Node2D

var grass_tilemap: TileMap
var dirt_tilemap: TileMap
var growth_timer: Timer
var spread_chance = 0.3
var growth_positions = []  

@onready var timer = $Timer

func _ready():
	timer.start()
	grass_tilemap = $grass
	dirt_tilemap = $dirt
	growth_timer = Timer.new()
	add_child(growth_timer)
	growth_timer.wait_time = 1.0  
	growth_timer.start()

func _on_timer_timeout() -> void:
	var grass_cells = grass_tilemap.get_used_cells(0)
	var dirt_cells = dirt_tilemap.get_used_cells(0)
	var new_grass_positions = []
	
	# 4방향 체크를 위한 방향 벡터
	var directions = [
		Vector2i(0, -1),  # 상
		Vector2i(0, 1),   # 하
		Vector2i(-1, 0),  # 좌
		Vector2i(1, 0)    # 우
	]
	
	for grass_pos in grass_cells:
		for direction in directions:
			if randi_range(0,5) == 0:
				var check_pos = Vector2i(grass_pos.x + direction.x, grass_pos.y + direction.y)
				
				# 흙 타일이 실제로 존재하는지 확인
				if check_pos in dirt_cells:
					var dirt_cell = dirt_tilemap.get_cell_source_id(0, check_pos)
					var grass_cell = grass_tilemap.get_cell_source_id(0, check_pos)
					var dirt_atlas_coords = dirt_tilemap.get_cell_atlas_coords(0, check_pos)
					
					# 흙 타일이 실제로 있고, 아직 풀이 없는 위치인지 확인
					if randf() < spread_chance:
						new_grass_positions.append(check_pos)
		
		# 새로운 풀을 한 번에 생성하고 terrain 연결
		var positions_to_update = new_grass_positions
		for new_pos in new_grass_positions:
			growth_positions.append(new_pos)
		
		# 모든 새로운 위치에 대해 한 번에 terrain 연결 설정
		if positions_to_update.size() > 0:
			grass_tilemap.set_cells_terrain_connect(0, positions_to_update, 0, 0)
