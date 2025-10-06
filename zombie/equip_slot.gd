extends Panel

@onready var item_display = $CenterContainer/Panel/item_display
var item = null
var on = false

func update(slot:InvSlot):
	if  !slot:
		item_display.visible = false
	else:
		item_display.visible = true
		if slot.item:
			item_display.texture = slot.item.texture


func _on_area_2d_mouse_entered():
	on = true


func _on_area_2d_mouse_exited():
	on = false
