extends Node2D
var grass_tilemap: TileMap
var dirt_tilemap: TileMap
var growth_timer: Timer
var spread_chance = 0.3
var time_since_last_spawn = 0.0
@onready var area_2d = $Area2D
var water_p = {}
var tempe_p = {}
var terrain_p = {}
@onready var hahaha = $hahaha
const TREE_L = preload("res://tree_l.tscn")
var w_tf = false
var directions = [
	Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)
]

var s_type
var seed = null
var tempe = 59.9
var no_water = true
const GGUN = preload("res://ggun.tscn")
var value_ws = 10
@onready var camera_2d = $Camera2D
@onready var grass_detail = $grass_detail
var type = null
@onready var timer = $Timer
var tree_scene = preload("res://tree_l.tscn")
var edge_grass = []
var start_pos: Vector2i = Vector2i(0,0)
var water_val = {}
var thing_val = {}
var kl_ok = false
var t_tf = false
var o_tf = false
var grass_ok = false
var trees = {}
var all_thing = {}
var now_worm
var worms = []
var worm_jip = false
var no_seed = false
var onshil = 0
var seed_click = true
var mouse_on_s = false
var grass_thing = null
@onready var ui = $CanvasLayer/UI/CanvasLayer/UI
@onready var g_timer = $g_timer

#화암균 (고온 생존)
#빙환균 (극한 저온 생존)

var fire_tile = {}

var nearby_tiles
const MAX_WORMS = 1000  # 최대 균 수량 설정

# 나무 종류별 필요 산소량 정의
const TREE_OXYGEN_REQUIREMENTS = {
	"warm": {"min": 15, "max": 30},  # 온대 참나무: 15~30%
	"fire": {"min": 10, "max": 20},  # 열대 선인장: 10~20% (건조 적응)
	"snow": {"min": 20, "max": 35},  # 설원 소나무: 20~35% (추위 적응)
	"rain": {"min": 25, "max": 40}   # 습지 맹그로브: 25~40% (높은 산소 요구)
}

# 지형별 필요 조건 정의
const TERRAIN_REQUIREMENTS = {
	"warm": {  # 온화지대
		"water": {"min": 40, "max": 90},  # 물 50~80
		"tempe": {"min": 10, "max": 35}   # 온도 10~35
	},
	"fire": {  # 열대지형
		"water": {"min": 20, "max": 70},  # 물 30~60
		"tempe": {"min": 25, "max": 60}   # 온도 35~60
	},
	"snow": {  # 설원지형
		"water": {"min": 40, "max": 90},  # 물 50~80
		"tempe": {"min": 5, "max": 25}    # 온도 15~25
	},
	"rain": {  # 습지대
		"water": {"min": 50, "max": 100}, # 물 60~100
		"tempe": {"min": 10, "max": 35}   # 온도 20~35
	}
}

# 변수 추가
var grass_feeling_active = false  # 풀의 느낌 타일 활성화 상태
var previous_all_thing = {}  # 이전 상태 저장용
var previous_thing_val = {}  # 풀 상태 저장용

# 자주 사용되는 상수들을 미리 캐시
const TILE_SIZE = Vector2i(16, 16)  # 타일 크기
const SCREEN_MARGIN = 2  # 화면 여백

# 타일이 새로 놓였는지 체크하는 변수 추가
var newly_placed_tiles = {}

func _ready():
	timer.start()
	grass_tilemap = $grass
	dirt_tilemap = hahaha.tile_map
	grass_tilemap.clear()
	grass_tilemap.clear_layer(3)
	
	if hahaha.tile_map.get_cell_tile_data(1,Vector2(0,0)):
		all_thing[Vector2i(0,0)] = {"water":200,"tempe":100,"oxyen":100}
	for i in range(0,32):
		for ic in range(0,32):
			all_thing[Vector2i(ic,i)] = {"water":0,"tempe":100,"oxyen":0}
	if grass_ok:
		thing_val[Vector2i(0,0)] = {"water":1,"tempe":0,"terrain":"산악지대","tree":false,"fire":false}
		timer.start()
		var done = false
		grass_tilemap.set_cell(0, Vector2i(0,0), 0, Vector2i(0,0))
		edge_grass.append(Vector2i(0,0))

	#update_cell_cache()

	grass_tilemap.set_layer_enabled(7, true)  # 7번 레이어 활성화
	grass_tilemap.set_layer_modulate(7, Color(1, 1, 1, 1))  # 7번 레이어 투명도 설정
	previous_all_thing = all_thing.duplicate(true)  # 깊은 복사로 초기화
	previous_thing_val = thing_val.duplicate(true)  # 풀 상태도 초기화

