extends CharacterBody2D
#얘들
@onready var timer = $Timer
@onready var sprite_2d = $Sprite2D
@onready var line_2d = $Line2D
#변수
var damage : int
var flying = true
var dir : Vector2
var strengh : int

func _ready():
	look_at(dir)
	if strengh < 20:
		strengh = 30
	



func _physics_process(delta):
	if flying:
		line_2d.line()
		velocity = transform.x * strengh * 7
		velocity.y += 850 * delta
		
		move_and_slide()

	else:
		line_2d.deleting()


func _on_area_2d_body_entered(body):
	timer.start()
	flying = false


func _on_timer_timeout():
	queue_free()


func _on_area_2d_2_area_entered(area):
	if timer.is_stopped():
		#대쉬중이면 무적 - 화살이 그냥 통과함
		if not Gamemaneger.is_invincible():
			Gamemaneger.hurt(damage)
			timer.start()
			flying = false
		
