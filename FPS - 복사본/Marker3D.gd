extends Marker3D
@onready var timer = $Timer
@export var target : Marker3D
@export var player : CharacterBody3D
@export var nav : NavigationAgent3D
@export var hud : Control
var mob = load("res://mob.tscn")
var instance

func _ready():
	timer.start()


func _on_timer_timeout():
	instance = mob.instantiate()
	instance.nav = nav
	instance.target = target
	instance.player = player
	instance.hud = hud
	instance.global_position = global_position
	get_tree().current_scene.add_child(instance)
