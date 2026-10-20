extends Control

var a = 1



func _on_button_pressed():
	Gamemaneger.restart_map("res://home.tscn")
	clear()
func _on_button_2_pressed():
	Gamemaneger.restart_map("res://start_ui.tscn")
	clear()
	
func clear():
	Gamemaneger.ui_open = false
	Gamemaneger.in_money = 0
	Gamemaneger.my_scrolls = []
	Gamemaneger.cam_moving = false
	Gamemaneger.skill_setting = [null,null,null,null,null,null,null,null,null]
	Gamemaneger.small_attack_n = 10
	Gamemaneger.small_attack_p = 100
	Gamemaneger.big_attack_p = 50
	Gamemaneger.big_attack_n = 5
	Gamemaneger.big_attack_cool = 1.0
	Gamemaneger.ex = 0
	Gamemaneger.plusdamage = 0
	Gamemaneger.stage = 1
	Gamemaneger.plus_hp = 0
	Gamemaneger.used_maps = []
	Gamemaneger.mobs = []
	Gamemaneger.ui_stack = []
	Gamemaneger.map_stack = 0
	Gamemaneger.tu = false
