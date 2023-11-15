extends Node3D

const SPEED = 100.0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position += transform.basis * Vector3(0,0,-SPEED) * delta



func _on_bullets_coll_area_entered(area):
	queue_free()
	area.get_parent().queue_free()
	area.get_parent().anipl.play("Armature|Death")

