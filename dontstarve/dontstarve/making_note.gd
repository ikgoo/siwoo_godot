extends Node3D
@onready var sprite_3d = $Sprite3D
var resipis : resipi
var thing : obsticle

## 이 making_note에 투입된 재료 정보 저장
var contributed_materials : Dictionary = {}

## 완성된 obsticle 씬을 미리 로드
const OBSTICLE_SCENE = preload("res://obsticle.tscn")

## 거리 기반 렌더링 설정
@export var render_distance : float = 15.0  # 렌더링 거리 (기본 15미터)
var player_node : Node3D = null  # 플레이어 노드 참조

## 타일 범위 표시를 위한 노드들
var tile_indicators : Array[MeshInstance3D] = []
var show_tile_range : bool = false  # 타일 범위 표시 여부

## 노드가 씬 트리에 추가될 때 호출
func _ready():
	if thing:
		sprite_3d.texture = thing.img
		sprite_3d.offset.y = thing.offset
	
	# making_need UI를 찾아서 신호 연결
	connect_to_making_need()
	
	# 플레이어 노드 찾기
	find_player_node()
	
	# Globals에 등록
	Globals.register_making_note(self)


## 매 프레임 호출
func _process(_delta):
	# 거리 기반 렌더링 체크
	check_render_distance()
	check_tile_range_visibility()


## making_need UI를 찾아서 초기화하는 함수 (신호 연결은 더 이상 필요 없음)
func connect_to_making_need():
	# making_need UI는 이제 Globals.active_making_notes를 통해 자동으로 업데이트됨
	print("making_note: making_need UI 준비됨")


## 모든 재료가 충족되었을 때 호출되는 함수 (making_need.gd에서 호출)
## recipe: 완성된 레시피
func _on_all_materials_satisfied(recipe: resipi):
	print("making_note: 모든 재료 충족! obsticle 생성 시작")
	
	# 레시피에서 완성될 obsticle 확인
	if not recipe or not recipe.end_obsticle:
		print("레시피에 end_obsticle이 없습니다")
		return
	
	# 현재 위치에 obsticle 생성
	create_obsticle(recipe.end_obsticle)
	
	# Globals에서 즉시 제거 (banner가 남지 않도록)
	Globals.remove_nearby_making_note(self)
	Globals.unregister_making_note(self)
	
	# Area3D 비활성화 (신호가 더 이상 발생하지 않도록)
	if has_node("Area3D"):
		var area = get_node("Area3D")
		area.monitoring = false
		area.monitorable = false
	
	# 자기 자신 제거
	queue_free()


## obsticle을 생성하는 함수
## obsticle_data: 생성할 obsticle 리소스
func create_obsticle(obsticle_data: obsticle):
	if not obsticle_data:
		print("obsticle 데이터가 없습니다")
		return
	
	# obsticle 씬 인스턴스 생성
	var new_obsticle = OBSTICLE_SCENE.instantiate()
	
	# obsticle 데이터 설정
	new_obsticle.thing = obsticle_data
	
	# 현재 위치에 배치
	new_obsticle.global_position = global_position
	
	# 부모에 추가
	get_parent().add_child(new_obsticle)
	
	# ObstacleGrid에 등록
	register_obsticle_to_grid(new_obsticle, global_position)
	
	print("obsticle 생성 완료: ", obsticle_data.name, " at ", global_position)


## Area3D에 플레이어가 들어왔을 때 호출
## area: 들어온 Area3D (플레이어의 Area3D)
func _on_area_3d_area_entered(area):
	# 플레이어의 Area3D인지 확인
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		# 현재 making_note의 정보를 Globals에 저장
		Globals.ob_re_need = thing
		Globals.ob_re_resipis = resipis
		Globals.ob_re_contributed = contributed_materials
		Globals.current_making_note = self
		Globals.is_near_making_note = true
		
		# 근처 리스트에 추가
		Globals.add_nearby_making_note(self)
		
		print("making_note 근처 진입: ", thing.name if thing else "없음")
		print("저장된 재료 투입 현황: ", contributed_materials)


