extends MeshInstance3D
class_name BulletTracer

## 총알 궤적 이펙트
## 총구에서 피격 지점까지 빠르게 날아가는 선을 그림

# 설정
var lifetime: float = 0.1  # 표시 시간
var fade_speed: float = 15.0  # 페이드아웃 속도

# 타이머
var time_elapsed: float = 0.0

func _ready():
	# 초기 투명도 설정
	if get_surface_override_material_count() > 0:
		var mat = get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _process(delta):
	time_elapsed += delta
	
	# 페이드아웃
	if get_surface_override_material_count() > 0:
		var mat = get_surface_override_material(0) as StandardMaterial3D
		if mat:
			var alpha = 1.0 - (time_elapsed / lifetime)
			mat.albedo_color.a = max(alpha, 0.0)
	
	# 수명 종료 시 제거
	if time_elapsed >= lifetime:
		queue_free()

# 총알 궤적 설정
# start_pos: 시작 위치 (총구)
# end_pos: 끝 위치 (피격 지점)
func setup(start_pos: Vector3, end_pos: Vector3):
	# 중간 지점 계산
	var mid_point = (start_pos + end_pos) / 2.0
	global_position = mid_point
	
	# 거리 계산
	var distance = start_pos.distance_to(end_pos)
	
	# 방향 계산
	var direction = (end_pos - start_pos).normalized()
	
	# 메시 크기 조정 (얇은 선으로)
	if mesh is BoxMesh:
		mesh.size = Vector3(0.01, 0.01, distance)
	
	# 회전 (총구에서 피격 지점을 향하도록)
	look_at(end_pos, Vector3.UP)

