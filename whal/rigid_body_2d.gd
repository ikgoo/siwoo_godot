extends CharacterBody2D
#얘들
@onready var sprite_2d = $Sprite2D
@onready var line_2d = $Line2D
#변수
var dir : Vector2
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	sprite_2d.look_at(dir)
	velocity = transform.x * 10
	
