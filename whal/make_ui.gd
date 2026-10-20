extends Control
const ITEM_BUTTON = preload("uid://dfk82u4j2lhqa")
@onready var grid_container = $GridContainer
@onready var s_name = $name
@onready var rarity = $rarity
@onready var real_tmi = $real_tmi
@onready var tmi = $tmi
@onready var sprite_2d = $Sprite2D
@onready var price = $price

var now_thing

func open():
	visible = true
	Gamemaneger.push_ui(self)

func close():
	visible = false
	Gamemaneger.pop_ui(self)

func _ready():
	for rarity in ["mistic","epic","rare","normal"]:
		for i in Gamemaneger.all_scrolls[rarity]:
			var b = ITEM_BUTTON.instantiate()
			b.thing = i
			grid_container.add_child(b)
			b.spawn()
 			

func update():
	s_name.text = now_thing.name
	rarity.text = now_thing.rarity
	real_tmi.text = now_thing.real_tmi
	sprite_2d.texture = now_thing.texture
	price.text = str(Gamemaneger.item_ver_piece[now_thing.rarity]*3)
	var c
	if now_thing.rarity == "normal":
		c = Color("#D9D9D9")
	elif now_thing.rarity == "rare":
		c = Color("#66A6FF")
	elif now_thing.rarity == "epic":
		c = Color("#BF73FF")
	else:
		c = Color("#FFA633")
	s_name.label_settings.font_color = c
	rarity.label_settings.font_color = c

func _on_make_button_down():
	if Gamemaneger.item_ver_piece[now_thing.rarity]*3 <= Gamemaneger.piece:
		Gamemaneger.r_get = now_thing
		Gamemaneger.piece -= Gamemaneger.item_ver_piece[now_thing.rarity]*3
		get_parent().get_parent().get_parent().roll.get_random_scroll()
		close()
	
