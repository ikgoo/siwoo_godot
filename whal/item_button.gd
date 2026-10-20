extends NinePatchRect
@onready var sprite_2d = $Sprite2D
var thing : Scroll
func _ready():
	pass


func _process(delta):
	pass


func spawn():
	sprite_2d.texture = thing.texture
	if thing.rarity == "normal":
		self_modulate = "#D9D9D9"
	elif  thing.rarity == 'rare':
		self_modulate = '#66A6FF'
	elif thing.rarity == "epic":
		self_modulate = "#BF73FF"
	else:
		self_modulate = "#FFA633"


func _on_button_button_down():
	get_parent().get_parent().now_thing = thing
	get_parent().get_parent().update()
