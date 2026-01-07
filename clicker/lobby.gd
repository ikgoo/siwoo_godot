extends Node2D
@onready var start = $start

const MINC_CLICKER_LOBBY_BUTTON_START_3 = preload("uid://byi030cxhp7oc")

@onready var animation_player = $AnimationPlayer

func _on_start_button_up():
	animation_player.play("close")
	start.texture_normal = MINC_CLICKER_LOBBY_BUTTON_START_3
	start.texture_hover = MINC_CLICKER_LOBBY_BUTTON_START_3

func _on_setting_button_up():
	pass


func _on_exit_button_up():
	get_tree().quit()

func go():
	get_tree().change_scene_to_file("res://main.tscn")
