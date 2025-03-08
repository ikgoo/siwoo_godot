extends Control


@onready var inv : Inv = preload("res://items/player_inv.tres")

@onready var slots : Array = $NinePatchRect/GridContainer.get_children()

var is_open = false

func _ready():
	inv.update.connect(update_slots)
	close()
	
func _process(delta):
	update_slots()
	if Input.is_action_just_pressed("tab"):
		if is_open:
			close()
		else:
			open()
	
func open():
	visible = true
	is_open = true
	
func close():
	visible = false
	is_open = false


func update_slots():
	
	for i in range(min(inv.slots.size(),slots.size())):
		slots[i].update(inv.slots[i])
