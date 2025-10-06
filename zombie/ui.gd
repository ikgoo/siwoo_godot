extends Control
@onready var enery_bar = $Panel/enery_bar
@onready var health_bar = $Panel/health_bar
@onready var food_bar = $Panel/food_bar


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	enery_bar.value = Charater.current_stamina
	food_bar.value = Charater.current_hunger
