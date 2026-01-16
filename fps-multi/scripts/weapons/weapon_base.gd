extends Node3D
class_name WeaponBase

## 모든 무기의 베이스 클래스
## 발사, 재장전, 조준 등의 공통 기능을 제공

# 시그널
signal weapon_fired()
signal weapon_reloaded()
signal ammo_changed(current_ammo: int, reserve_ammo: int)
signal hit_target(target, damage: float, hit_position: Vector3)

# 무기 데이터
@export var weapon_data: WeaponData

# 현재 상태
var current_ammo: int = 0
var reserve_ammo: int = 0
var is_reloading: bool = false
var is_firing: bool = false
var is_aiming: bool = false
var can_fire: bool = true

# 발사 타이머
var fire_timer: float = 0.0
var burst_count_current: int = 0
var burst_timer: float = 0.0

# 노드 참조
@onready var raycast: RayCast3D = $RayCast3D
@onready var muzzle_flash: GPUParticles3D = $MuzzleFlash
@onready var shell_eject: GPUParticles3D = $ShellEject
@onready var weapon_mesh: MeshInstance3D = $WeaponMesh
@onready var muzzle_point: Marker3D = $MuzzlePoint

# 카메라 참조 (반동용)
var camera_controller: CameraController

# 총알 궤적 씬
var bullet_tracer_scene = preload("res://scenes/weapons/bullet_tracer.tscn")

func _ready():
	if weapon_data:
		# 탄약 초기화
		current_ammo = weapon_data.magazine_size
		reserve_ammo = weapon_data.reserve_ammo
		ammo_changed.emit(current_ammo, reserve_ammo)
	
	# 레이캐스트 설정
	if raycast:
		raycast.enabled = true
		raycast.target_position = Vector3(0, 0, -100)
		raycast.collision_mask = 1  # 레이어 1과 충돌
	
	# 파티클 비활성화
	if muzzle_flash:
		muzzle_flash.emitting = false
	if shell_eject:
		shell_eject.emitting = false

func _process(delta):
	# 발사 타이머 감소
	if fire_timer > 0:
		fire_timer -= delta
	
	# 점사 타이머 처리
	if weapon_data and weapon_data.fire_mode == 3:  # 점사 모드
		if burst_count_current > 0:
			burst_timer -= delta
			if burst_timer <= 0:
				_fire_single_shot()
				burst_count_current -= 1
				if burst_count_current > 0:
					burst_timer = weapon_data.burst_delay

# 무기 장착 시 호출
func equip():
	visible = true
	set_process(true)
	# 카메라 컨트롤러 참조 획득
	var parent = get_parent()
	while parent:
		if parent is Camera3D:
			camera_controller = parent.get_parent() as CameraController
			break
		parent = parent.get_parent()

# 무기 해제 시 호출
func unequip():
	visible = false
	set_process(false)
	is_firing = false
	is_reloading = false

# 발사 시도
func fire():
	if not weapon_data:
		return
	
	# 근접 무기는 다른 처리
	if weapon_data.fire_mode == 4:  # 근접
		melee_attack()
		return
	
	# 발사 불가 조건 체크
	if is_reloading or not can_fire or fire_timer > 0:
		return
	
	# 탄약 체크
	if current_ammo <= 0:
		# 빈 탄창 사운드 재생 (나중에 추가)
		return
	
	# 발사 모드에 따른 처리
	match weapon_data.fire_mode:
		0:  # 자동
			_fire_single_shot()
			fire_timer = weapon_data.fire_rate
		1:  # 반자동
			if not is_firing:
				_fire_single_shot()
				fire_timer = weapon_data.fire_rate
		2:  # 단발
			_fire_single_shot()
			fire_timer = weapon_data.fire_rate
		3:  # 점사
			if not is_firing:
				burst_count_current = weapon_data.burst_count
				_fire_single_shot()
				burst_count_current -= 1
				burst_timer = weapon_data.burst_delay
				fire_timer = weapon_data.fire_rate * 2
	
	is_firing = true

# 발사 중지
func stop_fire():
	is_firing = false

# 단발 발사 처리 (내부 함수)
func _fire_single_shot():
	if not weapon_data:
		return
	
	# 탄약 소모
	if not weapon_data.infinite_ammo:
		current_ammo -= 1
		ammo_changed.emit(current_ammo, reserve_ammo)
	
	# 샷건은 여러 발 발사
	for i in range(weapon_data.pellets_per_shot):
		_fire_raycast()
	
	# 시각 효과
	if weapon_data.use_muzzle_flash and muzzle_flash:
		muzzle_flash.restart()
	if weapon_data.use_shell_eject and shell_eject:
		shell_eject.restart()
	
	# 총 반동 애니메이션 (위아래로 움직임)
	_play_recoil_animation()
	
	# 총 흔들림 애니메이션 추가
	_play_gun_shake_animation()
	
	# 카메라 반동
	if camera_controller:
		camera_controller.add_trauma(weapon_data.recoil_amount * 0.3)
	
	# 시그널 발사
	weapon_fired.emit()
	
	# 멀티플레이어: 다른 플레이어에게 발사 알림
	if multiplayer.get_peers().size() > 0:
		_sync_fire.rpc()

