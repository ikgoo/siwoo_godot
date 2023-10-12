extends ARMED

@onready var animtion = $AnimationPlayer
func _process(delta):
	if position.x != 0.501:
		animtion.play("rifle")
func fire():
	pass
	
func reload():
	pass
func fire_stop():
	pass 

