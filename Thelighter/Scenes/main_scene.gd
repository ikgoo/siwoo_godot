extends Node2D

@onready var animation_player = $AnimationPlayer
@onready var animation_player_2 = $AnimationPlayer2
var re = 1


# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play("big")


# Called every frame. 'delta' is the elapsed time since the previous frame.




