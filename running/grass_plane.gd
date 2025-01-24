extends Node3D
@onready var jet = $"../Jet"

@onready var _1 = $"1"
@onready var _2 = $"2"
@onready var _3 = $"3"
@onready var _4 = $"4"
@onready var _5 = $"5"
@onready var _6 = $"6"
@onready var _7 = $"7"
@onready var _8 = $"8"

var grasses
# Called when the node enters the scene tree for the first time.
func _ready():
	grasses = [_1,_2,_3,_4,_5,_6,_7,_8]
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for grass in grasses:
		if grass.global_position.z - jet.global_position.z > 15:
			grass.position.z += -120
