extends CharacterBody2D
@onready var animation_player = $AnimationPlayer

func _on_area_2d_area_entered(area):
	animation_player.play("earn")
	Gamemaneger.money += 5 + (5   * (Gamemaneger.money_per/100.0))

func _process(delta):
	if velocity.x > 0:
		velocity.x -= 1
	elif velocity.x < 0:
		velocity.x += 1
	if not is_on_floor():
		velocity += get_gravity() * delta
	move_and_slide()

func _on_timer_timeout():
	animation_player.play("earn")
	Gamemaneger.money += 20 + (20  * (Gamemaneger.money_per/100.0))
