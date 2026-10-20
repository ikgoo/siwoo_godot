extends CharacterBody2D
#생성용
const ARROW = preload("uid://d4m6lntb3lf2l")


const DOUBLE_JUMP = preload("uid://v700tjv6p8jx")

const BIG_ARROW = preload("uid://x5euhmouku2t")

const JUMP_VELOCITY = -400.0
#패링 성공했을때
const PARRY_SLOW = 0.15        #느려지는 배속
const PARRY_SLOW_TIME = 0.45   #느려지는 시간 (진짜 초)
const PARRY_ARROW_POWER = 100  #반격 화살 세기
const PARRY_ZOOM = 1.5         #줌 빠지는 정도 (평소 2.0)
const PARRY_SHAKE = 5.0        #화면 흔들림 세기
#변수들
@onready var r_l = $r_l
var can_revive = true
var cant_move = false
var doing_s = false
var speed = 20.0
var face = 0
var is_charging = false
var zoom_tween: Tween
var is_dashing = false
var can_dash = true
var charge = 0
var max_speed = 150
var double_jump = true
var is_big_attacking = false
var can_big_attack = true
var going = Vector2.ZERO
var facing = 1
var now_anime = 0
var bow_anime
var pared =false
var dead = false
var gaksunged = false
var skill_cool = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
var can_get_item = []
#얘들
@onready var drop_timer = $drop_timer
@onready var action_finder = $action_finder
@onready var big_arrow_r = $big_arrow_r
@onready var big_arrow_t = $big_arrow_t
@onready var animation_player = $AnimationPlayer
@onready var effect_player = $effect_player
@onready var line_2d_2 = $Line2D2
@onready var reloadtimer = $reloadtimer
@onready var double_jump_p2 = $double_jump2
@onready var double_jump_p = $double_jump
@onready var dash_timer = $dash_timer
@onready var progress_bar = $ProgressBar
@onready var ray_cast = $bow/RayCast2D
@onready var line_2d = $Line2D
@onready var timer = $Timer
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var paring_t = $paring_t
@onready var bow = $bow
@onready var gpu_particles_2d = $GPUParticles2D
@onready var dash = $dash
@onready var hit = $hit
@onready var reload = $reload
@onready var charge_s = $charge
@onready var shoot_s = $shoot
func revive():
	Engine.time_scale = 0.4
	Gamemaneger.hp = Gamemaneger.max_hp * (Gamemaneger.respawn / 100.0)

func revive_end():
	Engine.time_scale = 1
func paring(time):
	effect_player.play("parry")
	paring_t.wait_time = time
	paring_t.start()
	get_parent().camera_2d.zoom = Vector2(1.9,1.9)
func _ready():
	Gamemaneger.character = self
	bow_anime = bow.animation_player
