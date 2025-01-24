extends Node3D
@onready var animation_player = $Node3D2/Control/Control/Button/AnimationPlayer
@onready var animation_player_2 = $Node3D2/Control/Control/Button2/AnimationPlayer_2
@onready var world_environment = $WorldEnvironment
@onready var animation_player_3 = $Challenger/AnimationPlayer
@onready var animation_player_4 = $Node3D2/Control/Control/Button3/AnimationPlayer
@onready var audio_stream_player_3d = $AudioStreamPlayer3D

@onready var camera_3d = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	SpaceshipS.audio_stream_player.stream_paused = true
	animation_player_3.play("coming")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	world_environment.environment.sky_rotation.y -= 0.001



func _on_button_mouse_entered():
	animation_player.play("up")


func _on_button_mouse_exited():
	animation_player.play("down")


func _on_button_button_down():
	SpaceshipS.audio_stream_player.play()
	SpaceshipS.audio_stream_player.stream_paused = false
	get_tree().change_scene_to_file("res://jujang.tscn")


func _on_button_2_button_down():
	get_tree().change_scene_to_file("res://ranking.tscn")


func _on_button_2_mouse_entered():
	animation_player_2.play("up")


func _on_button_2_mouse_exited():
	animation_player_2.play("down")

func animate():
	animation_player_3.play("hundulllim")


func _on_button_3_button_down():
	get_tree().quit()


func _on_button_3_mouse_entered():
	animation_player_4.play("up")


func _on_button_3_mouse_exited():
	animation_player_4.play("down")


func _on_audio_stream_player_3d_finished():
	audio_stream_player_3d.play()
