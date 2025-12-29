extends Sprite3D

## 호버 상태 변수
var is_hovered: bool = false
## 원본 색상 저장
var original_modulate: Color
## 호버 시 적용할 색상 (빨간색으로 확 변경 - 테스트용)
var hover_modulate: Color = Color(10.0, 0.0, 0.0, 1.0)
## Area3D 노드 참조
var area_3d: Area3D
## CollisionShape3D 노드 참조
var collision_shape: CollisionShape3D
## 압축 해제된 이미지 캐시
var uncompressed_image: Image
## 카메라 참조
var camera_3d
## 로그 출력 제어용 타이머
var log_timer: float = 0.0
## 디버그 모드 (상세 로그 출력)
@export var debug_mode: bool = false
## Area3D 회전 업데이트 타이머
var rotation_update_timer: float = 0.0
const ROTATION_UPDATE_INTERVAL: float = 0.1  # 0.1초마다 회전 업데이트
## 마우스가 Area3D 안에 있는지 여부
var mouse_in_area: bool = false
@onready var collision_shape_3d = $body/CollisionShape3D


## 노드가 씬 트리에 진입할 때 호출
## 원본 색상을 저장하고 Area3D를 찾아서 연결
func _ready() -> void:
	camera_3d = get_viewport().get_camera_3d()
	# 원본 색상 저장
	original_modulate = modulate
	
	# 텍스처 이미지 압축 해제 (픽셀 접근을 위해)
	if texture:
		var image = texture.get_image()
		if image:
			# 이미지가 압축되어 있으면 압축 해제
			if image.is_compressed():
				image.decompress()
			uncompressed_image = image
	
	# 자식 노드에서 Area3D와 CollisionShape3D 찾기
	area_3d = get_node_or_null("body")
	if area_3d:
		collision_shape = area_3d.get_node_or_null("CollisionShape3D")
		
		# Area3D의 마우스 이벤트 연결
		area_3d.input_event.connect(_on_area_input_event)
		area_3d.mouse_entered.connect(_on_mouse_entered)
		area_3d.mouse_exited.connect(_on_mouse_exited)


## 매 프레임마다 호출되어 마우스 위치를 확인
## 픽셀 퍼펙트 호버 감지를 수행
func _process(delta: float) -> void:
	log_timer += delta
	rotation_update_timer += delta
	
	# CollisionShape를 카메라 화면과 평행하게 회전 (0.1초마다만 업데이트)
	# (카메라 중앙에서 쏘는 직선이 CollisionShape와 수직으로 만남)
	if area_3d and camera_3d and rotation_update_timer >= ROTATION_UPDATE_INTERVAL:
		rotation_update_timer = 0.0
		
		# 카메라가 바라보는 방향 (카메라의 -Z축)
		var camera_forward = -camera_3d.global_transform.basis.z
		
		# CollisionShape 축 계산
		# Z축: 카메라가 바라보는 방향
		var forward = camera_forward
		# X축: 카메라의 오른쪽 방향
		var right = camera_3d.global_transform.basis.x
		# Y축: 카메라의 위쪽 방향
		var up = camera_3d.global_transform.basis.y
		
		# offset을 월드 좌표로 변환 (픽셀 단위 -> 월드 단위)
		var offset_world_x = offset.x * pixel_size * right
		var offset_world_y = offset.y * pixel_size * up
		var offset_world = offset_world_x + offset_world_y
		
		# Area3D의 위치를 스프라이트 중심 + offset으로 설정
		area_3d.global_position = global_position + offset_world
		# Area3D의 Basis를 카메라와 평행하게 설정
		# Godot Basis는 (X축, Y축, Z축) 순서
		area_3d.global_transform.basis = Basis(right, up, forward)
	
	# 디버그 로그 출력 (1초마다)
	if debug_mode and log_timer >= 1.0 and camera_3d:
		log_timer = 0.0
	
	# 픽셀 퍼펙트 체크는 main.gd -> obsticle.gd를 통해서만 실행됨
	# 여기서는 실행하지 않음


