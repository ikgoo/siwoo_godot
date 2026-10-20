extends Node2D
@onready var ui = $CanvasLayer/UI
@onready var bosu = $bosu
@onready var player = $CharacterBody2D
@onready var camera_2d = $Camera2D
@onready var animation_player = $AnimationPlayer
@onready var boss_ui = $CanvasLayer/boss_UI
@onready var marker_2d = $Marker2D
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var map_holder = get_node_or_null("map_holder")
@onready var upgrades = $TileMapLayer2/upgrades
@onready var tile_map_layer = $TileMapLayer
@onready var audio_stream_player = $AudioStreamPlayer

var upgrade = false
var max_distance: float = 70.0
var zoom_target = Vector2(2, 2)
var zoom_tween: Tween
var dragging = false


func _ready():
	
	audio_stream_player.play()
	Gamemaneger.tilemap = tile_map_layer
	add_to_group("boss")
	Gamemaneger.camera = camera_2d
	if map_holder:
		if Gamemaneger.tu:
			load_map("res://map_t.tscn")
		else:
			load_map(Gamemaneger.random_map())
	if animation_player:
		animation_player.play("respawn")
	Gamemaneger.cam_moving = true
	ui.fade_out()

#맵 갈아끼우기
func load_map(path : String):
	for c in map_holder.get_children():
		c.queue_free()
	var m = load(path).instantiate()
	map_holder.add_child(m)
	var sp = m.get_node_or_null("spawn")
	if sp and player:
		player.global_position = sp.global_position
# 부드럽게 줌하기
func cam_zoom(x, y, time):
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	zoom_tween.tween_property(camera_2d, "zoom", Vector2(x, y), time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _unhandled_input(event):
	if upgrade:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
		elif event is InputEventMouseMotion and dragging:
			camera_2d.off -= event.relative / camera_2d.zoom



func _process(delta):
	if animated_sprite_2d:
		if not upgrades.visible:
			if Input.is_action_just_pressed("f"):
				animation_player.play("upgrade_mode")
				animated_sprite_2d.visible = false
				upgrades.current_m.visible = true
				upgrades.price_2.visible = true
				upgrades.upgrade_ui.visible = true
				Gamemaneger.character.doing_s = true
				Gamemaneger.character.velocity = Vector2.ZERO
				upgrade = true
				Gamemaneger.push_ui(self)
				cam_zoom(1.2,1.2,1)
	if boss_ui:
		boss_ui.progress_bar.value = bosu.hp / 7.5

func close():
	exit_upgrade()

func exit_upgrade():
	if not upgrade:
		return
	animation_player.play("upgrade_out")
	upgrades.price_2.visible = false
	upgrades.current_m.visible = false
	upgrades.upgrade_ui.visible = false
	camera_2d.off = Vector2.ZERO
	animated_sprite_2d.visible = true
	Gamemaneger.character.doing_s = false
	upgrade = false
	Gamemaneger.pop_ui(self)

func cam_move(delta = 0.016):
	if upgrades:
		if not player or not camera_2d:
			return
		var offset = get_global_mouse_position() - player.global_position
		var clamped_offset = offset.limit_length(max_distance)
		var target_position = player.global_position + clamped_offset
		camera_2d.global_position = camera_2d.global_position.lerp(target_position, 10.0 * delta)
		upgrades.upgrade_ui.on(-1)
#카메라가 딴 걸 보게 하기
func cam_look(node):
	camera_2d.target = node

func respawn():
	animation_player.play("respawn")
	Gamemaneger.hp = Gamemaneger.max_hp


func hurt():
	ui.hurt()
	camera_2d.hurt()


func _on_area_2d_area_entered(area):
	animation_player.play("f_can")
	animated_sprite_2d.visible = true
	


func _on_area_2d_area_exited(area):
	animated_sprite_2d.visible = false
