extends Scroll

func use():
	super()
	Gamemaneger.though_arrow += 1

func unuse():
	super()
	Gamemaneger.though_arrow -= 1
