extends Node3D
@onready var sprite_3d = $Sprite3D

const OBSTICLE = preload("uid://f73ynbaimcwh")
const MOON_ROCK = preload("uid://cfifr707lvaqv")

func _ready():
	# 현재 위치를 ObstacleGrid에 맞춰 스냅
	snap_to_obstacle_grid()
	
	# 스프라이트를 하늘 높이 위치시킴
	var start_y = 20.0  # 시작 높이
	var target_y = 0.0  # 땅 높이
	
	sprite_3d.position.y = start_y
	
	print("운석 낙하 시작! 위치: ", global_position, " | 시작 Y: ", start_y, " -> 목표 Y: ", target_y)
	
	# Tween 생성 및 설정
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)  # 점점 감속하는 효과
	tween.set_trans(Tween.TRANS_QUAD)  # 2차 함수 곡선으로 완만한 감속
	
	# 스프라이트의 y축으로 떨어지는 애니메이션
	tween.tween_property(sprite_3d, "position:y", target_y, 1)
	
	# 떨어지는 애니메이션이 끝나면 MOON_ROCK 소환
	tween.tween_callback(set_rock)

## ObstacleGrid에 맞춰 위치를 스냅하는 함수
func snap_to_obstacle_grid():
	var main_scene = get_parent()
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		print("[moon_rock] 경고: ObstacleGrid를 찾을 수 없습니다!")
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var cell_size = obstacle_grid.cell_size
	
	# ObstacleGrid의 실제 셀 크기 사용
	var tile_size_x = cell_size.x
	var tile_size_z = cell_size.z
	
	# X와 Z 좌표를 타일 그리드에 스냅 (타일 중앙에 맞춤)
	var snapped_x = floor(global_position.x / tile_size_x) * tile_size_x + tile_size_x / 2.0
	var snapped_z = floor(global_position.z / tile_size_z) * tile_size_z + tile_size_z / 2.0
	
	# Y좌표는 그대로 유지
	global_position = Vector3(snapped_x, global_position.y, snapped_z)
	
	print("[moon_rock] 그리드에 스냅: ", global_position)


func set_rock():
	var a = OBSTICLE.instantiate()
	a.thing = MOON_ROCK
	
	# Y 좌표를 0으로 맞춰서 다른 obsticle과 동일하게 설정
	var spawn_position = global_position

	
	a.global_position = spawn_position
	get_parent().add_child(a)
	
	# ObstacleGrid에 등록
	register_obsticle_to_grid(a, spawn_position)
	
	print("[moon_rock] obsticle 생성 완료 - 위치: ", spawn_position)
	
	queue_free()

## ObstacleGrid에 obsticle 정보를 등록하는 함수
func register_obsticle_to_grid(obsticle_node: Node3D, world_pos: Vector3):
	var main_scene = get_parent()
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		print("[moon_rock] 경고: ObstacleGrid를 찾을 수 없어서 obsticle을 등록할 수 없습니다!")
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var obsticle_data = obsticle_node.thing
	
	if not obsticle_data:
		return
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width_tiles = obsticle_data.grid_width if "grid_width" in obsticle_data else 3
	var grid_height_tiles = obsticle_data.grid_height if "grid_height" in obsticle_data else 3
	
	# 월드 좌표를 ObstacleGrid의 그리드 좌표로 변환
	var center_grid_pos = obstacle_grid.world_to_grid(world_pos)
	
	# ObstacleGrid에 영역 등록
	obstacle_grid.register_obstacle_area(center_grid_pos, grid_width_tiles, grid_height_tiles)
	
	print("[moon_rock] obsticle 등록: ", obsticle_data.name if "name" in obsticle_data else "unknown", " at ", center_grid_pos, " (타일 크기: %dx%d)" % [grid_width_tiles, grid_height_tiles])
