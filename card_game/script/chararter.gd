@tool
extends Node2D

var energy = 0

var speed = 0

var faith = 0

var pressed = false

var  m_in = false
@onready var main_image: Sprite2D = $main_image
@onready var line_2d = $Line2D

@export var entity : Entity :
	set(value):
		entity = value
		
		energy = entity.energy
		speed = entity.speed
		faith = entity.sinangsim
var image
var card_background
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	image = entity.image.instantiate()
	card_background = entity.back_card.instantiate()
	add_child(card_background)
	add_child(image)
	image.position.y += -6
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if pressed:
		line_2d.points[1] = get_local_mouse_position()
	if Gamemaneger.m_in:
				pressed = false
				line_2d.points[1] = Vector2(0,0)
func _input(event):
	if m_in:
		if event is InputEventMouseButton:
			if event.pressed:
				pressed = true
				card_background.animation.play("up")
			if event.is_released():
				card_background.animation.play("down")
				pressed = false



func _on_area_2d_mouse_entered():
	m_in = true
	


func _on_area_2d_mouse_exited():
	m_in = false
