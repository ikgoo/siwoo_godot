extends Node2D
@onready var ui = $CanvasLayer/UI

@onready var player = $CharacterBody2D
@onready var camera_2d = $Camera2D
@onready var animation_player = $AnimationPlayer
@onready var animation_player_2 = $AnimationPlayer2
@onready var roll = $roll
@onready var tile_map_layer = $TileMapLayer
@onready var tile_map_layer_2 = $TileMapLayer2
@onready var tile_map_layer_3 = $TileMapLayer3
@onready var audio_stream_player = $AudioStreamPlayer

var max_distance: float = 70.0

var zoom_target = Vector2(2, 2)
var zoom_tween: Tween

func _ready():
	audio_stream_player.play()
	Gamemaneger.tilemap = tile_map_layer_3
	animation_player.play("idle")
	Gamemaneger.cam_moving = true
	ui.fade_out()
# 부드럽게 줌하기
func cam_zoom(x, y, time):
	var to = Vector2(x, y)

	if zoom_target.is_equal_approx(to):
		return
	zoom_target = to
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_property(camera_2d, "zoom", to, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)



func cam_move(delta = 0.016):
	if not player or not camera_2d:
		return
	
	var mouse_pos = get_global_mouse_position()
	var offset = mouse_pos - player.global_position
	var clamped_offset = offset.limit_length(max_distance)
	var target_position = player.global_position + clamped_offset
	camera_2d.global_position = camera_2d.global_position.lerp(target_position, 10.0 * delta)

#카메라가 딴 걸 보게 하기
func cam_look(node):
	camera_2d.target = node

func hurt():
	ui.hurt()
	camera_2d.hurt()

func end_idle():
	animation_player.pause()
	
func resume():
	animation_player.play("idle")
