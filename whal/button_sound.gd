extends AudioStreamPlayer

func _ready():
	if get_parent() is BaseButton:
		get_parent().button_down.connect(play)
