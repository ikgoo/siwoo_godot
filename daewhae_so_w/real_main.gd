extends Node2D
@onready var animation_player = $AnimationPlayer

func _ready():
	animation_player.play("new_animation")
	Main.visible = true  # 글로벌 Main을 보이게 함
	Main.control.visible = true
	Main.go = true
	Main.camera.enabled = true
	# 게임 시작 시 튜토리얼 표시
	Main.control.show_tutorial()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
