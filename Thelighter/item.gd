extends Sprite2D
@onready var slot = $"../../.."


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update(slot.items)
		
func update(item : inventory_item):
	
	if slot.itemfollow == 1:
		global_position = get_global_mouse_position()
		if item.what == "light":
			print(slot.inventorywhere)
			if slot.inventorywhere == "light1":
				global_position.x = 195
				global_position.y = 46
			global_scale.x = 2.1
			global_scale.y = 2
		elif item.what == "lens":
			global_scale.x = 3
			global_scale.y = 3
	if slot.itemfollow == 0:
		position.x = 0
		position.y = 0
		global_scale.x = 1
		global_scale.y = 1
