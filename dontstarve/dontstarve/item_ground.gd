@tool
extends Node3D
@onready var sprite = $Sprite3D
@onready var animation_player = $AnimationPlayer

@export var thing: Item = null:
	set(value):
		thing = value
		update_sprite()

# sprite 텍스처를 업데이트하는 함수
func update_sprite():
	if not sprite:
		return
		
	if thing:
		sprite.texture = thing.img
	else:
		sprite.texture = null

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play('drop')
	# _ready에서 sprite 재설정 (노드가 준비된 후)
	update_sprite()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func flying_item(start_pos: Vector3, target_pos: Vector3, flight_time: float = 1.5, arc_height: float = 3.0):
	
	# 시작 위치 설정
	global_position = start_pos
	
	# Tween 생성
	var tween = create_tween()
	tween.set_parallel(true)  
	
	tween.tween_property(self, "global_position:x", target_pos.x, flight_time)
	tween.tween_property(self, "global_position:z", target_pos.z, flight_time)
	
	var mid_height = max(start_pos.y, target_pos.y) + arc_height
	
	tween.tween_property(self, "global_position:y", mid_height, flight_time * 0.5)
	tween.tween_property(self, "global_position:y", target_pos.y, flight_time * 0.5).set_delay(flight_time * 0.5)
	
