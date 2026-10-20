extends Node2D

@onready var animation_player = $AnimationPlayer
@export var power = 250.0
@export var up = 200.0
var in_m = []
# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("ex")
	

func ex():
	for i in in_m:
		i.hp -= 40
		i.velocity.y -= 50 * global_position.distance_to(i.global_position)

func _on_area_2d_area_entered(area):
	in_m.append(area.get_parent())

func _on_area_2d_area_exited(area):
	in_m.erase(area.get_parent())
