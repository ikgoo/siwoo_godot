extends Scroll
#사용: 화면에 보이는 공중에 뜬 적 내리꽂기
func use():
	for m in Gamemaneger.mobs:
		if is_instance_valid(m) and not m.is_dead and not m.is_on_floor():
			m.slam()
