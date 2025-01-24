extends Node3D
@onready var charater = $Jet
const JANG_AE_WATER = preload("res://tree.tscn")
@onready var jet = $Jet
var first = true
@onready var label = $Control/Label
const JANG_AE_EAT = preload("res://jang_ae_eat.tscn")
@onready var timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready():
	timer.start()
	jet.earth()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Gamemanager.end:
		label.text = str(Gamemanager.jumsu)
		Gamemanager.jumsu += 40 * delta
		Gamemanager.jumsu = ceil(Gamemanager.jumsu)
		if Gamemanager.jumsu >= 5000 * Gamemanager.went:
			Gamemanager.here = "space"
			charater.animation_player.play("go_to_planet")
			
			Gamemanager.went += 1
			Gamemanager.speed += 0.05
			Gamemanager.go_speed += 0.5
		if Gamemanager.here == "earth":
			if first:
				jet.earth()
				first = false
		if jet.position.x < -50:
			jet.stuck = "left"
		elif jet.position.x > 60:
			jet.stuck = "right"
		else:
			jet.stuck = "front"


func _on_timer_timeout():
		var jang_ae_mul_1 = JANG_AE_WATER.instantiate()
		jang_ae_mul_1.position = Vector3(charater.position.x + randf_range(-100, 100),-10,charater.position.z - 100)
		add_child(jang_ae_mul_1)
		var jang_ae_mul_2 = JANG_AE_WATER.instantiate()
		jang_ae_mul_2.position = Vector3(charater.position.x + randf_range(-100, 100),-10,charater.position.z - 100)
		add_child(jang_ae_mul_2)
		var jang_ae_mul_3 = JANG_AE_WATER.instantiate()
		jang_ae_mul_3.position = Vector3(charater.position.x + randf_range(-100, 100),-10,charater.position.z - 100)
		add_child(jang_ae_mul_3)
		var jang_ae_mul_4 = JANG_AE_WATER.instantiate()
		jang_ae_mul_4.position = Vector3(charater.position.x + randf_range(-100, 100),-10,charater.position.z - 100)
		add_child(jang_ae_mul_4)
		var jang_ae_mul_5 = JANG_AE_WATER.instantiate()
		jang_ae_mul_5.position = Vector3(charater.position.x + randf_range(-100, 100),-10,charater.position.z - 100)
		add_child(jang_ae_mul_5)
		if randi_range(0,10) == 0:
			var jang_ae_eat = JANG_AE_EAT.instantiate()
			jang_ae_eat.position = Vector3(charater.position.x + randf_range(-100, 100),-9,charater.position.z - 100)
			add_child(jang_ae_eat)
		if randi_range(0,10) == 0:
			var jang_ae_eat_2 = JANG_AE_EAT.instantiate()
			jang_ae_eat_2.position = Vector3(charater.position.x + randf_range(-100, 100),-9,charater.position.z - 100)
			add_child(jang_ae_eat_2)