#func update_cell_cache():
	#grass_cells_cache = grass_tilemap.get_used_cells(0)
	#
	#dirt_cells_cache = dirt_tilemap.get_used_cells(0)

#func is_edge_cell(pos: Vector2i, grass_cells: Array) -> bool:
	#for direction in directions:
		#if not (pos + direction) in grass_cells:
			#return true
	#return false


var dic_check = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1),
]

var previous_tile_pos = null
var tiles = []

func get_tiles_in_radius():
	var camera = get_viewport().get_camera_2d()
	var zoom = camera.zoom
	var mouse_position = camera.get_global_position() + ((get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2) / zoom)
	
	# 마우스 위치를 타일맵 좌표로 변환
	var current_tile_pos = grass_tilemap.local_to_map(grass_tilemap.to_local(mouse_position))
	
	# 현재 위치를 이전 위치로 저장
	previous_tile_pos = current_tile_pos
	
	# 새로운 타일 배열 생성
	tiles.clear()
	
	# 반경 3칸을 순회 (-3 ~ +3)
	for x in range(-3, 4):
		for y in range(-3, 4):
			# 3칸 이내의 모든 타일 포함 (맨해튼 거리 사용)
			if abs(x) + abs(y) <= 3:
				var check_pos = Vector2i(current_tile_pos.x + x, current_tile_pos.y + y)
				# thing_val에 해당 위치가 있는지 확인
				if all_thing.has(check_pos):
					tiles.append(check_pos)
	
	return tiles

func _process(_delta):
	grass_tilemap.clear_layer(4)
	if seed:
		if Gamemanger.my_thing:
			type = null
			
			ui.water_t_on_o = false
			ui.tempe_t_on_o = false
			ui.oxyen_t_on_o = false
			ui.animation_player.play("coming_down")
			ui.up_down = "down"
			Gamemanger.my_thing = null
		var camera = get_viewport().get_camera_2d()
		var zoom = camera.zoom
		var mouse_position = camera.get_global_position() + ((get_viewport().get_mouse_position() - get_viewport().get_visible_rect().size / 2) / zoom)
		var current_tile_pos = grass_tilemap.local_to_map(grass_tilemap.to_local(mouse_position))
		grass_tilemap.set_cell(4, current_tile_pos, 2, Vector2i(0,0))
	if worm_jip:
		now_worm.global_position = get_global_mouse_position()
	

	
	nearby_tiles = get_tiles_in_radius()
	for tile_pos in nearby_tiles:
		if type:
			grass_tilemap.set_cell(4, tile_pos, 2, Vector2i(0,0))
			if kl_ok:
				if type == "water":
					water_up()
				if type == "sun":
					for i in nearby_tiles:
						if all_thing.has(i):
							if tempe < 60:
								if all_thing[i]["water"] - ui.h_slider.value / 1000  > 0:
									all_thing[i]["water"] -= ui.h_slider.value / 1000
					if tempe < 60:
						if onshil > 0:
							onshil -= ui.h_slider.value / 100000
				

func calculate_distance(pos1: Vector2i, pos2: Vector2i) -> float:
	var dx = pos1.x - pos2.x
	var dy = pos1.y - pos2.y
	return sqrt(dx * dx + dy * dy)
	
