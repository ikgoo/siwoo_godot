@tool
extends Node3D
@onready var sprite = $Sprite3D
@onready var animation_player = $AnimationPlayer

@export var thing: Item = null:
	set(value):
		print("item_ground thing setter 호출: ", value)
		thing = value
		update_sprite()

# sprite 텍스처를 업데이트하는 함수
func update_sprite():
	if not sprite:
		print("sprite가 아직 준비되지 않음, _ready에서 다시 시도")
		return
		
	if thing:
		sprite.texture = thing.img
		print("sprite 텍스처 설정 완료: ", thing.name)
	else:
		sprite.texture = null
		print("sprite 텍스처 제거")

# Called when the node enters the scene tree for the first time.
func _ready():
	animation_player.play('drop')
	# _ready에서 sprite 재설정 (노드가 준비된 후)
	update_sprite()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
