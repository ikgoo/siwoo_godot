extends Resource

class_name obsticle
enum mineable{
	nothing,
	tree,
	stone
}

@export var name : String
@export var img : Texture2D
@export var sulmung : String
@export var moving : bool
@export var type : mineable
@export var times_mine : int
@export var things : Array[obsticle_get]
@export var offset : float