func _physics_process(delta):
	if gaksunged:
		gpu_particles_2d.emitting = true
	else:
		gpu_particles_2d.emitting = false
	if Gamemaneger.hp <= Gamemaneger.max_hp * (30/100.0):
		if not gaksunged:
			gaksunged = true
			if Gamemaneger.gaksung != 0:
				Gamemaneger.plusdamage += Gamemaneger.gaksung
	else:
		if gaksunged:
			gaksunged = false
			Gamemaneger.plusdamage -= Gamemaneger.gaksung
	#스킬 쿨 흐르기
	if not is_on_floor():
		if not is_dashing:
			velocity += get_gravity() * delta
	
	if not dead and not doing_s:
		for i in skill_cool.size():
			if skill_cool[i] > 0:
				skill_cool[i] -= delta
		#대화중이거나 창 열려있으면 아무것도 못함
		if Gamemaneger.talking or Gamemaneger.ui_open:
			going = Vector2.ZERO
			velocity.x = 0
			if not is_on_floor():
				velocity += get_gravity() * delta
			animation()
			
			return
		#원웨이 발판 뚫고 내려가기
		if Input.is_action_just_pressed("s") and is_on_floor():
			set_collision_mask_value(6, false)
			drop_timer.start()
		if Input.is_action_just_pressed('f'):
			if action_finder.get_overlapping_areas().size() > 0:
				action_finder.get_overlapping_areas()[0].action()
		#스킬 사용
		if Input.is_action_just_pressed("v"):
			can_get_item = can_get_item.filter(func(x): return is_instance_valid(x))
			if can_get_item.size() > 0:
				var got = can_get_item[0]
				while can_get_item.has(got):
					can_get_item.erase(got)
				Gamemaneger.get_scroll(got.thing,got)
		for i in Gamemaneger.skill_setting.size():
			if Input.is_action_just_pressed("skill" + str(i + 1)):
				use_skill(i)
		animation()
		if Gamemaneger.hp <= 0:
			if can_revive:
				if Gamemaneger.respawn != 0:
					animation_player.play("revive")
				else:
					animation_player.play("dead")
					cant_move = true
			else:
				animation_player.play("dead")
				cant_move = true
		#기본 공격 차징중일때
		if is_big_attacking:
			get_parent().cam_move()
		if is_charging:
			if charge < 100:
				charge += 3
				progress_bar.value = charge
			else:
				get_parent().cam_zoom(1.9,1.9,0.1)
		#빨간선
		if ray_cast.is_colliding():
			
			var a = ray_cast.get_collision_point()
			line_2d.set_point_position(1, ray_cast.get_collision_point()-global_position)
		var mouse_pos = get_global_mouse_position()
		#앞뒤 이미지
		if mouse_pos.x > global_position.x:
			bow.position.x = 6
		else:
			bow.position.x = -6

		#강공격
		if not can_big_attack:
			Gamemaneger.big_attack_cool = 1.0 - big_arrow_t.time_left / big_arrow_t.wait_time
		if Input.is_action_just_pressed("r_click") and can_big_attack and Gamemaneger.big_attack_n > 0:
			#기본공격 차징중이면 취소
			if is_charging:
				cancel_charging()
			bow_anime.play("big_zoom")
			charge_s.play()

			Engine.time_scale = 0.1
			line_2d.visible = true
			get_parent().cam_zoom(2.3,2.3,0.1)
			is_big_attacking = true
		elif Gamemaneger.big_attack_n <= 0:
			if big_arrow_r.is_stopped():
				big_arrow_r.start()
		if Input.is_action_just_released("r_click") and is_big_attacking:
			bow_anime.play("attack")
			charge_s.stop()
			shoot_s.play()
			var arrow = BIG_ARROW.instantiate()
			if Gamemaneger.ex:
				arrow.ex = true
				Gamemaneger.ex -= 1
			var direction = global_position.direction_to(mouse_pos)
			speed = 20
			max_speed = 150
			arrow.strengh = 200
			arrow.big = true
			arrow.global_position = global_position
			get_parent().add_child(arrow)
			is_big_attacking = false
			bow.attack()
			line_2d.visible = false
			Engine.time_scale = 1
			get_parent().cam_zoom(2,2,0.01)
			velocity = direction * -500
			can_big_attack = false
			Gamemaneger.big_attack_n -= 1
			Gamemaneger.big_attack_cool = 0.0
			big_arrow_t.start()
		if Gamemaneger.small_attack_n > 0: #탄창 췍
			
			if Input.is_action_just_pressed("click") and not is_big_attacking:
				get_parent().cam_zoom(1.95,1.95,1)
				bow_anime.play("zoom")
				charge_s.play()
				is_charging = true
				speed = 20
				max_speed = 120
			#차징중일때만 발사
			if Input.is_action_just_released("click") and is_charging:
				bow_anime.play("attack")
				charge_s.stop()
				shoot_s.play()
				get_parent().cam_zoom(2,2,0.1)
				line_2d_2.visible = false
				progress_bar.value = 0
				is_charging = false
				var direction = global_position.direction_to(mouse_pos)
				var new_a = ARROW.instantiate()
				if Gamemaneger.ex:
					new_a.ex = true
					Gamemaneger.ex -= 1
				speed = 20
				max_speed = 150
				new_a.strengh = charge
				charge = 0
				new_a.global_position = global_position
				get_parent().add_child(new_a)
				Gamemaneger.small_attack_n -= 1
		else:
			if Input.is_action_just_pressed("click") and not is_big_attacking:
				if reloadtimer.is_stopped():
					reloadtimer.start()
					reload.play()
					r_l.visible = true
		# 점프
		if Input.is_action_just_pressed(" ") and (is_on_floor() or double_jump):
			if double_jump and not is_on_floor():
				double_jump = false
				var particle = DOUBLE_JUMP.instantiate()
				particle.global_position = global_position
				get_parent().add_child(particle)
				
			velocity.y = JUMP_VELOCITY
		#더블점프 초기화
		if is_on_floor():
			double_jump = true
		#앞뒤 이동
		going = Vector2.ZERO
		if velocity.x >= 1 or velocity.x <= -1:
			velocity.x += -1 * sign(velocity.x) *10
		else:
			velocity.x = 0
		if Input.is_action_pressed("a"):
			going.x = 1
			face = 1
			   #300           300
			if max_speed * -1 > velocity.x:
				velocity.x = -1 * max_speed
				#300             -300
			if velocity.x > -1 * max_speed:
				velocity.x -= speed
		if Input.is_action_pressed("d"):
			going.y = 1
			face = 0
				  #300        -300
			if max_speed < velocity.x:
				velocity.x = max_speed
				#-300            #300
			if velocity.x < max_speed:
				velocity.x += speed
		#대쉬
		if Input.is_action_just_pressed("shift"):
			if can_dash and not is_dashing:
					
				
				
				max_speed = speed*30
				is_dashing = true
				if face == 0:
					velocity.x =  speed*25
				else:
					velocity.x =  speed*-25
				dash_timer.start()
				dash.play()
				can_dash = false
				velocity.y = 0
				var effect = DOUBLE_JUMP.instantiate()
				effect.what = "dash"
				if velocity.x < 0:
					
					effect.global_position = global_position
					effect.global_position += Vector2(5,0)
					effect.flip_h = true
				else:
					effect.global_position = global_position
					effect.global_position += Vector2(-5,0)
				get_parent().add_child(effect)
	if cant_move:
		velocity = Vector2.ZERO
	move_and_slide()

