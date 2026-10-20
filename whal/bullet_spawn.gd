extends AnimatedSprite2D
#보스 탄막 소환진 - 잠깐 떴다가 탄 하나 뱉고 사라짐
const BULLET = preload("res://bullet.tscn")

@onready var animation_player = $AnimationPlayer

var dir : Vector2 = Vector2.RIGHT

func _ready():
	animation_player.play("idle")

#소환진 다 차면 발사
func _on_timer_timeout():
	var b = BULLET.instantiate()
	get_parent().add_child(b)
	b.global_position = global_position
	b.dir = dir
	queue_free()
