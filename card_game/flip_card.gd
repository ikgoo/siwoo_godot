extends Node2D
@onready var sprite_2d = $Sprite2D
@onready var animation_player = $AnimationPlayer


var m_in = false
var my_thing = null
# Called when the node enters the scene tree for the first time.
func _ready():
	var random = randi_range(0,3)
	my_thing = Gamemaneger.flip_cards[random]
	var thing = my_thing.instantiate()
	sprite_2d.add_child(thing)


func _input(event):
	if m_in:
		if event is InputEventMouseButton:
			if event.pressed:
				animation_player.play("flip")


func _on_area_2d_mouse_entered():
	m_in = true



func _on_area_2d_mouse_exited():
	m_in = false
