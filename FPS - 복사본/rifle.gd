extends ARMED

func _ready():
	animation_player = $AnimationPlayer
	animation_player.connect("animation_finished", on_animation_finished) 




func _on_timer_timeout():
	ok_naw()
