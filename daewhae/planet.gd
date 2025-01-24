extends Node2D
var grass_tilemap: TileMap
var dirt_tilemap: TileMap
var growth_timer: Timer
var spread_chance = 0.3
var tree_spawn_cooldown = 0.5  # 나무 생성 쿨다운 추가
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
var worms = {}
var worm_jip = false
@onready var ui = $CanvasLayer/UI

#화암균 (고온 생존)
#빙환균 (극한 저온 생존)

var fire_tile = {}

var nearby_tiles
func _ready():
	grass_tilemap = $grass
	dirt_tilemap = hahaha.tile_map
	grass_tilemap.clear()
	grass_tilemap.clear_layer(3)
	
	
	all_thing[Vector2i(0,0)] = {"water":0,"tempe":100,"oxyen":100}
	for i in range(0,64):
		for ic in range(0,64):
			all_thing[Vector2i(ic,i)] = {"water":0,"tempe":100,"oxyen":0}
	if grass_ok:
		thing_val[Vector2i(0,0)] = {"water":1,"tempe":0,"terrain":"산악지대","tree":false,"fire":false}
		timer.start()
		var done = false
		grass_tilemap.set_cell(0, Vector2i(0,0), 0, Vector2i(0,0))
		edge_grass.append(Vector2i(0,0))

	#update_cell_cache()

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
				if thing_val.has(check_pos):
					tiles.append(check_pos)
	
	return tiles

