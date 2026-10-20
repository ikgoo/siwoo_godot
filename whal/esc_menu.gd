extends Control

func _unhandled_input(event):
	if not event.is_action_pressed("esc"):
		return
	get_viewport().set_input_as_handled()
	if Gamemaneger.close_top():
		return
	if Gamemaneger.can_pause():
		open()

func open():
	visible = true
	get_tree().paused = true
	Gamemaneger.push_ui(self)

func close():
	visible = false
	get_tree().paused = false
	Gamemaneger.pop_ui(self)

func _on_resume_button_down():
	close()

func _on_go_to_title_button_down():
	close()
	Gamemaneger.cam_moving = false
	Gamemaneger.restart_map("res://start_ui.tscn")

func _on_quit_button_down():
	get_tree().quit()
