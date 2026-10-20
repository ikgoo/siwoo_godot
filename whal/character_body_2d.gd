extends CharacterBody2D

const HIT = preload("uid://cwo2wmhos5uxk")
const COIN = preload("uid://srnr3e48tg4f")
const INCOIN = preload("uid://cgo68mxle2wsa")
const MOB_ARROW = preload("uid://d4afw7bstgt6h")

#변수
var hp = 100
var facing_right = false
var now_anime = 0
var is_dead = false
var speed = 40
@onready var ray_cast_2d = $RayCast2D
@onready var collision_shape_2d = $Area2D2/CollisionShape2D
var blind = false
#얘들
@onready var line_2d = $Line2D
@onready var progress_bar_2 = $ProgressBar2
@onready var found = $found
@onready var wait = $wait
@onready var area_2d = $Area2D
@onready var animation_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var timer = $Timer
enum Doing { IDLE, SAW, IN, ATTACK }
var doing: Doing = Doing.IDLE:
	set(value):
		if doing == value:
			return
		doing = value
		if not is_node_ready():
			return
		match doing:
			Doing.IDLE:
				found.visible = false
				wait.visible = false
				line_2d.visible = false
				timer.stop()
			Doing.SAW:
				found.visible = true
				wait.visible = false
				line_2d.visible = true
			Doing.IN:
				found.visible = false
				wait.visible = true
				line_2d.visible = false
				timer.stop()
			Doing.ATTACK:
				timer.stop()

#애니메이션 설정
func animation():
	#땅에 있을때
	if is_on_floor():
		sprite.flip_h = false
		#움직일때
		if abs(velocity.x) > 1:
			facing_right = velocity.x > 0
			if facing_right:
				if not now_anime == 1:
					animation_player.play("right_walk")
					now_anime = 1
			else:
				if not now_anime == 2:
					animation_player.play("left_walk")
					now_anime = 2
		#가만히 있을때
		else:
			if facing_right:
				if not now_anime == 3:
					animation_player.play("right_idle")
					now_anime = 3
			else:
				if not now_anime == 4:
					animation_player.play("left_idle")
					now_anime = 4
	#떨어질때
	else:
		if not now_anime == 5:
			animation_player.play("jump")
			now_anime = 5
		sprite.flip_h = not facing_right
func drop_coin():
	var coin = COIN.instantiate()
	coin.global_position = global_position
	coin.velocity = Vector2(randi_range(-100,100),randi_range(-100,-200))
	get_parent().add_child(coin)
func drop_incoin():
	var coin = INCOIN.instantiate()
	coin.global_position = global_position
	coin.velocity = Vector2(randi_range(-100,100),randi_range(-100,-200))
	get_parent().add_child(coin)

#죽을때 death 애니메이션 다 재생하고 삭제
func die():
	timer.stop()
	is_dead = true
	drop_coin()
	drop_incoin()
	drop_incoin()

	#더 이상 화살 맞거나 공격 안하게
	area_2d.set_deferred("monitorable", false)
	animation_player.play("death")
	await animation_player.animation_finished
	queue_free()

#중력
func _physics_process(delta):
	progress_bar_2.value = hp
	ray_cast_2d.target_position = to_local(Gamemaneger.character.global_position)
	ray_cast_2d.force_raycast_update()
	if facing_right:
		collision_shape_2d.position.x = 11.0
	else:
		collision_shape_2d.position.x = -11.0
		
		
	if doing == Doing.IN:
		if facing_right:
			if Gamemaneger.character.global_position.x > global_position.x:
				if can_see_player():
					doing = Doing.SAW
		else:
			if Gamemaneger.character.global_position.x < global_position.x:
				if can_see_player():
					doing = Doing.SAW
		if facing_right:
			velocity.x = speed
		else:
			velocity.x = speed * -1
	

	if doing == Doing.IDLE:
		if facing_right:
			velocity.x = speed
		else:
			velocity.x = speed * -1
	if doing == Doing.SAW:
		if facing_right:
			if Gamemaneger.character.global_position.x < global_position.x:
				facing_right = false
		else:
			if Gamemaneger.character.global_position.x > global_position.x:
				facing_right = true
		velocity.x = 0
		if can_see_player():
			line_2d.set_point_position(1, to_local(Gamemaneger.character.global_position))
			if timer.is_stopped():
				timer.start()
		else:
			doing = Doing.IN
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		if velocity.y > 0:
			velocity.y = 0
	if is_on_wall():
		facing_right = !facing_right
		collision_shape_2d.position.x = collision_shape_2d.position.x * -1
	move_and_slide()
	if slamming and is_on_floor():
		slamming = false
		Gamemaneger.getting_hurt(self,false,false,20)

#추락 아이템으로 내리꽂기
const SLAM_POWER = 900.0
const SLAM_RANGE = 50.0
const SLAM_DAMAGE = 40
var slamming = false

func slam():
	slamming = true
	velocity.y = SLAM_POWER



func _process(delta):
	#죽는중이면 아무것도 안함
	if is_dead:
		return
	#죽이기
	if hp <= 0:
		die()
		return
	animation()

func can_see_player() -> bool:
	if global_position.distance_to(Gamemaneger.character.global_position) < 24.0:
		return true
	return ray_cast_2d.get_collider() == Gamemaneger.character

#데미지 입었을때
func hurt(arrow,thing :  bool = false):

	if not  thing:
		Gamemaneger.camera.hurt()
		var hit_e = HIT.instantiate()
		hit_e.global_position = global_position
		get_parent().add_child(hit_e)
		if is_dead:
			return
		if global_position.x < Gamemaneger.character.global_position.x:
			facing_right = true
		else:
			facing_right = false
	else:
		Gamemaneger.camera.hurt()
		var hit_e = HIT.instantiate()
		hit_e.global_position = global_position
		get_parent().add_child(hit_e)


func _on_visible_on_screen_notifier_2d_screen_entered():
	Gamemaneger.mobs.append(self)
	

func _on_visible_on_screen_notifier_2d_screen_exited():
	Gamemaneger.mobs.erase(self)






func _on_area_2d_2_body_exited(body):
	if doing != Doing.IDLE:
		return
	facing_right = !facing_right
	collision_shape_2d.position.x = collision_shape_2d.position.x * -1


func _on_area_2d_2_area_entered(area):
	doing = Doing.IN


func _on_timer_timeout():
	if doing == Doing.SAW:
		var arr = MOB_ARROW.instantiate()
		arr.dir = Gamemaneger.character.global_position
		arr.global_position = global_position
		arr.damage = 10
		arr.strengh = 300
		get_parent().add_child(arr)



func _on_area_2d_2_area_exited(area):
	doing = Doing.IDLE