func _process(_delta):
	grass_tilemap.clear_layer(4)
	if worm_jip:
		now_worm.global_position = get_global_mouse_position()
	
	
	nearby_tiles = get_tiles_in_radius()
	for tile_pos in nearby_tiles:

		if type:
			grass_tilemap.set_cell(4, tile_pos, 2, Vector2i(0,0))
			if kl_ok:
				if type == "water":
					water_up()
				elif type == "tempe":
					tempe_up()

		
		
		
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
	print()
	oxyen_spread()
	for i in worms:
		var this = round(worms[i].global_position / 16)
		this = Vector2i(this)
		if all_thing.has(this):
			all_thing[this]["oxyen"] += 2
			if all_thing[this]["oxyen"] >= 100:
				all_thing[this]["oxyen"] = 100
	var wo = all_thing.keys()[randi_range(0,len(all_thing)-1)]

	if not len(worms) >= 100:
		var worm_s = GGUN.instantiate()
		worm_s.global_position = wo * 16
		
		add_child(worm_s)
		worm_s.on("blue")
		worms[len(worms)+1] = worm_s
		
	if grass_ok:
		if randi_range(0,10) == 1:
			on_fire()

		fire_spread()
		river_water()
		spawn_tree()
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
					var tile_data = []
					var tile_data_layer0 = grass_tilemap.get_cell_tile_data(0, select + dic_check[dir])
					if tile_data_layer0:
						tile_data.append(tile_data_layer0)

					# 레이어 1의 타일 데이터
					var tile_data_layer1 = grass_tilemap.get_cell_tile_data(2, select + dic_check[dir])
					if tile_data_layer1:
						tile_data.append(tile_data_layer1)
					
					if not tile_data:
						var has_tile = dirt_tilemap.get_cell_source_id(0, select + dic_check[dir]) != -1
						var has_tile_d = dirt_tilemap.get_cell_source_id(2, select + dic_check[dir]) != -1
						if has_tile or has_tile_d:
							if not has_tile_d:
								water_val[select + dic_check[dir]] = thing_val[select]["water"]
							var new_temp = min(100, thing_val[select]["tempe"]+randi_range(-1,1))
							var terrain_name = "사막지대" if new_temp > 70 else "산악지대"
							var terrain_type = 1 if new_temp > 70 else 0
							# terrain에 따라 다른 지형을 설정합니다
							if not terrain_type:
								grass_tilemap.set_cells_terrain_connect(0,[select + dic_check[dir]], 0, 0)
							elif terrain_type:
								grass_tilemap.set_cells_terrain_connect(2,[select + dic_check[dir]], 0, 0)
							thing_val[select + dic_check[dir]] = {
								"water": max(0,min(100, thing_val[select]["water"] + randi_range(-5,-1))),
								"tempe": new_temp,
								"terrain": terrain_name,
								"tree":false,
								"fire":false
							}
							insert_sorted_by_distance(select + dic_check[dir])

						
						if check_full_grass(select + dic_check[dir]):
							kill_edge_grass(select + dic_check[dir])
						
						for j in dic_check:
							if check_full_grass(select + dic_check[dir] + j):
								kill_edge_grass(select + dic_check[dir] + j)
								
								
						break
			grass_tilemap.set_cells_terrain_connect(0,[edge_grass[0]], 0, 0)
	if w_tf:
		water_tile()
	elif t_tf:
		tempe_tile()
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
	var grass_cells_cache = grass_tilemap.get_used_cells(0)
	for i in range(0,min(2,len(grass_cells_cache)-10)):
	
		if grass_cells_cache.is_empty():
			return false
		else:
			var pos = grass_cells_cache[randi_range(0,len(grass_cells_cache)-1)]
			if thing_val[pos]["water"] > 20:
				if not thing_val[pos]["tree"]:
					thing_val[pos]["tree"] = true
					var global_pos = grass_tilemap.map_to_local(pos)
					
					var tree = tree_scene.instantiate()

					tree.global_position = global_pos + Vector2(randi_range(-5,5),randi_range(-5,5))
					add_child(tree)
					tree.pos = pos
					trees[pos] = tree
					tree.tree_temp = "sanak"
					if thing_val[pos]["fire"]:
						tree.animation_player.play("on_fire_up")
			elif randi_range(0,1) == 1:
				if not thing_val[pos]["tree"]:
					var global_pos = grass_tilemap.map_to_local(pos)
					var tree = tree_scene.instantiate()
					thing_val[pos]["tree"] = true
					tree.global_position = global_pos + Vector2(randi_range(-5,5),randi_range(-5,5))
					add_child(tree)
					tree.pos = pos
					trees[pos] = tree
					tree.tree_temp = "sanak"
					if thing_val[pos]["fire"]:
						tree.animation_player.play("on_fire_up")
	var grass_cells_cache_l = grass_tilemap.get_used_cells(2)
	for i in range(0,min(2,len(grass_cells_cache_l)-10)):
		if randi_range(0,4) == 2:
			if grass_cells_cache_l:
				var pos_l = grass_cells_cache_l[randi_range(1,len(grass_cells_cache_l))-1]
				if not thing_val[pos_l]["tree"]:
					var global_pos_l = grass_tilemap.map_to_local(pos_l)
					var tree_l = TREE_L.instantiate()
					tree_l.global_position = global_pos_l + Vector2(randi_range(-5,5),randi_range(-5,5))
					add_child(tree_l)
					tree_l.pos = pos_l
					tree_l.tree_temp = "lava"
					trees[pos_l] = tree_l
					thing_val[pos_l]["tree"] = true
					if thing_val[pos_l]["fire"]:
						tree_l.animation_player.play("on_fire_up")

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
				grass_detail.thing_get(thing_val[global_tile]["terrain"],thing_val[global_tile]["water"],thing_val[global_tile]["tempe"])
				grass_detail.visible = true
			else:
				var tile_pos_l = Vector2i(floor(tile_pos.x), floor(tile_pos.y))
				if all_thing.has(tile_pos_l):
					grass_detail.thing_get("빈땅", all_thing[tile_pos_l]["water"], all_thing[tile_pos_l]["tempe"],all_thing[tile_pos_l]["oxyen"])
					grass_detail.visible = true
				
		# 여기서 tiles 배열을 사용하여 원하는 작업을 수행할 수 있습니다
			if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				kl_ok = true
				if now_worm:
					print("on")
					now_worm.jip()
					worm_jip = true
					
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
	
#
#$TileMap.set_cell_custom_metadata(0, Vector2i(x, y), {"water_content": 50})
#
## 메타데이터 읽기
#var metadata = $TileMap.get_cell_custom_metadata(0, Vector2i(x, y))
#var water_content = metadata.water_content

func river_water():
	for i in thing_val:
		
		for x in dic_check:
			if thing_val.has(i+x):
				if thing_val[i]["water"] - 5 > thing_val[i+x]["water"] and not thing_val[i+x]["water"] < 0:
					if thing_val[i+x]["tempe"] >= 70:
						thing_val[i+x]["tempe"] -= 2
						change_grass(i+x)
					thing_val[i]["water"] -= 2
					thing_val[i+x]["water"] += 2
	for i in water_val:
		var thing = water_val[i]
		if thing_val.has(i):
			thing_val[i]["water"] = 100
			thing_val[i]["tempe"] = 20
		

func _on_timer_2_timeout():
	area_2d.monitorable = false
	area_2d.monitoring = false

