extends Node2D
@onready var master = $master_volume/master
@onready var music = $music_volume/music
@onready var sound = $sound_volume/sound
@onready var label_2m = $master_volume/Label2m
@onready var label_2_mu = $music_volume/Label2mu
@onready var label_2s = $sound_volume/Label2s


# Called when the node enters the scene tree for the first time.
func _ready():
	# 슬라이더 초기값 설정
	master.value = Gamemaneger.master_volume
	music.value = Gamemaneger.music_volume
	sound.value = Gamemaneger.sfx_volume


func _on_button_button_down():
	get_tree().change_scene_to_file("res://title.tscn")


func _on_master_value_changed(value):
	label_2m.text = str(master.value) + "%"
	set_bus_volume("Master",master.value)

func _on_music_value_changed(value):
	label_2_mu.text = str(music.value) + "%"
	set_bus_volume("MUSIC",music.value)


func _on_sound_value_changed(value):
	label_2s.text = str(sound.value) + "%"
	set_bus_volume("SFX",sound.value)

func slider_to_db(slider_value):
	# 0은 음소거(-80dB), 100은 최대 볼륨(0dB)
	if slider_value <= 0:
		return -80.0  # 완전 음소거
	else:
		# 로그 스케일로 변환 (인간의 청각은 로그 스케일에 가까움)
		return linear_to_db(slider_value / 100.0)

# 버스 볼륨 설정 함수
func set_bus_volume(bus_name, slider_value):
	var bus_index = AudioServer.get_bus_index(bus_name)
	var db_value = slider_to_db(slider_value)
	AudioServer.set_bus_volume_db(bus_index, db_value)
