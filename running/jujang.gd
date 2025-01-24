extends Node3D
@onready var charater = $Jet

@onready var timer = $Timer

@onready var obstacle_scene = preload("res://jang_ae_water.tscn")
const JANG_AE_EAT = preload("res://jang_ae_eat.tscn")
# Called when the node enters the scene tree for the first time.


@export var noise = FastNoiseLite.new()
var current_time = 0.0
var check_timer = 0.0
var check_interval = 0.2  # 1초마다 체크
var noise_speed = 0.3    # 노이즈가 흐르는 속도
var threshold = 0.6     # 장애물 생성 임계값

# 스폰 영역 설정
var spawn_width = 100.0   # X축 범위 (-5 ~ 5)
var spawn_height = 100.0  # Y축 범위 (-5 ~ 5)
var grid_size = 20      # 격자 크기 (체크할 포인트 수)


func _ready():
	# 노이즈 설정
	noise.seed = randi()
	noise.frequency = 0.05  # 노이즈 패턴의 크기 조절
	noise.fractal_octaves = 2
	
func _process(delta):
	if not Gamemanager.end:
		Gamemanager.jumsu += 20 * delta
		Gamemanager.jumsu = ceil(Gamemanager.jumsu)
		if Gamemanager.jumsu >= 5000 * Gamemanager.went:
			Gamemanager.here = "earth"
			charater.animation_player.play("go_to_planet")
			
			Gamemanager.went += 1
			Gamemanager.speed += 0.2
			Gamemanager.go_speed += 1
	current_time += delta * noise_speed  # 시간에 따라 노이즈 패턴이 흐름
	check_timer += delta
	
	# 1초마다 장애물 체크 및 생성
	if check_timer >= check_interval:
		check_timer = 0
		check_noise_points()
		
	if randi_range(0,10) == 0:
		var jang_ae_eat = JANG_AE_EAT.instantiate()
		jang_ae_eat.position = Vector3(charater.position.x + randf_range(-50, 50),charater.position.y + randf_range(-50, 50),charater.position.z - 100)
		add_child(jang_ae_eat)
		
func check_noise_points():
	# 캐릭터 위치를 중심으로 격자 생성
	var start_x = charater.position.x - spawn_width / 2
	var start_y = charater.position.y - spawn_height / 2
	
	var step_x = spawn_width / grid_size
	var step_y = spawn_height / grid_size
	
	for i in grid_size:
		for j in grid_size:
			# 캐릭터 위치 기준으로 상대적인 x, y 계산
			var x = start_x + (i * step_x)
			var y = start_y + (j * step_y)
			
			# 노이즈 값 계산 (월드 좌표 기준으로 계산)
			var noise_value = noise.get_noise_2d(x + current_time, y + current_time)
			# 노이즈 값 범위를 0~1로 변환 (-1~1 → 0~1)
			noise_value = (noise_value + 1) / 2
			
			# 임계값 이상인 경우에만 장애물 생성
			if noise_value >= threshold:
				spawn_obstacle(x, y)
			if noise_value < 0.4:
				if randi_range(0,10) == 0:
					var jang_ae_eat = JANG_AE_EAT.instantiate()
					jang_ae_eat.position = Vector3(x, y, charater.position.z - 100)
					add_child(jang_ae_eat)
func spawn_obstacle(x: float, y: float):
	var obstacle = obstacle_scene.instantiate()
	add_child(obstacle)
	# 시작 위치 설정 (z축은 먼 거리에서 시작)
	obstacle.position = Vector3(x, y, charater.position.z - 100)
	