func water_tile_load(tf:bool):
	t_tf = false
	o_tf = false
	w_tf = tf
	grass_tilemap.clear_layer(1)
	grass_tilemap.clear_layer(3)
	grass_tilemap.clear_layer(6)
	
func oxyen_tile_load(tf:bool):
	t_tf = false
	w_tf = false
	o_tf = tf
	grass_tilemap.clear_layer(1)
	grass_tilemap.clear_layer(3)
	grass_tilemap.clear_layer(6)
	
	
func water_tile():
	for pos in all_thing.keys():
		var water_value = all_thing[pos]["water"]
		
		# 타일맵 업데이트
		# atlas_coords는 타일셋에서의 타일 위치
		# source_id는 타일셋의 ID (보통 0)
		if not int(all_thing[pos]["water"] /10) == 0:
			grass_tilemap.set_cell(1, Vector2i(pos.x, pos.y), 0, Vector2i(1,1),int(all_thing[pos]["water"] /10) + 1)
			
			
func oxyen_tile():
	for pos in all_thing.keys():
		var water_value = all_thing[pos]["oxyen"]
		
		# 타일맵 업데이트
		# atlas_coords는 타일셋에서의 타일 위치
		# source_id는 타일셋의 ID (보통 0)
		if not int(all_thing[pos]["oxyen"] /10) == 0:
			grass_tilemap.set_cell(6, Vector2i(pos.x,pos.y), 2, Vector2i(0,0),int(all_thing[pos]["oxyen"]/10) + 1)
			

func change_grass(pos):
	var x = grass_tilemap.get_cell_tile_data(2,pos)
	if x:
		if thing_val[pos]["tempe"] < 70:
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
func tempe_tile():
	for pos in all_thing.keys():
		var water_value = all_thing[pos]["tempe"]
		
		# 타일맵 업데이트
		# atlas_coords는 타일셋에서의 타일 위치
		# source_id는 타일셋의 ID (보통 0)
		print(all_thing[pos]["tempe"] /10)
		if not int(all_thing[pos]["tempe"] /10) == 0:
			grass_tilemap.set_cell(3, Vector2i(pos.x, pos.y), 0, Vector2i(1,1),int(all_thing[pos]["tempe"] / 10) + 11)


func water_up():
	if nearby_tiles:
		for i in nearby_tiles:
			grass_tilemap.set_cell(5,i,-1)
			if len(fire_tile) == 1:
				if thing_val[i]["fire"]:
					ui.get_child(0).get_child(0).pop_up_on("fire_off")
			thing_val[i]["fire"] = false
			fire_tile.erase(i)
			if not thing_val[i]["water"] >= 100:
				thing_val[i]["water"] = value_ws
					
			if trees.has(i):
				
				if trees[i].fire >= 0:
					trees[i].animation_player.play("RESET")
					trees[i].fire = 0
				else:
					trees[i].fire -= 0.05
func tempe_up():
	if nearby_tiles:
		for i in nearby_tiles:
			if not thing_val[i]["tempe"] >= 100:
				thing_val[i]["tempe"] = value_ws


func on_fire():
	
	if trees:
		ui.get_child(0).get_child(0).pop_up_on("fire")
		var firen = trees.keys()[randi_range(0,trees.size()-1)]
		if thing_val[firen]["tempe"] >= 0:
			thing_val[firen]["fire"] = true
			
			if trees.has(firen):
				trees[firen].fire_a()
				fire_tile[firen] = 0

func oxyen_spread():
	for i in all_thing:
		if not all_thing[i]["oxyen"] == 0:
			
			var ic = dic_check[randi_range(0,3)]
			if all_thing.has(i+ic):
				if all_thing[i+ic]["oxyen"] + 1 < all_thing[i]["oxyen"]:
					all_thing[i]["oxyen"] -= 2
					all_thing[i+ic]["oxyen"] += 2
						

func fire_spread():

	if not len(fire_tile) >= 10000000000000:
		
		for i in fire_tile:
			for ic in dic_check:
				if randi_range(0,15) == 1:
					if thing_val.has(i+ic):
						thing_val[i+ic]["tempe"] += 2
						if not fire_tile.has(i+ic):
							fire_tile[i+ic] = 0
							thing_val[i+ic]["fire"] = true
							
							grass_tilemap.set_cell(5, Vector2i((i+ic).x,(i+ic).y), 0, Vector2i(1,1),21)
							if trees.has(i+ic):
								trees[i+ic].fire_a()
			