func insert_sorted_by_distance(new_pos: Vector2i):
	var new_distance = calculate_distance(start_pos, new_pos)
	
	# If edge_grass is empty, just append
	if edge_grass.is_empty():
		edge_grass.append(new_pos)
		return
	
	# Find the correct position to insert
	var insert_index = 0
	for i in range(edge_grass.size()):
		var current_distance = calculate_distance(start_pos, edge_grass[i])
		if new_distance < current_distance:
			insert_index = i
			break
		if i == edge_grass.size() - 1:
			insert_index = edge_grass.size()
	
	# Insert at the found position
	edge_grass.insert(insert_index, new_pos)


func _on_timer_timeout():
	# 전체 상태를 복사하는 대신 변경된 타일만 추적
	var changed_tiles = {}
	
	# worms 처리를 최적화
	var worm_positions = {}
	for worm in worms:
		var pos = round(worm.global_position / 16)
		if all_thing.has(pos):
			if not worm_positions.has(pos):
				worm_positions[pos] = []
			worm_positions[pos].append(worm)
	
	# 위치별로 한번에 처리
	for pos in worm_positions:
		var total_oxygen_change = 0
		for worm in worm_positions[pos]:
			if worm.is_oxygen_remover:
				total_oxygen_change -= 2
			elif worm.is_onshil_creator:
				onshil -= 0.002
			elif worm.is_onshil_remover:
				onshil += 0.002
			else:
				onshil += 0.0005
				total_oxygen_change += 1
		
		all_thing[pos]["oxyen"] = clamp(all_thing[pos]["oxyen"] + total_oxygen_change, 0, 99)

	if grass_ok:
		if randi_range(0,10) == 1:
			on_fire()

		fire_spread()
		
		spawn_tree()
	if grass_thing:
		var requirements = TERRAIN_REQUIREMENTS[grass_thing]
		print(requirements["tempe"]["min"] - 10,requirements["tempe"]["max"] + 10)
		if tempe > requirements["tempe"]["min"] - 10 or tempe < requirements["tempe"]["max"] + 10:
			if not len(thing_val.keys()) >= 5000:
				for i in range(0,randi_range(1, min(10, len(edge_grass)))):
					var select = edge_grass[randi_range(0,edge_grass.size()-1)]
					var attamp = 0
					var tt = [0, 1, 2, 3]
					while true:
						if tt.size() == 0:
							kill_edge_grass(select)
							break
							
						var a = randi_range(0,tt.size()-1)
						var dir = tt[a]
						tt.remove_at(a)
						var new_pos = select + dic_check[dir]
						
						# 새로운 위치가 자랄 수 있는지 확인
						
						var has_tile = dirt_tilemap.get_cell_source_id(0, new_pos) != -1
						var has_tile_d = dirt_tilemap.get_cell_source_id(2, new_pos) != -1
						if has_tile or has_tile_d:
							if not has_tile_d:
								water_val[new_pos] = thing_val[select]["water"]
							
							grass_tilemap.set_cells_terrain_connect(0,[new_pos], 0, 0)
							thing_val[new_pos] = {
								"water": max(0,min(100, thing_val[select]["water"] + randi_range(-5,-1))),
								"terrain":s_type,
								"tree":false,
								"fire":false
							}
							insert_sorted_by_distance(new_pos)
				grass_tilemap.set_cells_terrain_connect(0,[edge_grass[0]], 0, 0)
	if w_tf:
		water_tile()
	elif o_tf:
		oxyen_tile()
			
	
				
	$Timer.start()
	
func kill_edge_grass(pos: Vector2i):
	for i in edge_grass.size()-1:
		if edge_grass[i] == pos:
			edge_grass.remove_at(i)
			break
			
func check_full_grass(pos: Vector2i):
	for i in dic_check:
		var tile_data = grass_tilemap.get_cell_tile_data(0, pos + i)
		var water_tile = hahaha.tile_map.get_cell_tile_data(1,pos + i)

		if not tile_data and not water_tile:
			return false
	return true