## 픽셀 퍼펙트 호버 감지 함수
## 카메라에서 레이캐스트를 쏴서 스프라이트의 실제 픽셀을 감지
## 투명 픽셀은 통과하고 뒤의 오브젝트도 체크
func check_pixel_perfect_hover() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera or not area_3d:
		return
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 카메라에서 마우스 위치로 레이 생성
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# 물리 공간 쿼리
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true  # Area3D와 충돌 감지 (픽셀퍼펙트용)
	query.collide_with_bodies = true  # StaticBody3D도 일시적으로 감지 (디버깅용)
	
	# 이 스프라이트의 Area3D와 충돌했는지 확인
	var was_hovered = is_hovered
	is_hovered = false
	
	# 제외할 충돌체 목록 (투명 픽셀을 가진 Area는 제외하고 다시 레이캐스트)
	var excluded_colliders: Array[RID] = []
	var max_iterations = 10  # 최대 10개 오브젝트까지 체크
	
	for i in range(max_iterations):
		# 제외 목록 설정
		query.exclude = excluded_colliders
		
		# 레이캐스트 실행
		var result = space_state.intersect_ray(query)
		
		if not result:
			# 더 이상 충돌이 없으면 종료
			break
		
		# StaticBody3D인지 확인
		if result.collider is StaticBody3D:
			# StaticBody3D를 제외하고 다음 반복
			if result.collider is CollisionObject3D:
				excluded_colliders.append(result.collider.get_rid())
			else:
				excluded_colliders.append(result.rid)
			continue
		
		# 이 스프라이트의 Area3D와 충돌했는지 확인
		if result.collider == area_3d:
			# 충돌 지점에서 텍스처의 픽셀 확인
			var pixel_check = is_pixel_opaque_at_position(result.position)
			if pixel_check:
				# 불투명한 픽셀을 찾았으면 호버 활성화하고 종료
				is_hovered = true
				break
			else:
				# 투명한 픽셀이면 이 충돌체를 제외하고 다음 반복
				pass
				# Area3D나 CollisionObject3D의 RID 가져오기
				if result.collider is CollisionObject3D:
					excluded_colliders.append(result.collider.get_rid())
				else:
					# RID를 직접 가져올 수 없는 경우 result.rid 사용
					excluded_colliders.append(result.rid)
		else:
			# 다른 오브젝트와 충돌 - Sprite3D인지 확인
			var other_sprite = result.collider.get_parent() if result.collider.get_parent() is Sprite3D else null
			if other_sprite and other_sprite.has_method("is_pixel_opaque_at_position"):
				# 다른 Sprite3D의 픽셀이 불투명한지 체크
				var other_pixel_check = other_sprite.is_pixel_opaque_at_position(result.position)
				if other_pixel_check:
					# 앞쪽에 불투명한 오브젝트가 있으면 뒤쪽은 체크하지 않음
					break
			
			# 투명하거나 Sprite3D가 아니면 제외하고 계속
			if result.collider is CollisionObject3D:
				excluded_colliders.append(result.collider.get_rid())
			else:
				excluded_colliders.append(result.rid)
	
	# 호버 상태가 변경되었을 때만 색상 업데이트
	if was_hovered != is_hovered:
		update_hover_effect()


