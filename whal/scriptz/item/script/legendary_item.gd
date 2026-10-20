extends Scroll
#사용
func use():
	super()
	Gamemaneger.damage += 0.00001
	Gamemaneger.hp += 1
	if Gamemaneger.character.is_on_floor():
		Gamemaneger.character.speed = Gamemaneger.character.speed / 10
	else:
		Gamemaneger.character.speed = Gamemaneger.character.speed * 10
