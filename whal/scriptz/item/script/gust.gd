extends Scroll

func use():
	super()
	Gamemaneger.gust += 1

func unuse():
	super()
	Gamemaneger.gust -= 1
