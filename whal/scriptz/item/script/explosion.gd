extends Scroll

func use():
	super()
	Gamemaneger.bleed += 1

func unuse():
	super()
	Gamemaneger.bleed -= 1