#내려가기 끝, 발판 다시 밟히게
func _on_drop_timer_timeout():
	set_collision_mask_value(6, true)

#기본공격 차징 취소
func cancel_charging():
	is_charging = false
	charge_s.stop()
	charge = 0
	progress_bar.value = 0
	line_2d_2.visible = false
	speed = 20
	max_speed = 150

#대쉬 쿨타임
func _on_timer_timeout():

	can_dash = true


#대쉬 타이머+대쉬동안 중력무시
func _on_dash_timer_timeout():
	is_dashing = false
	max_speed = 150
	timer.start()
	if velocity.x > 150:
		velocity.x = 150
	elif velocity.x < -150:
		velocity.x = -150 

#기본공격 재장전
func _on_reloadtimer_timeout():
	Gamemaneger.small_attack_n += Gamemaneger.can_small_attack_r
	Gamemaneger.small_attack_p -= Gamemaneger.can_small_attack_r
	r_l.visible = false
#강공격 재장전
func _on_big_arrow_t_timeout():
	can_big_attack = true
	Gamemaneger.big_attack_cool = 1.0
#데미지 입었을때
func hurt() -> bool:
	if not dead:
		if paring_t.is_stopped():
			get_parent().hurt()
			hit.play()
			return false
		else:
			pared = true
			parry_success()
			return true
	else:
		return false

#패링 성공
func parry_success():
	Engine.time_scale = PARRY_SLOW
	get_parent().cam_zoom(PARRY_ZOOM, PARRY_ZOOM, 0.15)
	get_parent().camera_2d.hurt(PARRY_SHAKE, 0.2)
	await get_tree().create_timer(PARRY_SLOW_TIME, true, false, true).timeout
	if not is_big_attacking:
		Engine.time_scale = 1.0
		get_parent().cam_zoom(2, 2, 0.25)
	var new_a = ARROW.instantiate()
	if Gamemaneger.ex:
		new_a.ex = true
		Gamemaneger.ex -= 1
	new_a.strengh = PARRY_ARROW_POWER
	new_a.global_position = global_position
	get_parent().add_child(new_a)
	shoot_s.play()
	bow.attack()
	bow_anime.play("attack")

#애니메이션 설정
func animation():
	if is_on_floor():
		animated_sprite_2d.flip_h = false
		if going.x or going.y:
		
			if not now_anime == 1 and bow.position.x == -6:
				animation_player.play("left_walk")
				now_anime = 1

			if not now_anime == 2 and bow.position.x == 6:
				animation_player.play("right_walk")
				now_anime = 2
		else:
			if bow.position.x == -6:
				if not now_anime == 3:
					animation_player.play("left_idle")
					now_anime = 3
			else:
				if not now_anime == 4:
					animation_player.play("right_idle")
					now_anime = 4
	else:
		if not now_anime == 5:
			animation_player.play("jump")

			now_anime = 5
		if bow.position.x == -6:
			animated_sprite_2d.flip_h = true
		else:
			animated_sprite_2d.flip_h = false
		

#강공격 재장전 
func _on_big_arrow_t_2_timeout():
	Gamemaneger.big_attack_n += Gamemaneger.can_big_attack_r
	Gamemaneger.big_attack_p -= Gamemaneger.can_big_attack_r

#등록된 스크롤 발동
func use_skill(i : int):
	var s = Gamemaneger.skill_setting[i]
	if not s:
		return
	elif not s.can_use or skill_cool[i] > 0:
		return
	skill_cool[i] = s.cool
	s.use()
	
func game_over():
	if dead:
		return
	dead = true
	Engine.time_scale = 1.0
	velocity = Vector2.ZERO
	Gamemaneger.ui.dead_ui.show()
	Gamemaneger.ui_open = true
func _on_paring_t_timeout():
	#패링 판정 끝 - 성공 표시 초기화
	pared = false
