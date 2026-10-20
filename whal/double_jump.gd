extends AnimatedSprite2D

@onready var animation_player = $AnimationPlayer
var what = "jump"
# Called when the node enters the scene tree for the first time.
func _ready():
	if what == "jump":
		animation_player.play("jump")
	else:
		animation_player.play("dash")
		scale = scale * 2
		
