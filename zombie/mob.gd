extends CharacterBody3D
var hp = 100
@onready var animation_player = $AnimationPlayer
@onready var navigation_agent_3d = $NavigationAgent3D
var my_cha = null
func hp_out(dam):
	if hp > 0:
		hp -= dam
		if hp <= 0:
			animation_player.play("die")
		else:
			animation_player.play("hurt")

func _on_area_3d_2_area_entered(area):
	my_cha = area.get_parent()

func _on_area_3d_2_area_exited(area):
	my_cha = null
func _physics_process(delta):
	if hp > 0:
		if not is_on_floor():
			velocity += get_gravity() * delta
		if my_cha:
			var cha_pos = Charater.global_position
			navigation_agent_3d.set_target_position(cha_pos)
		
		var des = navigation_agent_3d.get_next_path_position()
		var local_des = des - global_position
		var dir = local_des.normalized()
		
		velocity = dir * 1
		move_and_slide()
