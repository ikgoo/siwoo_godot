extends Scroll
#소환할 연기

const SMOKE = preload("uid://cnobmx3o505kr")

#사용
func use():
	var c = Gamemaneger.character
	var s = SMOKE.instantiate()
	s.global_position = c.global_position
	c.get_parent().add_child(s)
