extends Node

var jumsu = 0

var here = "space"
var high_score = 0
var speed = 0.4
var end = false
var went = 1
var go_speed = 8
func high_score_get():
	if jumsu > high_score:
		high_score = jumsu
	var config = ConfigFile.new()
	config.set_value("Game", "high_score", high_score)
	config.save("user://high_score.cfg")
	end = true
func _ready():
	load_score()

func load_score():
	var config = ConfigFile.new()
	var error = config.load("user://high_score.cfg")
	if error == OK:
		high_score = config.get_value("Game", "high_score", 0)
		