func spawn_tree():
	if not grass_thing:
		return
		
	var visible_range = get_visible_tile_range()
	var requirements = TREE_OXYGEN_REQUIREMENTS[grass_thing]
	
	for x in range(visible_range.start.x, visible_range.end.x):
		for y in range(visible_range.start.y, visible_range.end.y):
			var pos = Vector2i(x, y)
			if not thing_val.has(pos) or thing_val[pos]["tree"]:
				continue
				
			if randi_range(0,1000) != 1:
				continue
				
			var oxygen_level = all_thing[pos]["oxyen"]
			if oxygen_level >= requirements["min"] and oxygen_level <= requirements["max"]:
				_create_tree(pos)

func _create_tree(pos: Vector2i):
	var tree = tree_scene.instantiate()
	var global_pos = grass_tilemap.map_to_local(pos)
	tree.global_position = global_pos + Vector2(randi_range(-5,5), randi_range(-5,5))
	add_child(tree)
	tree.pos = pos
	trees[pos] = tree
	thing_val[pos]["tree"] = true
	tree.sp_sprite(grass_thing)
	
	if thing_val[pos]["fire"]:
		tree.animation_player.play("on_fire_up")

func _input(event):
	if event is InputEventMouseButton:
		var camera = get_viewport().get_camera_2d()
		
		var zoom = camera.zoom
		var mouse_position = camera.get_global_position() + ((event.position - get_viewport().get_visible_rect().size / 2) / zoom)
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			
			var query = PhysicsPointQueryParameters2D.new()
			query.collision_mask = 4
			query.position = mouse_position
			
			var result = get_world_2d().direct_space_state.intersect_point(query)
			var local_pos = grass_tilemap.to_local(mouse_position)
			var tile_pos = Vector2i(
				floor(local_pos.x / grass_tilemap.tile_set.tile_size.x),
				floor(local_pos.y / grass_tilemap.tile_set.tile_size.y)
			)
			if not result.is_empty():
				var global_tile = grass_tilemap.local_to_map(grass_tilemap.to_local(mouse_position))
				grass_detail.thing_get(thing_val[global_tile]["terrain"],all_thing[global_tile]["water"],all_thing[global_tile]["oxyen"])
				grass_detail.visible = true
			else:
				var tile_pos_l = Vector2i(floor(tile_pos.x), floor(tile_pos.y))
				if all_thing.has(tile_pos_l):
					grass_detail.thing_get("빈땅", all_thing[tile_pos_l]["water"],all_thing[tile_pos_l]["oxyen"])
					grass_detail.visible = true
				
		# 여기서 tiles 배열을 사용하여 원하는 작업을 수행할 수 있습니다
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			kl_ok = true


					
		elif event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			kl_ok = false
			
			
#func _input(event):
	#
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		#var camera = get_viewport().get_camera_2d()
		#var mouse_position = event.position
		
		#if camera:
			#var zoom = camera.zoom
			#mouse_position = camera.get_global_position() + ((event.position - get_viewport().get_visible_rect().size / 2) / zoom)
			#print(mouse_position)
			#
		#var query = PhysicsPointQueryParameters2D.new()
		#
		#query.position = mouse_position
		#
		#area_2d.monitorable = true
		#area_2d.monitoring = true
		#area_2d.position = mouse_position
		#
		#query.collide_with_bodies = true
		#query.collision_mask = 4  # TileMap의 physics layer와 같은 값으로 설정
		#
		#var result = get_world_2d().direct_space_state.intersect_point(query)
		#
		#if not result.is_empty():
			#var tile_pos = result[0].collider.local_to_map(get_global_mouse_position())
			#var tile_data = result[0].collider.get_cell_tile_data(0, tile_pos)
			#if tile_data:
				#var value = tile_data.get_custom_data("water")
				#print(value,"z")
			#water_p[tile_pos] += 1
			#grass_detail.position = mouse_position
			#grass_detail.thing_get(result[0].collider.water + 10,45,56)
	#area_2d.monitorable = false
	#area_2d.monitoring = false
	

#$TileMap.set_cell_custom_metadata(0, Vector2i(x, y), {"water_content": 50})
#
## 메타데이터 읽기
#var metadata = $TileMap.get_cell_custom_metadata(0, Vector2i(x, y))
#var water_content = metadata.water_content

