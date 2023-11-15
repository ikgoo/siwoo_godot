extends Panel
@onready var inventory = $"../../.."

var inventorywhere
var itemfollow = 0
@onready var backgroundsprite : Sprite2D = $background
var items
var intind
@onready var itemsprite : Sprite2D = $CenterContainer/Panel/item

func update(intind,item: inventory_item):
	self.intind = intind
	items = item
	if !item:
		backgroundsprite.frame = 0
		itemsprite.visible = false
	else:
		backgroundsprite.frame = 1
		itemsprite.visible = true
		itemsprite.texture = item.texture
		


func _on_button_button_down():
	inventory.SelectItem(intind, items)
#	itemfollow = 1


func _on_button_button_up():
#	itemfollow = 0
#	inventorywhere = inventory.where
	pass
