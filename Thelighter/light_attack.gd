extends Node2D

class_name light_attack

@onready var area_2d_light1 = $Area2D
@onready var area_2d_battry = $Area2D4
@onready var area_2d_lens = $Area2D3
@onready var area_2d_light2 = $Area2D2




@onready var sprite_2d = $Sprite2D
var item1 : inventory_item = null
var item1_slot_idx = -1
@onready var sprite_2d_4 = $Sprite2D4
var item2 : inventory_item = null
var item2_slot_idx = -1
@onready var sprite_2d_5 = $Sprite2D5
var item3 : inventory_item = null
var item3_slot_idx = -1
@onready var sprite_2d_3 = $Sprite2D3
var item4 : inventory_item = null
var item4_slot_idx = -1

signal uneqeup(index : float, item : inventory_item)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func addItem(type, slot_idx, item : inventory_item) -> bool:
	if type.contains(item.what):
		if type == "light1":
			if item1:
				emit_signal("uneqeup", item1_slot_idx, item1)
			item1 = item
			item1_slot_idx = slot_idx
		if type == "light2":
			if item2:
				emit_signal("uneqeup", item2_slot_idx, item2)
			item2 = item
			item2_slot_idx = slot_idx
		if type == "lens":
			if item3:
				emit_signal("uneqeup", item3_slot_idx, item3)
			item3 = item
			item3_slot_idx = slot_idx
		if type == "battry":
			if item4:
				emit_signal("uneqeup", item4_slot_idx, item4)
			item4 = item
			item4_slot_idx = slot_idx
		return true
	else:
		return false
	

func preview(type, item : inventory_item):
	if type == "light1":
		sprite_2d.texture = item.texture
		unpreview("light2")
		unpreview("lens")
		unpreview("battry")
	if type == "light2":
		sprite_2d_4.texture = item.texture
		unpreview("light1")
		unpreview("lens")
		unpreview("battry")
	if item.what == "lens":
		sprite_2d_5.texture = item.texture
		unpreview("light1")
		unpreview("light2")
		unpreview("battry")
	if item.what == "battry":
		sprite_2d_3.texture = item.texture
		unpreview("light1")
		unpreview("light2")
		unpreview("lens")
	
	
	


func unpreview(type):
	if type == "light1":
		if item1 != null:
			sprite_2d.texture = item1.texture
		else:
			sprite_2d.texture = null
	if type == "light2":
		if item2 != null:
			sprite_2d_4.texture = item2.texture
		else:
			sprite_2d_4.texture = null
	if type == "lens":
		if item3 != null:
			sprite_2d_5.texture = item3.texture
		else:
			sprite_2d_5.texture = null
	if type == "battry":
		if item4 != null:
			sprite_2d_3.texture = item4.texture
		else:
			sprite_2d_3.texture = null

func get_area2d_at_mouse_pos():
	var mouse_pos = get_viewport().get_mouse_position()
	if area_2d_light1.get_rect().has_point(area_2d_light1.to_local(mouse_pos)):
		print("겹침_light1")
		return "light1";
	elif  area_2d_battry.get_rect().has_point(area_2d_battry.to_local(mouse_pos)):
		print("겹침_battry")
		return "battry";
	elif  area_2d_lens.get_rect().has_point(area_2d_lens.to_local(mouse_pos)):
		print("겹침_lens")
		return "lens";
	elif  area_2d_light2.get_rect().has_point(area_2d_light2.to_local(mouse_pos)):
		print("겹침_light2")
		return "light2";

#
#    var area2d_list = []
#    for area2d in area2d_array:
#        if area2d.get_rect().has_point(area2d.to_local(mouse_pos)):
#            area2d_list.append(area2d)
#    return area2d_list
