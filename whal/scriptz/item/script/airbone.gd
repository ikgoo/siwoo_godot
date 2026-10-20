extends Scroll

func use():
	super()
	Gamemaneger.air_dam += 20

func unuse():
	super()
	Gamemaneger.air_dam -= 20
