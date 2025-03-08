extends Control
@onready var enery_bar = $Panel/enery_bar
@onready var health_bar = $Panel/health_bar
@onready var food_bar = $Panel/food_bar


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	enery_bar.value = Charater.current_stamina
