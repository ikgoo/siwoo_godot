extends CharacterBody2D
const LASER = preload("uid://bk1d7s5kwq2fr")
const BULLET_SPAWN = preload("uid://d4ibkekd2bg3")
const HIT = preload("uid://cwo2wmhos5uxk")

#얘들
@onready var laser_timer = $laser_timer
@onready var attack_timer = $attack_timer
@onready var attack_area = $attack_area
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var animation_player = $AnimationPlayer
@onready var skill_timer = $skill_timer
var rand = -1
var hp = 1500
var flip = true
var lazer = 0
var used_tel = false
var damage = 40
var can_attack = false
func _ready():
	animation_player.play("idle")
	random_skill()
func _process(delta):
	if can_attack:
		if hp <= 0:
			animation_player.play("dead")
			skill_timer.stop()
		if not is_on_floor():
			velocity += get_gravity() * delta
		if Gamemaneger.character.global_position.x < global_position.x:
			flip = true
		else:
			flip = false
		if flip:
			animated_sprite_2d.flip_h  = true
			if attack_area.position.x > 0:
				attack_area.position.x = attack_area.position.x * -1
		else:
			animated_sprite_2d.flip_h  = false
			if attack_area.position.x < 0:
				attack_area.position.x = attack_area.position.x * -1
		move_and_slide()
	else:
		hp = 1500
func normal_attack():
	animation_player.play("idle")
	attack_timer.start()

func start():
	skill_timer.autostart = true
	can_attack = true
	skill_timer.start()

func l_teleport():
	global_position = Gamemaneger.character.global_position
	global_position.x -= 30
	global_position.y -= 5
	animation_player.play("appear")


func r_teleport():
	global_position = Gamemaneger.character.global_position
	global_position.x += 30
	global_position.y -= 5
	animation_player.play("appear")


func parring():
	pass

func jang_pan_attack():
	lazer = 0
	laser_timer.start()

func _on_attack_timer_timeout():
	animation_player.play("attack")


func random_skill():
	
	var pre = rand
	rand = randi_range(0,4)



	while pre == rand:

		rand = randi_range(0,4)
	if rand == 0:	
		animation_player.play("teleport_left")
	if rand == 1:
		jang_pan_attack()
	if rand == 3:
		summon_bullet(14,100)
		

#소환진을 원형으로 깔고 바깥쪽으로 쏘기
func summon_bullet(count, radius):
	for i in count:
		var sp = BULLET_SPAWN.instantiate()
		get_parent().add_child(sp)
		var ang = TAU * i / count
		sp.global_position = global_position + Vector2(radius, 0).rotated(ang)
		sp.dir = Vector2.RIGHT.rotated(ang)


func _on_laser_timer_timeout():
	var laser = LASER.instantiate()
	get_parent().add_child(laser)
	if lazer != 3:
		lazer += 1
		laser_timer.start()
	else:
		lazer = 0
	
func hurt(arrow, thing : bool = false):
	get_parent().camera_2d.hurt()
	var hit_e = HIT.instantiate()
	hit_e.global_position = global_position
	get_parent().add_child(hit_e)
	
func _on_area_2d_2_area_entered(area):
		Gamemaneger.hurt(damage)
		

func ani():
	animation_player.play("idle")
func _on_skill_timer_timeout():
	random_skill()
