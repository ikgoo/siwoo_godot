extends Node2D
@onready var animation_player = $AnimationPlayer
@onready var timer = $Timer
var star_scene = preload("res://big_cow_star.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	hide()  # 처음에는 숨김



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass





func t_st():
	visible = true
	animation_player.play("new_animation")

	var star = star_scene.instantiate()
	star.position = Vector2(
		randf_range(-2000, 2000) + position.x,
		randf_range(-1000, 1000) + position.y
	)
	star.get_s = 50
	star.modulate = Color(1.4, 1.2, 0.6, 1)  # 황백색
	get_parent().add_child(star)

func end():
	if Main.end:
		animation_player.play("end")
