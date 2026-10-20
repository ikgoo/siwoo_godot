extends Area2D

var gone = false
var shop = "res://shop.tscn"
var main = "res://main_game.tscn"
var boss = "res://boss.tscn"
func _on_area_entered(area):
	if not gone:
		gone = true
		print(Gamemaneger.map_stack)
		Gamemaneger.cam_moving = false
		if Gamemaneger.map_stack == 2:
			Gamemaneger.go_to_map(shop)
			Gamemaneger.map_stack = 6
		elif Gamemaneger.map_stack == 6:
			Gamemaneger.go_to_map(boss)
			Gamemaneger.map_stack = 0
		else:
			Gamemaneger.go_to_map(main)
			Gamemaneger.map_stack += 1

func _on_timer_timeout():
	pass # Replace with function body.
