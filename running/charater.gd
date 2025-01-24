extends CharacterBody3D
@onready var for_rot = $for_rot
@onready var for_rot_2 = $for_rot/for_rot2
@onready var camera_3d = $"../Camera3D2"
@onready var animation_player = $for_rot/for_rot2/AnimationPlayer
@onready var ui = $CanvasLayer/UI
@onready var high_l = $CanvasLayer/UI/high_l
@onready var score_l = $CanvasLayer/UI/score_l
@onready var restart = $CanvasLayer/UI/restart
@onready var rank_p = $CanvasLayer/UI/rank_p
@onready var lobby = $CanvasLayer/UI/lobby
@onready var fire_part = $for_rot/for_rot2/fire_part
@onready var fire_part_2 = $for_rot/for_rot2/fire_part_2
@onready var not_8 = $CanvasLayer/UI/not_8
@onready var timer = $Timer
@onready var succeed = $CanvasLayer/UI/succeed
@onready var text_edit = $CanvasLayer/UI/Label2/TextEdit
@onready var gpu_particles_3d = $GPUParticles3D
@onready var label_2 = $CanvasLayer/UI/Label2
@onready var audio_stream_player_3d = $AudioStreamPlayer3D
@onready var succeed_2 = $CanvasLayer/UI/succeed2

var stuck = "null"
var dir = "front"
var ACCELERATION = 2
var ud = true
var going_planet = false
var direction
var dird
var FRICTION = 7.0
var dird_dir = "null"

#func _ready():
	#FirebaseData.data_loaded.connect(_on_data_loaded)

func _process(delta):
	if not Gamemanager.end:
		velocity.z = Gamemanager.speed * -60

		if not going_planet:
			move_and_slide()
		else:
			position.z -= Gamemanager.speed
		camera_3d.position.z = position.z + 1.2
		camera_3d.position.x = lerp(camera_3d.position.x, position.x, 1)
		camera_3d.position.y = lerp(camera_3d.position.y, position.y + 1, 1)
		
func _input(event):
	if not Gamemanager.end:
		if not going_planet:

			
			#if direction != Vector3.ZERO:
				#velocity.x = move_toward(velocity.x, direction.x * MAX_SPEED, ACCELERATION)
				#print(velocity.x)
				#velocity.y = move_toward(velocity.y, direction.y * MAX_SPEED, ACCELERATION)
				#
				## BlendSpace2D 파라미터 업데이트
			#else:
				#velocity.x = move_toward(velocity.x, 0, FRICTION)
				#velocity.y = move_toward(velocity.y, 0, FRICTION)
			##animation_tree.set("parameters/blend_position",velocity.normalized().x)
			#
			#animation_tree.  <-- 이부분에 넣고 싶어
			
			direction = Input.get_axis("a","d")
			dird = Input.get_axis("w","s")
			
			if dir != "right":
				if direction == 1:
					animation_player.play("right")
					dir = "right"
			if dir != "left":
				if direction == -1:
					animation_player.play("left")
					dir = "left"
			if dir != "front":
				if direction == 0:
					animation_player.play("ud_front")
					dir = "front"
			if stuck == "left":
				if direction == -1:
					direction = 0
					animation_player.play("ud_front")
			elif stuck == "right":
				if direction == 1:
					direction = 0
					animation_player.play("ud_front")
			if dird_dir != "up":
				if dird == -1:
					animation_player.play("up")
					dird_dir = "up"
			if dird_dir != "down":
				if dird == 1:
					animation_player.play("down")
					dird_dir = "down"
			if dird_dir != "front":
				if dird == 0:
					animation_player.play("front")
					dird_dir = "front"

			velocity.x = direction * Gamemanager.go_speed
			velocity.y = dird * Gamemanager.go_speed * -1
			if not ud:
				velocity.y = 0
			
func _on_area_3d_area_entered(area):
	if not going_planet:
		Gamemanager.high_score_get()
		ui.visible = true
		high_l.text = "high score:" + str(Gamemanager.high_score)
		score_l.text = "score:" + str(Gamemanager.jumsu)
func earth():
	ud = false

func all_down():
	fire_part.all_visible(false)
	fire_part_2.all_visible(false)
func all_up():
	fire_part.all_visible(true)
	fire_part_2.all_visible(true)
func go_earth():
	if Gamemanager.here == "earth":
		get_tree().change_scene_to_file("res://earth.tscn")
		
	elif Gamemanager.here == "space":
		get_tree().change_scene_to_file("res://jujang.tscn")
		
func going_planet_f():
	direction = 0
	dird = 0
	going_planet = true
	


func _on_button_button_down():
	Gamemanager.jumsu = 0
	Gamemanager.go_speed = 14
	Gamemanager.speed = 0.6
	Gamemanager.end = false
	Gamemanager.here = "space"
	Gamemanager.went = 1
	ui.visible = false
	get_tree().change_scene_to_file("res://jujang.tscn")
	


func _on_area_3d_body_entered(body):
	if not going_planet:
		Gamemanager.end = true
		Gamemanager.high_score_get()
		ui.visible = true
		high_l.text = "high score:" + str(Gamemanager.high_score)
		score_l.text = "score:" + str(Gamemanager.jumsu)
	

func _on_rank_p_button_down():
	var d = await HttpModule.get_rankings()
	if len(d) >= 8:
		if d[8] > Gamemanager.jumsu:
			noteight()
		else:
			label_2.visible = true
			print(d)
			
	

#func _on_data_loaded(rank_data):
	#label_2.visible = true


func _on_lobby_button_down():
	Gamemanager.jumsu = 0
	Gamemanager.go_speed = 14
	Gamemanager.speed = 0.6
	Gamemanager.end = false
	Gamemanager.here = "space"
	Gamemanager.went = 1
	ui.visible = false
	get_tree().change_scene_to_file("res://start_ui.tscn")
	rank_p.visible = true

func noteight():
	not_8.visible = true
	timer.start()
func _on_text_edit_text_changed():
	if Input.is_key_pressed(KEY_ENTER):
		if text_edit.text.length() >= 10:
			succeed_2.visible = true
			timer.start()
		else:
			label_2.visible = false
			var a = await HttpModule.save_ranking(text_edit.text,Gamemanager.jumsu)
			#var a = FirebaseData.check_and_update_ranking(text_edit.text,Gamemanager.jumsu)
			#if a:
				#noteight()
			#else:
				#rank_p.visible = false
				#succeed.visible = true
				#timer.start()

func _on_timer_timeout():
	not_8.visible = false
	succeed.visible = false
	succeed_2.visible = false
