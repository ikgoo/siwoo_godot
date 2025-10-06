extends Resource
class_name entity

# entity_drop 클래스 참조를 위한 preload
const EntityDrop = preload("res://entity/entity_drop.gd")
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
@export var drop_item : Array[Item]  # 기존 호환성을 위해 유지
@export var drops : Array[EntityDrop]  # 새로운 확률적 드롭 시스템
@export var attack_type : attack_typee
@export var size : int
@export var frames : int
@export var y_frames : int
@export var e_speed : float
@export var my_animation_attack : String
@export var my_animation_walk : String
@export var attack_speed : float
