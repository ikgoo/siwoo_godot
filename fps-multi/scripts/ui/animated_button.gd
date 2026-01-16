extends Button

## 애니메이션 버튼
## 호버 시 크기 변화 효과

var original_scale = Vector2.ONE
var hover_scale = Vector2(1.05, 1.05)

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	pivot_offset = size / 2

func _on_mouse_entered():
	var tween = create_tween()
	tween.tween_property(self, "scale", hover_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(self, "scale", original_scale, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_pressed():
	# 클릭 효과
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
	tween.tween_property(self, "scale", hover_scale, 0.05)
