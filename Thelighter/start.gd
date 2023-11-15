extends Control


	
@onready var animation_player = $AnimationPlayer
@onready var texture_button = $TextureButton
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_texture_button_mouse_entered():
	animation_player.play("enter")



func _on_texture_button_mouse_exited():
	animation_player.play("exit")


func _on_texture_button_button_down():
	animation_player.play("press")


func _on_texture_button_button_up():
	animation_player.play("out")
