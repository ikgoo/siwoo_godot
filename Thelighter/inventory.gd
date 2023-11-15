extends Node2D

signal itemSct(intind, sctItem)

var where = null
@onready var inventory : Inventory = preload("res://inventory.tres")
@onready var slots: Array = $NinePatchRect/GridContainer.get_children()
# Called when the node enters the scene tree for the first time.
func update():
	for i in range(min(inventory.item.size(), slots.size())):
		slots[i].update(i, inventory.item[i])

func _ready(): 
	update()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func AddItem(intInd : int, sctItem):
	if intInd >= 0:
		if !inventory.item[intInd]:
			inventory.item[intInd] = sctItem
		else:
			pass
		update()

func SelectItem(intind, sctItem):
	inventory.item[intind] = null
	update()
	emit_signal("itemSct", intind, sctItem)

