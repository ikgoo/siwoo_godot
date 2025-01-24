extends Node2D

@onready var terrain_l = $terrain
@onready var water_l = $water
@onready var tempe_l = $tempe
@onready var oxyen = $oxyen

var water
var tempe
var terrain
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func thing_get(t : String,w : int,te : int,oxyen_l : int):
	terrain = t
	tempe = te
	water = w
	terrain_l.text = str(terrain)
	tempe_l.text = "온도 : " + str(tempe)
	water_l.text = "수분 : " + str(water)
	oxyen.text = "산소 : " + str(oxyen_l)
	global_position = get_global_mouse_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta : float):
	#terrain_l.text = str(terrain)
	#tempe_l.text = str(tempe)
	#water_l.text = str(water)
