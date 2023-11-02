extends PointLight2D

var time = 0
var time_up = 0.5
const COLOR = Color("#ff5c4b")
const COLOR2 = Color("#e40000b7")
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta:float) -> void:
	time += time_up * delta
	if time >= 1  or time <= -1:
		if time_up == 0.5:
			time_up = -0.5
		else:
			time_up = 0.5
	self.color = lerp(COLOR2, COLOR, time)
