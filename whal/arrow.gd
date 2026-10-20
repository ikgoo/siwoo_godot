extends CharacterBody2D
#얘들
@onready var timer = $Timer
@onready var sprite_2d = $Sprite2D
@onready var line_2d = $Line2D
@onready var ray_cast_2d = $RayCast2D
const EX = preload("uid://c88rcc70u46kv")

#변수
@onready var audio_stream_player = $AudioStreamPlayer

var damage : int
var flying = true
var dir : Vector2
var strengh : int
var pre_pos = Vector2.ZERO
var though = 0
var already_shot = []
var ex = false
#강공격 화살인지(돌풍 화살용)
var big = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if Gamemaneger.ex > 0:
		Gamemaneger.ex -= 1
		ex = true
	#날아갈 각도
	look_at(get_global_mouse_position())
	if strengh < 30:
		strengh = 30
	



func _physics_process(delta):
	#날고있을때
	pre_pos = global_position
	if flying:
		line_2d.line()
		velocity = transform.x * strengh * 13
		velocity.y += 850 * delta
		
		move_and_slide()
		#빨라서 지나간 경우를 검사
		ray_cast_2d.target_position = pre_pos - global_position
		ray_cast_2d.force_raycast_update()
		if ray_cast_2d.is_colliding():
			var c = ray_cast_2d.get_collider()
			if not c.get_parent() in already_shot:
				_on_area_2d_2_area_entered(c)
				if not flying:
					global_position = c.global_position

		rotation = velocity.angle()
		ray_cast_2d.target_position = ray_cast_2d.to_local(pre_pos)
	else:
		line_2d.deleting()

#벽에 닿았을때
func _on_area_2d_body_entered(body):
	if ex:
		var e = EX.instantiate()
		e.global_position = global_position
		get_parent().add_child(e)
		ex = false
	gust()
	timer.start()
	flying = false
func gust():
	if big and Gamemaneger.gust > 0:
		Gamemaneger.launch(global_position)
		big = false

#5초뒤 삭제
func _on_timer_timeout():
	queue_free()

#적 닿았을때
func _on_area_2d_2_area_entered(area:Area2D):
	if ex:
		var e = EX.instantiate()
		e.global_position = global_position
		
		get_parent().add_child(e)
		ex = false
	for i in already_shot:
		if i == area.get_parent():
			return
	already_shot.append(area.get_parent())
	audio_stream_player.play()
	if area.get_collision_layer_value(8):
		if area.get_collision_layer_value(9):
			Gamemaneger.getting_hurt(area.get_parent(),true,true,strengh)
		else:
			Gamemaneger.getting_hurt(area.get_parent(),false,true,strengh)
		
	elif area.get_collision_layer_value(9):
		Gamemaneger.getting_hurt(area.get_parent(),true,false,strengh)
	else:
		Gamemaneger.getting_hurt(area.get_parent(),false,false,strengh)
	
	area.get_parent().hurt(self)
	gust()
	if Gamemaneger.though_arrow <= though:
		timer.start()
		flying = false
		reparent(area.get_parent())
	else:
		though += 1
