extends Area2D

const  ballon = preload("res://text_ui.tscn")

@export var dia_resource : DialogueResource
@export var dia_start : String = "start"
#대화하기
func action() -> void:
	if Gamemaneger.talking:
		return
	var Ballon = ballon.instantiate()
	get_tree().current_scene.add_child(Ballon)
	Ballon.start(dia_resource,dia_start)