## Area3D의 input_event 시그널 핸들러
func _on_area_input_event(_camera: Node, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	# 마우스 움직임 이벤트 처리
	if event is InputEventMouseMotion:
		# 픽셀 퍼펙트 체크는 _process에서 처리됨
		pass


## Area3D에 마우스가 진입했을 때
func _on_mouse_entered() -> void:
	mouse_in_area = true
	# 실제 호버는 픽셀 체크 후 결정


## Area3D에서 마우스가 나갔을 때
func _on_mouse_exited() -> void:
	mouse_in_area = false
	# 호버 해제
	if is_hovered:
		is_hovered = false
		update_hover_effect()


## 특정 3D 위치가 스프라이트의 불투명한 픽셀에 해당하는지 확인
## world_position: 확인할 월드 공간 위치
## 반환값: 해당 위치의 픽셀이 불투명하면 true
func is_pixel_opaque_at_position(world_position: Vector3) -> bool:
	# 압축 해제된 이미지가 없으면 false
	if not uncompressed_image or not camera_3d:
		return false
	
	# 스프라이트 중심에서 충돌 지점까지의 벡터 (글로벌)
	var to_hit = world_position - global_position
	
	# CollisionShape가 카메라 방향으로 고정되어 있으므로
	# 카메라의 축을 직접 사용
	var sprite_right = camera_3d.global_transform.basis.x  # 카메라의 오른쪽
	var sprite_up = camera_3d.global_transform.basis.y     # 카메라의 위쪽
	
	# 충돌 지점을 카메라 기준 좌표로 투영
	var local_x = to_hit.dot(sprite_right)
	var local_y = to_hit.dot(sprite_up)
	
	# Sprite3D의 offset 적용 (픽셀 단위를 월드 단위로 변환)
	var offset_world = offset * pixel_size
	local_x -= offset_world.x
	local_y -= offset_world.y
	
	# 한 프레임의 크기 계산 (hframes, vframes 고려)
	var texture_size = texture.get_size()
	var frame_width = texture_size.x / float(hframes) if hframes > 0 else texture_size.x
	var frame_height = texture_size.y / float(vframes) if vframes > 0 else texture_size.y
	var frame_size = Vector2(frame_width, frame_height) * pixel_size
	
	# 로컬 좌표를 UV 좌표로 변환 (0~1 범위, 한 프레임 기준)
	var uv_x = (local_x / frame_size.x) + 0.5
	var uv_y = (-local_y / frame_size.y) + 0.5
	
	# UV 범위 체크
	if uv_x < 0 or uv_x > 1 or uv_y < 0 or uv_y > 1:
		return false
	
	# 현재 프레임의 위치 계산
	var current_frame = frame if hframes > 0 or vframes > 0 else 0
	var frame_x = current_frame % hframes if hframes > 0 else 0
	var frame_y = int(current_frame / hframes) if hframes > 0 else 0
	
	# 실제 텍스처에서의 픽셀 좌표 계산 (프레임 오프셋 포함)
	var pixel_x = int(frame_x * frame_width + uv_x * frame_width)
	var pixel_y = int(frame_y * frame_height + uv_y * frame_height)
	
	# 범위 체크
	if pixel_x < 0 or pixel_x >= uncompressed_image.get_width() or pixel_y < 0 or pixel_y >= uncompressed_image.get_height():
		return false
	
	# 픽셀의 알파값 확인 (압축 해제된 이미지 사용)
	var pixel_color = uncompressed_image.get_pixel(pixel_x, pixel_y)
	var is_opaque = pixel_color.a > 0.1  # 알파값이 0.1보다 크면 불투명으로 간주
	
	return is_opaque


## 호버 상태에 따라 색상 효과 업데이트
func update_hover_effect() -> void:
	if is_hovered:
		# 호버 시 밝게
		modulate = hover_modulate
	else:
		# 원래 색상으로 복원
		modulate = original_modulate


## 외부에서 호출 가능한 픽셀 퍼펙트 체크 함수
## 마우스 위치에서 이 스프라이트의 불투명한 픽셀이 있는지 확인
## 반환값: 불투명한 픽셀이 있으면 true, 없으면 false
func check_pixel_perfect_from_mouse() -> bool:
	var camera = get_viewport().get_camera_3d()
	if not camera or not area_3d:
		return false
	
	var mouse_pos = get_viewport().get_mouse_position()
	
	# 카메라에서 마우스 위치로 레이 생성
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# 물리 공간 쿼리
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = false  # Body는 체크하지 않음
	
	# 레이캐스트 실행
	var result = space_state.intersect_ray(query)
	
	if not result:
		return false
	
	# 이 스프라이트의 Area3D와 충돌했는지 확인
	if result.collider == area_3d:
		# 충돌 지점에서 텍스처의 픽셀 확인
		return is_pixel_opaque_at_position(result.position)
	
	return false


## main.gd의 raycast 충돌 지점을 사용하여 픽셀 퍼펙트 체크를 수행하는 함수
## collision_point: main.gd의 raycast가 감지한 충돌 지점 (월드 좌표)
## 반환값: 불투명한 픽셀이 있으면 true, 없으면 false
func check_pixel_perfect_at_point(collision_point: Vector3) -> bool:
	# 충돌 지점에서 텍스처의 픽셀 확인
	return is_pixel_opaque_at_position(collision_point)


## 외부에서 호출 가능한 빨간색 표시 함수
func set_red_highlight() -> void:
	modulate = Color(10.0, 0.0, 0.0, 1.0)


## CollisionShape3D 크기를 entity의 pixel_s 값으로 업데이트하는 함수
## pixel_s: entity.gd의 pixel_s 값 (정사각형 크기)
func update_collision_shape_size(pixel_s: int) -> void:
	print("[entity_sprite] === update_collision_shape_size 시작 ===")
	
	# collision_shape가 없으면 직접 찾기 (에디터 모드나 _ready 전에 호출될 수 있음)
	if not collision_shape:
		var area = get_node_or_null("body")
		if area:
			collision_shape = area.get_node_or_null("CollisionShape3D")
	
	if not collision_shape:
		print("[entity_sprite] collision_shape 없음!")
		return
	
	# 기존 shape가 있는지 확인
	var old_box_shape = collision_shape.shape as BoxShape3D
	if old_box_shape:
		print("[entity_sprite] 기존 box_shape.size: ", old_box_shape.size)
	
	# pixel_s와 pixel_size를 곱해서 월드 크기로 변환 (정사각형)
	var world_size = pixel_s * pixel_size
	
	print("[entity_sprite] pixel_s=", pixel_s, " pixel_size=", pixel_size, " world_size=", world_size)
	
	# 새로운 BoxShape3D 생성 및 크기 설정 (정사각형, Z축은 얇게)
	var new_box_shape = BoxShape3D.new()
	var new_size = Vector3(world_size, world_size, 0.01)
	new_box_shape.size = new_size
	
	# CollisionShape3D에 새로운 shape 할당
	collision_shape.shape = new_box_shape
	
	print("[entity_sprite] 새로운 크기 설정: ", new_size)
	print("[entity_sprite] collision_shape.shape.size (변경 후): ", collision_shape.shape.size)
	print("[entity_sprite] === update_collision_shape_size 완료 ===")
