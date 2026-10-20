extends CharacterBody2D
@onready var animation_player = $AnimationPlayer

var dir : Vector2 = Vector2.RIGHT
var speed : float = 240
var damage : int = 7
var dead = false
var looked = false
func _ready():
	
	animation_player.play("idle")
	look_at(Gamemaneger.character.global_position)
func _physics_process(delta):
	if not looked:
		look_at(Gamemaneger.character.global_position)
		looked = true
	if not dead:
		velocity = transform.x * speed
		move_and_slide()

#벽에 박음
func _on_area_2d_body_entered(body):
	queue_free()

#플레이어한테 맞음
func _on_area_2d_2_area_entered(area):
	if not dead:
		#대쉬중이면 무적 - 총알이 그냥 통과함
		if Gamemaneger.is_invincible():
			return
		Gamemaneger.hurt(damage)
		animation_player.play("explode")
		dead = true
