extends AnimatedSprite2D

@onready var animation_player = $AnimationPlayer
@onready var area_2d = $Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	global_position = Gamemaneger.character.global_position
	global_position.y = 248.0 - 100
	animation_player.play("warn")

func explode():
	animation_player.play("explode")


func _on_area_2d_area_entered(area):
	Gamemaneger.hurt(2)
	area_2d.monitoring = false