# 레이캐스트 발사 및 히트 체크
func _fire_raycast():
	if not raycast:
		return
	
	# 탄퍼짐 계산
	var spread = _calculate_spread()
	var spread_offset = Vector3(
		randf_range(-spread, spread),
		randf_range(-spread, spread),
		0
	)
	
	# 레이캐스트 방향 설정 (카메라 중앙에서 발사)
	var camera = get_viewport().get_camera_3d()
	if camera:
		var from = camera.global_position
		var to = from + (-camera.global_transform.basis.z * 100)
		
		# 탄퍼짐 적용
		to += camera.global_transform.basis * spread_offset
		
		# 물리 레이캐스트 수행
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		
		# 자기 자신만 제외 (다른 플레이어는 맞을 수 있음)
		var player = _get_player()
		if player:
			query.exclude = [player]
		
		# 충돌 마스크 설정: World(1) + Players(2) + Targets(4)
		query.collision_mask = 7
		
		var result = space_state.intersect_ray(query)
		
		# 총알 궤적 이펙트 생성
		var tracer_end = to
		if result:
			tracer_end = result.position
		_spawn_bullet_tracer(from, tracer_end)
		
		if result:
			# 히트 처리
			var damage = weapon_data.damage
			
			# 헤드샷 체크 (나중에 구현)
			# if result.collider.is_in_group("head"):
			# 	damage *= weapon_data.headshot_multiplier
			
			# 타겟에 데미지 전달
			if result.collider.has_method("take_damage"):
				result.collider.take_damage(damage, result.position)
			
			# 시그널 발사
			hit_target.emit(result.collider, damage, result.position)

# 총알 궤적 생성
# start_pos: 시작 위치
# end_pos: 끝 위치
func _spawn_bullet_tracer(start_pos: Vector3, end_pos: Vector3):
	if not bullet_tracer_scene:
		return
	
	# 총구 위치 가져오기
	var muzzle_pos = start_pos
	if muzzle_point:
		muzzle_pos = muzzle_point.global_position
	
	# 총알 궤적 생성
	var tracer = bullet_tracer_scene.instantiate()
	get_tree().root.add_child(tracer)
	tracer.setup(muzzle_pos, end_pos)

# 탄퍼짐 계산
func _calculate_spread() -> float:
	if not weapon_data:
		return 0.0
	
	var spread = weapon_data.base_spread
	
	# 조준 중이면 탄퍼짐 감소
	if is_aiming:
		spread = weapon_data.aim_spread
	
	# 플레이어 움직임에 따른 탄퍼짐 증가
	var player = _get_player()
	if player:
		if player.is_moving():
			spread *= weapon_data.moving_spread_multiplier
		if not player.is_on_floor():
			spread *= weapon_data.jumping_spread_multiplier
	
	return spread

# 재장전
func reload():
	if is_reloading or current_ammo == weapon_data.magazine_size:
		return
	
	if weapon_data.infinite_ammo:
		return
	
	if reserve_ammo <= 0:
		return
	
	is_reloading = true
	
	# 재장전 애니메이션 (360도 회전)
	if weapon_mesh:
		var original_rotation = weapon_mesh.rotation
		var tween = create_tween()
		tween.set_parallel(false)
		# Y축으로 360도 (2 * PI 라디안) 회전
		tween.tween_property(weapon_mesh, "rotation:y", 
			original_rotation.y + TAU, weapon_data.reload_time * 0.8)
		# 원래 위치로 복귀
		tween.tween_property(weapon_mesh, "rotation:y", 
			original_rotation.y, weapon_data.reload_time * 0.2)
	
	# 재장전 타이머 시작
	await get_tree().create_timer(weapon_data.reload_time).timeout
	
	# 탄약 재장전
	var ammo_needed = weapon_data.magazine_size - current_ammo
	var ammo_to_reload = min(ammo_needed, reserve_ammo)
	
	current_ammo += ammo_to_reload
	reserve_ammo -= ammo_to_reload
	
	is_reloading = false
	weapon_reloaded.emit()
	ammo_changed.emit(current_ammo, reserve_ammo)

# 조준 시작
func start_aim():
	is_aiming = true
	if camera_controller:
		camera_controller.change_fov(60.0, 0.2)

# 조준 중지
func stop_aim():
	is_aiming = false
	if camera_controller:
		camera_controller.change_fov(90.0, 0.2)

