extends Node

#소리
signal sound_made(pos)
signal shop_open(items)

#버튼 클릭 소리
const CLICK_SOUND = preload("res://sound/sfx/click.ogg")
var click_player : AudioStreamPlayer
var air_dam = 0
func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	click_player = AudioStreamPlayer.new()
	click_player.stream = CLICK_SOUND
	click_player.bus = "UI"
	click_player.pitch_scale = 1.2
	click_player.max_polyphony = 3
	click_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(click_player)

#아무 버튼이나 클릭하면 소리
func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var thing = get_viewport().gui_get_hovered_control()
		if thing is BaseButton and not thing.disabled:
			click_player.play()

func make_sound(pos):
	sound_made.emit(pos)

#아이템 얻었을때
signal scroll_gained(s)
var item_ver_piece = {"normal":10,"rare":30,"epic":60,"mistic":120}
#아이템 얻기
func get_scroll(s : Scroll,thing=null):
	if not len(my_scrolls) >= 9:
		my_scrolls.append(s)
		scroll_gained.emit(s)
		if thing:
			thing.queue_free()
		#패시브면 얻는 즉시 발동, 액티브는 나중에 직접 씀
		if not s.can_use:
			s.use()
	else:
		ui.change(s,thing)

func lose_scroll(s : Scroll):
	if not s in my_scrolls:
		return
	my_scrolls.erase(s)
	if not s.can_use:
		s.unuse()
var bleed = 0

var ui_stack = []

func push_ui(ui):
	self.ui.open.play()
	if ui in ui_stack: return
	ui_stack.append(ui)
	ui_open = true

func pop_ui(ui):
	self.ui.close.play()
	ui_stack.erase(ui)
	ui_open = not ui_stack.is_empty()

func close_top() -> bool:
	if ui_stack.is_empty(): 
		return false
	ui_stack[-1].close()
	return true
	
func _process(delta):
	mini_on()
func break_scroll(s : Scroll):
	if not s in my_scrolls:
		return
	my_scrolls.erase(s)

	piece += item_ver_piece[s.rarity]

	if not s.can_use:
		s.unuse()
var r_get = null
func random_scroll():
	if r_get:
		return r_get
	var ran_int = randf() * 100
	
	if ran_int < 3:
		return all_scrolls["mistic"].pick_random()
	elif ran_int < 15:
		return all_scrolls["epic"].pick_random()
	elif ran_int < 40:
		return all_scrolls["rare"].pick_random()
	else:
		return all_scrolls["normal"].pick_random()
var talking = false
var ui_open = false
var stage = 1
var ui
var interface
var money = 0
var changing_map = false
var cam_moving = true
var upgrade = [0,0,0,0,0,0,0,0,0,0,0]
var plusdamage = 0
var protect = 0
var skill_setting = [null,null,null,null,null,null,null,null,null]
var tu = false
#다음 맵으로
const LINJA = preload("uid://domwx5wy3pbr2")
func linja():
	var linja = LINJA.instantiate()
	linja.global_position = Gamemaneger.character.global_position
	character.get_parent().add_child(linja)
	
	

func go_to_map(path : String):
	if changing_map or path == "":
		return
	changing_map = true
	get_tree().paused = false
	Engine.time_scale = 1
	talking = false
	ui_open = false
	stage += 1
	
	Gamemaneger.hp += Gamemaneger.plus_hp_round
	Gamemaneger.plus_hp += Gamemaneger.plus_hp_round
	if ui:
		ui.fade_black()
		await ui.animation_player.animation_finished
	get_tree().change_scene_to_file(path)
	ui.refresh()
	ui_stack = []
	changing_map = false
var  in_money = 0
var map_stack = 0
#사망 후 재시작
func restart_map(path : String):
	if changing_map or path == "":
		return
	changing_map = true

	get_tree().paused = false
	Engine.time_scale = 1
	talking = false
	ui_open = false
	hp = max_hp
	if ui:
		ui.fade_black()
		await ui.animation_player.animation_finished
	get_tree().change_scene_to_file(path)
	changing_map = false	
