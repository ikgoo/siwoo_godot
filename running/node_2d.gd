extends Node2D
@onready var animation_player = $AnimationPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_button_mouse_entered():
	animation_player.play("up")

func _on_button_mouse_exited():
	animation_player.play("down")


func _on_button_button_up():
	get_tree().change_scene_to_file("res://game_scene.tscn")


func _on_button_button_down():
	get_tree().change_scene_to_file("res://game_scene.tscn")