# 근접 공격
func melee_attack():
	if not weapon_data or fire_timer > 0:
		return
	
	fire_timer = weapon_data.attack_speed
	
	# 칼 찌르기 애니메이션
	_play_stab_animation()
	
	# 전방 범위 내 적 탐지
	var camera = get_viewport().get_camera_3d()
	if camera:
		var from = camera.global_position
		var to = from + (-camera.global_transform.basis.z * weapon_data.attack_range)
		
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [get_parent().get_parent().get_parent()]
		
		var result = space_state.intersect_ray(query)
		if result:
			if result.collider.has_method("take_damage"):
				result.collider.take_damage(weapon_data.damage, result.position)
			hit_target.emit(result.collider, weapon_data.damage, result.position)
	
	weapon_fired.emit()

# 플레이어 참조 가져오기
func _get_player() -> PlayerController:
	var node = self
	while node:
		if node is PlayerController:
			return node
		node = node.get_parent()
	return null

# 멀티플레이어: 발사 동기화
@rpc("any_peer", "call_remote", "unreliable")
func _sync_fire():
	# 시각 효과만 재생 (데미지는 로컬에서 이미 처리됨)
	if weapon_data.use_muzzle_flash and muzzle_flash:
		muzzle_flash.restart()
	if weapon_data.use_shell_eject and shell_eject:
		shell_eject.restart()


# 총 반동 애니메이션 (위아래로 움직임)
func _play_recoil_animation():
	if not weapon_mesh:
		return
	
	var original_position = weapon_mesh.position
	
	# 반동 강도 계산 (극대화!)
	var recoil_multiplier = weapon_data.recoil_amount + 1.0  # 기본 1.0 추가
	var recoil_up = 0.25 * recoil_multiplier  # 위로 (5배 증가)
	var recoil_back = 0.4 * recoil_multiplier  # 뒤로 (4배 증가)
	
	# 회전도 추가 (더 역동적인 느낌)
	var original_rotation = weapon_mesh.rotation
	var recoil_rotation = -0.3 * recoil_multiplier  # 위로 회전
	
	var tween = create_tween()
	tween.set_parallel(true)  # 동시 진행
	
	# 1. 뒤로 + 위로 (반동) - 빠르게!
	tween.tween_property(weapon_mesh, "position", 
		original_position + Vector3(0, recoil_up, recoil_back), 0.08)
	tween.tween_property(weapon_mesh, "rotation:x", 
		original_rotation.x + recoil_rotation, 0.08)
	
	# 2. 원위치 복귀 - 탄성 효과
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(weapon_mesh, "position", 
		original_position, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon_mesh, "rotation:x", 
		original_rotation.x, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

# 총 흔들림 애니메이션 (발사 시 미세한 진동)
func _play_gun_shake_animation():
	if not weapon_mesh:
		return
	
	var original_position = weapon_mesh.position
	var original_rotation = weapon_mesh.rotation
	
	# 흔들림 강도
	var shake_intensity = weapon_data.recoil_amount * 0.15
	var shake_speed = 0.03  # 매우 빠른 흔들림
	
	var shake_tween = create_tween()
	shake_tween.set_parallel(false)
	
	# 1. 위로 흔들림
	shake_tween.tween_property(weapon_mesh, "position:y", 
		original_position.y + shake_intensity, shake_speed)
	shake_tween.tween_property(weapon_mesh, "rotation:z", 
		original_rotation.z + 0.1 * shake_intensity, shake_speed)
	
	# 2. 아래로 흔들림
	shake_tween.tween_property(weapon_mesh, "position:y", 
		original_position.y - shake_intensity * 0.5, shake_speed)
	shake_tween.tween_property(weapon_mesh, "rotation:z", 
		original_rotation.z - 0.05 * shake_intensity, shake_speed)
	
	# 3. 위로 다시
	shake_tween.tween_property(weapon_mesh, "position:y", 
		original_position.y + shake_intensity * 0.3, shake_speed)
	
	# 4. 원위치
	shake_tween.tween_property(weapon_mesh, "position:y", 
		original_position.y, shake_speed * 1.5)
	shake_tween.tween_property(weapon_mesh, "rotation:z", 
		original_rotation.z, shake_speed * 1.5)

# 칼 찌르기 애니메이션
func _play_stab_animation():
	if not weapon_mesh:
		return
	
	var original_position = weapon_mesh.position
	var original_rotation = weapon_mesh.rotation
	
	var tween = create_tween()
	tween.set_parallel(false)
	
	# 1. 뒤로 당기기 (준비 동작) - 크게!
	tween.tween_property(weapon_mesh, "position", 
		original_position + Vector3(-0.1, -0.1, 0.4), 0.12)
	
	# 2. 빠르게 앞으로 찌르기 - 훨씬 더 크게!
	tween.set_parallel(true)
	tween.tween_property(weapon_mesh, "position", 
		original_position + Vector3(0.05, 0, -0.6), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon_mesh, "rotation:z", 
		original_rotation.z + 0.2, 0.1)  # 약간 회전
	
	# 3. 원위치 복귀 - 탄성 효과
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(weapon_mesh, "position", 
		original_position, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon_mesh, "rotation:z", 
		original_rotation.z, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

