extends GPUParticles2D
#연기 안에 들어온 몹들
var inside = []

func _ready():
	emitting = true

func _process(delta):
	#파티클 다 끝나면 눈 돌려주고 삭제
	if not emitting:
		for m in inside:
			if is_instance_valid(m):
				m.blind = false
		inside.clear()
		queue_free()

#연기 안에 들어옴
func _on_area_2d_body_entered(body):
	if not "blind" in body:
		return
	inside.append(body)
	body.blind = true

#연기 밖으로 나감
func _on_area_2d_body_exited(body):
	if not "blind" in body:
		return
	inside.erase(body)
	body.blind = false
