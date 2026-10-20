extends Node2D
@onready var f = $f
@onready var hp_1 = $hp_1
@onready var d_1 = $d_1
@onready var d_2 = $d_2
@onready var d_3 = $d_3
@onready var d_s = $d_s
@onready var d_4 = $d_4
@onready var hp_4 = $hp_4
@onready var hp_3 = $hp_3
@onready var hp_s = $hp_s
@onready var hp_2 = $hp_2
@onready var upgrade_ui = $CanvasLayer/upgrade_ui
@onready var price_2 = $CanvasLayer/price2
@onready var current_m = $CanvasLayer/current_m
const NEED = [-1, 0, 1, 2, 2, 3, 0, 6, 7, 7, 8]

var things
var first = [0]
func _ready():
	things = [f,hp_1,hp_2,hp_3,hp_s,hp_4,d_1,d_2,d_3,d_s,d_4]
	refresh()

 


func refresh():
	for i in things.size():
		var need = NEED[i]
		things[i].visible = need < 0 or Gamemaneger.upgrade[need] > 0
		var done = Gamemaneger.upgrade[i] > 0
		for s in things[i].find_children("upgraded*", "", true, false):
			s.visible = done
		for s in things[i].find_children("unupgraded*", "", true, false):
			s.visible = not done


func _on_f_pressedl(num):
	upgrade_ui.on(num)
