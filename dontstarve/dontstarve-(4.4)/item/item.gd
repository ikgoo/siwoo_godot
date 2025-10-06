extends Resource
class_name Item
enum wears_op{
	nothing,
	body,
	head
}
enum what_tool{
	nothing,
	pickaxe,
	axe,
	weapon
}
@export var name : String
@export var img : Texture
@export var wear : wears_op
@export var eatable : bool
@export var negudo : bool
@export var wear_img : Texture
@export var count : int
@export var max_count : int
@export var can_hand : bool
@export var tool : what_tool
@export var damage : int = 0
