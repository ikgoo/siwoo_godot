extends Parallax2D

## 카메라의 Y 좌표를 직접 따라가는 패럴렉스 배경
## scroll_scale은 X축 패럴렉스만 처리하고, Y축은 코드로 카메라에 고정

# _physics_process로 카메라와 동일한 타이밍에 업데이트 (지연 없음)
func _physics_process(_delta):
	var camera = get_viewport().get_camera_2d()
	if camera:
		global_position.y = camera.global_position.y




