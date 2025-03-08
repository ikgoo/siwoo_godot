extends Node

var stars: Array[Node2D] = []
var stardust: int = 0
var speed_level: int = 1
var collect_level: int = 1
var spawn_level: int = 1  # spawn_level 변수 추가
const SPEED_INCREASE = 100  # 50 -> 75 (1.5배 증가)
const BASE_COLLECT_AMOUNT = 5  # 기본 수집량

# 볼륨 관련 변수 추가
var master_volume = 100
var music_volume = 100
var sfx_volume = 100
#
#func _ready():
	#AudioServer.set_bus_volume_db("Master", 100)
	#AudioServer.set_bus_volume_db(bus_index, db_value)
	#AudioServer.set_bus_volume_db(bus_index, db_value)

const MAX_STARS = 1000  # 최대 별 개수 제한

func add_star(star: Node2D):
	# 최대 별 개수를 초과하지 않을 때만 추가
	if stars.size() < MAX_STARS:
		stars.append(star)
	else:
		# 최대 개수를 초과하면 랜덤한 별 제거
		var random_index = randi() % stars.size()
		var random_star = stars[random_index]
		stars.remove_at(random_index)
		random_star.queue_free()
		# 새로운 별 추가
		stars.append(star)

func remove_star(star: Node2D):
	stars.erase(star)

func get_available_stars() -> Array[Node2D]:
	return stars

func get_current_speed() -> float:
	return 60.0 + (speed_level - 1) * SPEED_INCREASE  # 기본 속도 60에서 레벨당 75씩 증가

func get_collect_amount() -> int:
	return BASE_COLLECT_AMOUNT * collect_level

var cam_go = true

var star_get = 0  # 별 획득 카운터
var star_reset_timer = null  # 타이머 변수

func add_star_get():
	star_get += 1
	Main.timer_2.start()

# 마스터 볼륨 설정
func set_master_volume(value):
	master_volume = value
	# 모든 볼륨에 마스터 볼륨 적용
	apply_music_volume()
	apply_sfx_volume()

# 음악 볼륨 설정
func set_music_volume(value):
	music_volume = value
	apply_music_volume()

# 효과음 볼륨 설정
func set_sfx_volume(value):
	sfx_volume = value
	apply_sfx_volume()

# 음악 볼륨 적용
func apply_music_volume():
	var db = linear_to_db(music_volume / 100.0 * master_volume / 100.0)
	# Main.audio_stream_player 대신 Main.audio_stream_player_2d_2 사용
	Main.audio_stream_player_2d_2.volume_db = db

# 효과음 볼륨 적용
func apply_sfx_volume():
	var volume = sfx_volume / 100.0 * master_volume / 100.0
	# 모든 효과음 노드들의 볼륨 조정
	get_tree().call_group("sound_effects", "set_volume", volume)
