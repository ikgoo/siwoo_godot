extends Node2D
var mob1
var mob2
var mob3
var f_dead = false
var s_dead = false
var l_dead = false
const CHARARTER = preload("res://tscn/chararter.tscn")
const GOLEMIC = preload("res://tres/golemic.tres")
# Called when the node enters the scene tree for the first time.
func _ready():
	mob1 = CHARARTER.instantiate()
	mob2 = CHARARTER.instantiate()
	mob3 = CHARARTER.instantiate()
	mob1.entity = GOLEMIC
	mob2.entity = GOLEMIC
	mob3.entity = GOLEMIC
	add_child(mob1)
	add_child(mob2)
	add_child(mob3)
	mob1.position.x = -150
	mob3.position.x = 150
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if f_dead and s_dead and l_dead:
		queue_free()
