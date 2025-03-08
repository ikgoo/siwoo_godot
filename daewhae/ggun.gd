extends Node2D

const BLUE_G = preload("res://blue_g.png")
const RED_G = preload("res://red_g (18).png")
@onready var animated_sprite_2d = $sprite
@onready var animation_player = $AnimationPlayer
var color = "red"
var is_dragging = false
var drag_offset = Vector2()
var current_tween
var is_oxygen_remover = false
var is_onshil_creator = false  # 온실가스 생성 균인지 여부
var is_onshil_remover = false  # 온실가스 제거 균인지 여부

func _ready():
	if is_oxygen_remover:
		animated_sprite_2d.animation = "blue"
		color = "blue"
	elif is_onshil_creator:  # 빙환균
		animated_sprite_2d.animation = "blue"
		color = "blue"
	elif is_onshil_remover:  # 빙절균
		animated_sprite_2d.animation = "blue"
		color = "blue"
	else:
		animated_sprite_2d.animation = "red"
		animation_player.play("going")

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position()

func _input(event):

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if get_tree().get_root().get_child(1).now_worm == self:
					is_dragging = true
					animation_player.stop()
					animated_sprite_2d.frame = 2
					
					if current_tween and current_tween.is_running():
						current_tween.kill()
					start_drag()
			elif event.is_released():
				if is_dragging:
					is_dragging = false
					animation_player.play("going")
					get_tree().get_root().get_child(1).now_worm = null

				
func _on_area_2d_mouse_entered():
	get_tree().get_root().get_child(1).now_worm = self


func on(thing):
	if thing == "blue":
		animated_sprite_2d.animation = "blue"
		color = "blue"

func go():
	current_tween = create_tween()  # tween 저장
	var go_val = Vector2(global_position.x + randi_range(-20,20),global_position.y + randi_range(-20,20))
	if get_tree().get_root().get_child(1).is_water_tile(go_val):
		if go_val.x < 64 * 16 and go_val.x > 0 and go_val.y < 64 * 16 and go_val.y > 0:
			current_tween.tween_property(self, "position", go_val, 10)

func jip():
	animation_player.stop()
	animated_sprite_2d.frame = 2

func nut():
	animation_player.play("going")

func start_drag():
	is_dragging = true
	animation_player.stop()
	animated_sprite_2d.frame = 2


func _on_area_2d_mouse_exited():
	get_tree().get_root().get_child(1).now_worm = null

func set_as_oxygen_remover():
	is_oxygen_remover = true

func set_as_onshil_creator():  # 빙환균 설정
	is_onshil_creator = true
	#var sprite = get_node("sprite")
	#if sprite:
		#sprite.frame = 2
		#animation_player.stop()

func set_as_onshil_remover():  # 빙절균 설정
	is_onshil_remover = true
#var sprite = get_node("sprite")
	#if sprite:
		#sprite.frame = 2
		#animation_player.stop()
