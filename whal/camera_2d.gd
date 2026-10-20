extends Camera2D

@onready var character = $"../CharacterBody2D"

var target : Node2D
var off = Vector2.ZERO
func _process(delta):
	if Gamemaneger.cam_moving:
		var t = character
		if is_instance_valid(target):
			t = target
		global_position = global_position.lerp(t.global_position+off, 10 * delta)
#데미지 입었을때
func hurt(intensity = 3.0, duration = 0.15):
	var tween = create_tween()
	var steps = 6

	for i in range(steps):
		var random_offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)
		tween.tween_property(self, "offset", random_offset, duration / steps)

	tween.tween_property(self, "offset", Vector2.ZERO, duration / steps)