## Area3D에서 플레이어가 나갔을 때 호출
## area: 나간 Area3D (플레이어의 Area3D)
func _on_area_3d_area_exited(area):
	# 플레이어의 Area3D인지 확인
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		# Globals 정보 초기화 (contributed_materials는 유지됨)
		Globals.ob_re_need = null
		Globals.ob_re_resipis = null
		Globals.ob_re_contributed = {}
		Globals.current_making_note = null
		Globals.is_near_making_note = false
		
		# 근처 리스트에서 제거
		Globals.remove_nearby_making_note(self)
		
		print("making_note 근처 이탈")
		print("최종 재료 투입 현황: ", contributed_materials)

## 플레이어 노드를 찾는 함수
func find_player_node():
	# "player" 그룹에서 플레이어 찾기
	player_node = get_tree().get_first_node_in_group("player")
	
	if not player_node:
		print("플레이어 노드를 찾을 수 없습니다!")

## 플레이어와의 거리를 체크하여 렌더링 여부를 결정하는 함수
func check_render_distance():
	if not player_node or not sprite_3d:
		return
	
	# 플레이어가 유효하지 않으면 다시 찾기
	if not is_instance_valid(player_node):
		find_player_node()
		return
	
	# 플레이어와의 거리 계산
	var distance = global_position.distance_to(player_node.global_position)
	
	# 거리에 따라 sprite_3d 표시/숨김
	sprite_3d.visible = distance <= render_distance

## making_veiw가 활성화되어 있는지 체크하여 타일 범위 표시
func check_tile_range_visibility():
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
	
	var making_veiw = main_scene.get_node_or_null("making_veiw")
	if not making_veiw:
		return
	
	# making_veiw에 thing이 있으면 타일 범위 표시
	var should_show = making_veiw.thing != null
	
	if should_show != show_tile_range:
		show_tile_range = should_show
		if show_tile_range:
			create_tile_indicators()
		else:
			clear_tile_indicators()

## 타일 범위 인디케이터 생성
func create_tile_indicators():
	clear_tile_indicators()
	
	if not thing:
		return
	
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		return
	
	var obstacle_grid = main_scene.get_node("ObstacleGrid")
	var cell_size = obstacle_grid.cell_size
	
	# obsticle의 그리드 크기 (ObstacleGrid 타일 개수)
	var grid_width = thing.grid_width if "grid_width" in thing else 3
	var grid_height = thing.grid_height if "grid_height" in thing else 3
	
	var tile_size_x = cell_size.x
	var tile_size_z = cell_size.z
	
	# 중심을 기준으로 타일 생성
	var half_width = floor(grid_width / 2.0)
	var half_height = floor(grid_height / 2.0)
	
	for x in range(-half_width, grid_width - half_width):
		for z in range(-half_height, grid_height - half_height):
			var mesh_instance = MeshInstance3D.new()
			
			var plane_mesh = PlaneMesh.new()
			plane_mesh.size = Vector2(tile_size_x * 0.9, tile_size_z * 0.9)
			plane_mesh.orientation = PlaneMesh.FACE_Y
			mesh_instance.mesh = plane_mesh
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(1.0, 1.0, 0.0, 0.2)  # 반투명 노란색
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
			mesh_instance.material_override = material
			
			mesh_instance.position = Vector3(x * tile_size_x, 0.005, z * tile_size_z)
			
			add_child(mesh_instance)
			tile_indicators.append(mesh_instance)

## 타일 범위 인디케이터 제거
func clear_tile_indicators():
	for indicator in tile_indicators:
		if indicator:
			indicator.queue_free()
	tile_indicators.clear()

## 노드가 씬 트리에서 제거될 때 호출
func _exit_tree():
	# Globals에서 제거
	Globals.unregister_making_note(self)


func _on_is_setable_area_area_entered(_area):
	pass # Replace with function body.


func _on_is_setable_area_area_exited(_area):
	pass # Replace with function body.

## ObstacleGrid에 obsticle 정보를 등록하는 함수
func register_obsticle_to_grid(obsticle_node: Node3D, world_pos: Vector3):
	var main_scene = get_tree().current_scene
	if not main_scene or not main_scene.has_node("ObstacleGrid"):
		print("[making_note] 경고: ObstacleGrid를 찾을 수 없어서 obsticle을 등록할 수 없습니다!")
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
	
	print("[making_note] obsticle 등록: ", obsticle_data.name if "name" in obsticle_data else "unknown", " at ", center_grid_pos, " (타일 크기: %dx%d)" % [grid_width_tiles, grid_height_tiles])
