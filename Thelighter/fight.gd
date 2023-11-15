extends Node2D
var mouse_on_the_sprite = false
@onready var sprite_2d = $Sprite2D
var sctItem = null
var intind
var now_area = null
@onready var inventory = $inventory
@export var light1 : Sprite2D
@export var light2 : Sprite2D
@export var battry : Sprite2D
@export var lens : Sprite2D
@onready var light_attack_2 : light_attack = $"light attack2"


var ss
var light_attack_review;

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

var tter = PhysicsPointQueryParameters2D.new()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var mousePos = get_global_mouse_position()

	var space = get_world_2d().direct_space_state
	#sctItem.global_position = get_global_mouse_position()
	var collision_mask = light_attack_2.area_2d_light1.collision_layer # 충돌 레이어 1만 검사
	tter.position = mousePos
	tter.collide_with_areas = true
	tter.collision_mask = collision_mask
	ss = space.intersect_point(tter)
	var tmp = ""
	if sctItem:
		if len(ss) != 0:
			print(ss[0].collider.name)
			if ss[0].collider.name == "Area2D":
				
				tmp = "light1"
			if ss[0].collider.name == "Area2D2":
				tmp = "light2"
			if ss[0].collider.name == "Area2D3":
				tmp = "battry"
			if ss[0].collider.name == "light24":
				tmp = "lens"
		elif len(ss) == 0:
			light_attack_2.unpreview("light1")
			light_attack_2.unpreview("light2")
			light_attack_2.unpreview("lens")
			light_attack_2.unpreview("battry")
		now_area = tmp
		
		light_attack_2.preview(now_area, sctItem)
		sprite_2d.global_position = get_global_mouse_position()
	if not sctItem:
		if len(ss) != 0:
			print(ss[0].collider.name)
			if ss[0].collider.name == "Area2D":
				if light1.texture != null:
					pass
			if ss[0].collider.name == "Area2D2":
				tmp = "light2"
			if ss[0].collider.name == "Area2D3":
				tmp = "battry"
			if ss[0].collider.name == "light24":
				tmp = "lens"
#		light_attack_review = light_attack_2.get_area2d_at_mouse_pos()
#
#		mouse_on_the_sprite = true                    
#		if now_area == "light1":
#			if sctItem.what == "light":
#				pass
	


func _on_inventory_item_sct(intind, sctItem):
	if sctItem:
		sprite_2d.texture = sctItem.texture
		self.intind = intind
		self.sctItem = sctItem
	
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and now_area != null and sctItem != null:
		if(!light_attack_2.addItem(now_area, intind, sctItem)):
			sprite_2d.texture = null
			inventory.AddItem(intind,sctItem)
			self.intind = -1
		self.sctItem = null
		sprite_2d.texture = null
#		mouse_on_the_sprite = false
		now_area = null

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and !event.pressed and now_area == null and sctItem != null:
		sprite_2d.texture = null
		inventory.AddItem(intind,sctItem)
		self.intind = -1
		self.sctItem = null
		
	




func _on_light_attack_2_uneqeup(index, item):
	inventory.AddItem(index, item)
