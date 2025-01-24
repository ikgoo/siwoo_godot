@tool
extends Node2D

var energy = 0

var speed = 0

var faith = 0


@onready var main_image: Sprite2D = $main_image

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
	pass