func river_water():
			
	if not no_water:
		for i in dirt_tilemap.get_used_cells(1):
			all_thing[i]["water"] = 100
	for i in all_thing:
		
		for x in dic_check:
			if all_thing.has(i+x):
				if all_thing[i]["water"] - 5 > all_thing[i+x]["water"] and not all_thing[i+x]["water"] < 0:
					all_thing[i+x]["water"] += 2
					all_thing[i]["water"] -= 2



func _on_timer_2_timeout():
	area_2d.monitorable = false
	area_2d.monitoring = false

func water_tile_load(tf:bool):
	t_tf = false
	o_tf = false
	w_tf = tf
	
func oxyen_tile_load(tf:bool):
	t_tf = false
	w_tf = false
	o_tf = tf

	

func water_tile():
	var visible_range = get_visible_tile_range()
	for x in range(visible_range.start.x, visible_range.end.x):
		for y in range(visible_range.start.y, visible_range.end.y):
			var pos = Vector2i(x, y)
			if not all_thing.has(pos):
				continue
				
			var needs_update = newly_placed_tiles.has(pos)
			if not needs_update and previous_all_thing.has(pos):
				var prev_water = previous_all_thing[pos]["water"]
				if abs(int(all_thing[pos]["water"] / 10) - int(prev_water / 10)) > 0:
					needs_update = true
			
			if needs_update or not previous_all_thing.has(pos):
				var water_value = all_thing[pos]["water"]
				if water_value > 0:
					var water_level = min(int(water_value / 10), 11)
					grass_tilemap.set_cell(1, pos, 0, Vector2i(1,1), water_level)
				else:
					grass_tilemap.set_cell(1, pos, -1)

func oxyen_tile():
	var visible_range = get_visible_tile_range()
	for x in range(visible_range.start.x, visible_range.end.x):
		for y in range(visible_range.start.y, visible_range.end.y):
			var pos = Vector2i(x, y)
			if not all_thing.has(pos):
				continue
				
			var needs_update = newly_placed_tiles.has(pos)
			if not needs_update and previous_all_thing.has(pos):
				var prev_oxygen = previous_all_thing[pos]["oxyen"]
				if abs(int(all_thing[pos]["oxyen"] / 5) - int(prev_oxygen / 5)) > 0:
					needs_update = true
			
			if needs_update or not previous_all_thing.has(pos):
				var oxygen = all_thing[pos]["oxyen"]
				if oxygen > 0:
					grass_tilemap.set_cell(6, pos, 2, Vector2i(0,0), int(oxygen/5) + 1)
				else:
					grass_tilemap.set_cell(6, pos, -1)

func change_grass(pos):
	var x = grass_tilemap.get_cell_tile_data(2,pos)
	if x:

		grass_tilemap.erase_cell(2,pos)
		grass_tilemap.set_cells_terrain_connect(0,[pos], 0, 0)
		for i in dic_check:
			if grass_tilemap.get_cell_tile_data(2,pos+i):
				grass_tilemap.set_cells_terrain_connect(2,[pos+i], 0, 0)
			
			

func tempe_tile_load(tf:bool):
	w_tf = false
	o_tf = false
	t_tf = tf
	grass_tilemap.clear_layer(1)
	grass_tilemap.clear_layer(3)
	grass_tilemap.clear_layer(6)

func water_up():

	if nearby_tiles:
		for i in nearby_tiles:

				
				
				
				
			if all_thing.has(i):
				if len(fire_tile) == 1:
					
					if all_thing[i]["fire"]:
						ui.pop_up_on("fire_off")
				if len(fire_tile) > 1:
					all_thing[i]["fire"] = false
					fire_tile.erase(i)
				if tempe > 60:
					if onshil > 0:
						onshil -= ui.h_slider.value / 1000000


			if trees.has(i):
				
				if trees[i].fire >= 0:
					trees[i].animation_player.play("RESET")
					trees[i].fire = 0
					



func on_fire():
	if false:
		if trees:
			ui.pop_up_on("fire")
			var firen = trees.keys()[randi_range(0,trees.size()-1)]
				
			if trees.has(firen):
				trees[firen].fire_a()
				fire_tile[firen] = 0

