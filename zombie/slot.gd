extends Panel

@onready var item_display = $CenterContainer/Panel/item_display



func update(slot:InvSlot):
	if  !slot:
		item_display.visible = false
	else:
		item_display.visible = true
		if slot.item:
			item_display.texture = slot.item.texture
