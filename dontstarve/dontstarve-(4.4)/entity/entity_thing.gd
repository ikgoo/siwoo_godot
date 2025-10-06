extends Resource
class_name entity
enum attack_typee {
	first_attack,
	last_attack
	
	
}
@export var hp : int
@export var entity_name : String
@export var sulmung : String
@export var attack_dam : int
@export var speed : int
@export var attack_delay : int
@export var img : Texture
@export var drop_item : Array[Item]
@export var attack_type : attack_typee
@export var size : int
@export var frames : int
@export var y_frames : int
