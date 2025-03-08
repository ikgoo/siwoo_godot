extends Label

@onready var animation_player = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func fire():
	text = "산불이 일어났습니다!"
	label_settings.font_color = Color(1.0, 1.0, 0.0)


func fire_end():
	text = "산불이 사라졌습니다."
	label_settings.font_color = Color(0,0,255)
	

func text_thing(txt : String):
	animation_player.stop()
	animation_player.play("pop_up")
	text = txt
	label_settings.font_color = Color(0,0,255)
	
	
