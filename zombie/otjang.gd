extends CSGCombiner3D

@onready var animation_player = $AnimationPlayer
var thing = "op"
var op = true


func op_cl(c):
	if op:
		animation_player.play("open")
		op = false
	elif not op:
		animation_player.play("close")
		op = true
