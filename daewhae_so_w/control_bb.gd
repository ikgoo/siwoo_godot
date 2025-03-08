extends Control

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		var click_position = event.position
		# 클릭된 위치에서 가장 위에 있는 Sprite2D를 찾습니다
		var sprite = get_sprite_at_position(click_position)
		if sprite:
			print("클릭된 스프라이트: ", sprite.name)

func get_sprite_at_position(pos):
	for child in get_children():
		if child is Sprite2D:
			# 스프라이트의 범위 내에 클릭이 있는지 확인
			var sprite_rect = child.get_rect()
			var local_pos = pos - child.position
			if sprite_rect.has_point(local_pos):
				return child
	return null
