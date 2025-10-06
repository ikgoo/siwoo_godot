extends CSGCombiner3D

@onready var animation_player = $AnimationPlayer
var thing = "op"
@onready var animation_player_2 = $AnimationPlayer2
@onready var animation_player_3 = $AnimationPlayer3

var f_o = true
var s_o = true
var t_o = true

func op_cl(area):
	print(area.collision_layer,"        ",(1 << 5) | (1 << 23))
	match area.collision_layer:
		(1 << 5) | (1 << 21):
			if f_o:
				animation_player.play("first_o")
				f_o = false
			else:
				animation_player.play("first_c")
				f_o = true
		(1 << 5) | (1 << 22):
			if s_o:
				animation_player_2.play("se_o")
				s_o = false
			else:
				animation_player_2.play("se_c")
				s_o = true
		(1 << 5) | (1 << 23):
			if t_o:
				animation_player_3.play("third_o")
				t_o = false
			else:
				animation_player_3.play("third_c")
				t_o = true
