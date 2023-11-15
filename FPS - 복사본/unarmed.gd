extends ARMED

@onready var animtion = $AnimationPlayer
func _process(delta):
	if global_position.x != -0.48:
		animtion.play("pistol")
func fire():
	pass
	
func reload():
	pass
func fire_stop():
	pass 