var character : CharacterBody2D
var camera
var phase_thing = ["normal","speed","damage","nuckback"]
var phase_stat = [[1.0,20],[0.4,10],[2,40],[1,25]]
var hp = 100
var max_hp = 100
var respawn = 0

#플레이어가 무적인가
func is_invincible() -> bool:
	return character != null and character.is_dashing


func hurt(dam : int) -> bool:
	if character == null:
		return false
	#대쉬중이면 무적
	if is_invincible():
		return false
	if character.hurt():
		return false
	hp -= dam * ((100-protect) / 100.0)
	
	return true
func gaksung_b(sec, amount):
	plusdamage += amount
	await get_tree().create_timer(sec).timeout
	plusdamage -= amount
#ESC 메뉴를 열어도 되는 상황인가
func can_pause() -> bool:
	if changing_map:
		return false
	if character and character.dead:
		return false
	return true
var crit = 0
var tilemap
var all_scrolls = {
	normal=[preload("uid://c4mx8nq3wprt2"),preload("uid://dnw5t8k1yvbq6"),preload("uid://b1qvr7k2xdn40"),preload("uid://buttkvmfcgtvk")],
	rare=[preload("uid://ba3jf6mp8xua1"),preload("uid://3npxgafptol1"),preload("uid://bph3jlulhwp3y"),preload("uid://dxf6jawc1xvkq"),preload("uid://beaax2u1dkrqw"),preload("uid://fyr6d060a58n"),preload("res://scriptz/item/rare/gust.tres")],
	epic=[preload("uid://c7yhk2vd0nls8"),preload("uid://bnvxn2m0m6ana"),preload("res://scriptz/item/epic/fall.tres")],
	mistic=[preload("uid://c80qoquyvodai")]
	}
var my_scrolls : Array[Scroll] = []
var all_maps = ["res://map.tscn","res://map2.tscn","res://map3.tscn","res://map4.tscn"]
var though_arrow = 0
var used_maps = []
var gaksung = 0
func random_map() -> String:
	#아직 안나온 것중에서만 뽑기
	var pool = all_maps.filter(func(m): return not m in used_maps)
	if pool.is_empty():
		used_maps.clear()
		pool = all_maps
	var m = pool.pick_random()
	used_maps.append(m)
	return m
var damage = 10
var money_per = 0
var speed = 0
var boss_dam = 0
var r_click_speed
#아이템으로 올라간 데미지
var damage_add = 0
#기본공격 화살 개수
var small_attack_p = 100
var small_attack_n = 10
#강공격 화살 개수	
var big_attack_p = 50
var big_attack_n = 5
#한번에 최대 재장전 가능 수
var can_small_attack_r = 10
var can_big_attack_r = 5
var big_attack_cool = 1.0
var piece = 0
var phase = 0
var ex = 0
var plus_hp = 0
var plus_hp_round = 0
var mobs = []
var gust = 0


func launch(pos : Vector2):
	for m in mobs:
		if is_instance_valid(m) and not m.is_dead and m.global_position.distance_to(pos) < 70:
			m.velocity.y = -350

func getting_hurt(mob,boss:bool,head:bool,damage_much:int):
	var dam : float = damage_much * (1.0 + plusdamage / 100.0 + damage_add / 100.0)
	if head:
		dam *= 1.2 + crit / 100.0
	if boss:
		dam *= 1.0 + boss_dam / 100.0
	if not mob.is_on_floor():
		dam *= 1.0 + air_dam / 100.0
	mob.hp -= dam
	if bleed:
		if hp + dam * (bleed/100.0) <= max_hp:
			hp += dam * (bleed/100.0)
		else:
			hp = max_hp

var m_tile

func mini_on():
	if not is_instance_valid(m_tile) or not is_instance_valid(tilemap) or not is_instance_valid(character):
		return
	m_tile.clear()
	var ch_t_pos: Vector2i = tilemap.local_to_map(tilemap.to_local(character.global_position))
	for i in mobs:
		if is_instance_valid(i) and not i.is_dead:
			var m_t_pos: Vector2i = tilemap.local_to_map(tilemap.to_local(i.global_position))
			m_tile.set_cell(m_t_pos - ch_t_pos + Vector2i(35, 35), 0, Vector2i(0, 0))