func oxyen_spread():
	for i in all_thing:
		if not all_thing[i]["oxyen"] == 0:
			var ic = dic_check[randi_range(0,3)]
			if all_thing.has(i+ic):
				# 산소 확산
				if all_thing[i+ic]["oxyen"] + 1 < all_thing[i]["oxyen"]:
					all_thing[i]["oxyen"] -= 2
					all_thing[i+ic]["oxyen"] += 2
				
				# 열 분산 (산소 농도차에 비례)
						


func fire_spread():

	if not len(fire_tile) >= 10000000000000:
		
		for i in fire_tile:
			for ic in dic_check:
				if randi_range(0,15) == 1:
					if thing_val.has(i+ic):
						if not fire_tile.has(i+ic):
							fire_tile[i+ic] = 0
							thing_val[i+ic]["fire"] = true
							
						
							if trees.has(i+ic):
								trees[i+ic].fire_a()
			
func oxyen_tempe():
	if onshil > 20:
		tempe += 0.1
	if onshil > 40:
		tempe += 0.5
	if onshil > 50:
		tempe += 1
	if onshil > 100:
		tempe += 1
	if onshil > 150:
		tempe == 2
	if onshil > 200:
		tempe += 5
	if onshil >= 400:
		tempe += 10
	if onshil > 500:
		tempe += 50
	for i in all_thing:
		if all_thing[i]["oxyen"] >= 20 and all_thing[i]["oxyen"] < 25:
			if tempe > 40:
				tempe -= 0.0005
		if all_thing[i]["oxyen"] >= 30 and all_thing[i]["oxyen"] >= 35:
			if tempe > 15:
				tempe -= 0.001



func is_water_tile(pos):
	var r_pos = grass_tilemap.local_to_map(grass_tilemap.to_local(pos))
	var w_pos = dirt_tilemap.get_used_cells(1)
	if w_pos.has(r_pos):
		return false
	return true


func set_seed(seed_s,pos):
	var thing

	match seed_s:
		"warm":
			s_type = "온화지대"
			thing = "warm"
			grass_tilemap.set_layer_modulate(0, Color(0.8, 1, 0.6))
		"fire":
			s_type = "열대지형"
			thing = "fire"
			grass_tilemap.set_layer_modulate(0, Color(1, 0.85, 0.55))
		"snow":
			s_type = "설원지형"
			thing = "snow"
			grass_tilemap.set_layer_modulate(0, Color(0.9, 0.95, 0.95))
		"rain":
			s_type = "습지대"
			thing = "rain"
			grass_tilemap.set_layer_modulate(0, Color(0.6, 0.75, 0.7))
	grass_thing = thing
	
	thing_val[pos] = {"water":1,"terrain":s_type,"tree":false,"fire":false}
	var done = false
	grass_tilemap.set_cell(0, pos, 0, Vector2i(1,1))
	edge_grass.append(pos)
	grass_ok = true

func remove_all_worms():
	# 모든 미생물 객체 제거
	for worm in worms:
		if is_instance_valid(worm):  # 객체가 아직 유효한지 확인
			worm.queue_free()  # 씬에서 제거
	
	# worms 배열 비우기
	worms.clear()
	
	# now_worm 초기화
	now_worm = null

# 균 생성 가능 여부 확인 함수 추가
func can_add_worm() -> bool:
	return worms.size() <= MAX_WORMS

# 풀이 자랄 수 있는지 확인하는 함수 수정



