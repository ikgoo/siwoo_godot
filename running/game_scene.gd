extends Node3D
@onready var charater = $Jet

@onready var timer = $Timer
@onready var audio_stream_player = $AudioStreamPlayer

const JANG_AE_WATER = preload("res://jang_ae_water.tscn")
const JANG_AE_EAT = preload("res://jang_ae_eat.tscn")
# Called when the node enters the scene tree for the first time.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Gamemanager.end:
		Gamemanager.jumsu += 1
		if Gamemanager.jumsu >= 5000 * Gamemanager.went:
			Gamemanager.here = "earth"
			charater.animation_player.play("go_to_planet")
			
			Gamemanager.went += 1
			Gamemanager.speed += 0.05
			Gamemanager.go_speed += 0.5
		var jang_ae_mul_1 = JANG_AE_WATER.instantiate()
		var jang_ae_mul_2 = JANG_AE_WATER.instantiate()
		var jang_ae_mul_3 = JANG_AE_WATER.instantiate()
		jang_ae_mul_1.position = Vector3(charater.position.x + randf_range(-50, 50),charater.position.y + randf_range(-50, 50),charater.position.z - 100)
		jang_ae_mul_2.position = Vector3(charater.position.x + randf_range(-50, 50),charater.position.y + randf_range(-50, 50),charater.position.z - 100)
		jang_ae_mul_3.position = Vector3(charater.position.x + randf_range(-50, 50),charater.position.y + randf_range(-50, 50),charater.position.z - 100)
		add_child(jang_ae_mul_1)
		add_child(jang_ae_mul_2)
		add_child(jang_ae_mul_3)
		if randi_range(0,10) == 0:
			var jang_ae_eat = JANG_AE_EAT.instantiate()
			jang_ae_eat.position = Vector3(charater.position.x + randf_range(-50, 50),charater.position.y + randf_range(-50, 50),charater.position.z - 100)
			add_child(jang_ae_eat)