func grass_feeling_tile():
	# 변경된 타일만 업데이트
	var visible_range = get_visible_tile_range()
	var grass_tiles = grass_tilemap.get_used_cells_by_area(0, Rect2i(
		visible_range.start.x, visible_range.start.y,
		visible_range.end.x - visible_range.start.x,
		visible_range.end.y - visible_range.start.y
	))
	
	for grass_pos in grass_tiles:
		if not all_thing.has(grass_pos):
			continue
			
		var water_level = all_thing[grass_pos]["water"]
		var center_oxygen = all_thing[grass_pos]["oxyen"]
		
		var needs_update = newly_placed_tiles.has(grass_pos)
		if not needs_update and previous_all_thing.has(grass_pos):
			var prev_water = previous_all_thing[grass_pos]["water"]
			var prev_oxygen = previous_all_thing[grass_pos]["oxyen"]
			
						# 물과 산소 레벨이 요구조건 범위를 넘어가는지 체크
			var prev_water_state = (prev_water < TERRAIN_REQUIREMENTS[grass_thing]["water"]["min"] - 10) or (prev_water > TERRAIN_REQUIREMENTS[grass_thing]["water"]["max"] + 10)
			var curr_water_state = (water_level < TERRAIN_REQUIREMENTS[grass_thing]["water"]["min"] - 10) or (water_level > TERRAIN_REQUIREMENTS[grass_thing]["water"]["max"] + 10)

			var prev_oxygen_state = (prev_oxygen < TREE_OXYGEN_REQUIREMENTS[grass_thing]["min"]) or (prev_oxygen > TREE_OXYGEN_REQUIREMENTS[grass_thing]["max"])
			var curr_oxygen_state = (center_oxygen < TREE_OXYGEN_REQUIREMENTS[grass_thing]["min"]) or (center_oxygen > TREE_OXYGEN_REQUIREMENTS[grass_thing]["max"])
			
			if prev_water_state != curr_water_state or prev_oxygen_state != curr_oxygen_state:
				needs_update = true
		
		if needs_update or not previous_all_thing.has(grass_pos):
			grass_tilemap.set_cell(7, grass_pos, -1)
			
			if water_level < TERRAIN_REQUIREMENTS[grass_thing]["water"]["min"] - 10:
				grass_tilemap.set_cell(7, grass_pos, 4, Vector2i(0, 2))
			elif water_level > TERRAIN_REQUIREMENTS[grass_thing]["water"]["max"] + 10:
				grass_tilemap.set_cell(7, grass_pos, 4, Vector2i(1, 2))
			
			if center_oxygen < TREE_OXYGEN_REQUIREMENTS[grass_thing]["min"]:
				grass_tilemap.set_cell(7, grass_pos, 4, Vector2i(0, 1))
			elif center_oxygen > TREE_OXYGEN_REQUIREMENTS[grass_thing]["max"]:
				grass_tilemap.set_cell(7, grass_pos, 4, Vector2i(1, 1))

# 풀의 느낌 타일 활성화/비활성화 함수
func grass_feeling_tile_load(tf: bool):
	grass_feeling_active = tf
	w_tf = false
	o_tf = false
	t_tf = false
	grass_tilemap.clear_layer(1)
	grass_tilemap.clear_layer(3)
	grass_tilemap.clear_layer(6)
	grass_tilemap.clear_layer(7)  # 풀의 느낌 레이어도 초기화
	
	# 타이머 시작/중지
	if tf:
		g_timer.start()  # 새로운 타이머 시작
	else:
		g_timer.stop()   # 타이머 중지


func _on_g_timer_timeout():
	if grass_feeling_active:
		grass_feeling_tile()

# 화면에 보이는 타일 범위 계산 함수
func get_visible_tile_range() -> Dictionary:
	var camera = get_viewport().get_camera_2d()
	var zoom = camera.zoom
	var screen_size = get_viewport().get_visible_rect().size
	var camera_pos = camera.get_global_position()
	var top_left = camera_pos - (screen_size / (2 * zoom))
	var bottom_right = camera_pos + (screen_size / (2 * zoom))
	
	var tile_top_left = grass_tilemap.local_to_map(grass_tilemap.to_local(top_left))
	var tile_bottom_right = grass_tilemap.local_to_map(grass_tilemap.to_local(bottom_right))
	
	return {
		"start": tile_top_left - Vector2i(SCREEN_MARGIN, SCREEN_MARGIN),
		"end": tile_bottom_right + Vector2i(SCREEN_MARGIN, SCREEN_MARGIN)
	}


func _on_river_timer_timeout():
	river_water()
