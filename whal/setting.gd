extends Control

@onready var sound_menu = $NinePatchRect/sound_menu
@onready var ui_menu = $NinePatchRect/UI_menu
@onready var keys_menu = $NinePatchRect/keys_menu
@onready var check_box = $NinePatchRect/UI_menu/CheckBox
@onready var skill = $NinePatchRect/keys_menu/skill
@onready var basic = $NinePatchRect/keys_menu/basic
@onready var left = $NinePatchRect/keys_menu/basic/Label6/NinePatchRect6/left
@onready var jump = $NinePatchRect/keys_menu/basic/Label9/NinePatchRect7/jump
@onready var right = $NinePatchRect/keys_menu/basic/Label7/NinePatchRect7/right
@onready var dash = $NinePatchRect/keys_menu/basic/Label8/NinePatchRect8/dash
@onready var key_binding = $NinePatchRect/keys_menu/key_binding

@onready var _1 = $"NinePatchRect/keys_menu/skill/1/1"
@onready var _2 = $"NinePatchRect/keys_menu/skill/2/2"
@onready var _5 = $"NinePatchRect/keys_menu/skill/5/5"
@onready var _8 = $"NinePatchRect/keys_menu/skill/8/8"
@onready var _4 = $"NinePatchRect/keys_menu/skill/4/4"
@onready var _7 = $"NinePatchRect/keys_menu/skill/7/7"
@onready var _3 = $"NinePatchRect/keys_menu/skill/3/3"
@onready var _6 = $"NinePatchRect/keys_menu/skill/6/6"
@onready var _9 = $"NinePatchRect/keys_menu/skill/9/9"
var labels
var is_binding = false
var where = 0
func _ready():
	labels = [_1,_2,_3,_4,_5,_6,_7,_8,_9]

func _on_s_b_button_down():
	sound_menu.visible = true
	ui_menu.visible = false
	keys_menu.visible = false

func _on_k_b_button_down():
	sound_menu.visible = false
	ui_menu.visible = false
	keys_menu.visible = true


func _on_u_b_button_down():
	sound_menu.visible = false
	ui_menu.visible = true
	keys_menu.visible = false



func _on_ui_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"),linear_to_db(value / 100.0))


func _on_sfx_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("sfx"),linear_to_db(value / 100.0))


func _on_music_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"),linear_to_db(value / 100.0))


func _on_master_value_changed(value):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),linear_to_db(value / 100.0))


func _on_check_box_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)



func _on_basic_b_button_down():
	skill.visible = false
	basic.visible = true
	

func _on_skills_b_button_down():
	skill.visible = true
	basic.visible = false


func _on_left_button_down():
	if not is_binding:
		where = 0
		is_binding = true
		key_binding.visible = true


func _on_jump_button_down():
	if not is_binding:
		where = 1
		is_binding = true
		key_binding.visible = true

func _on_right_button_down():
	if not is_binding:
		where = 2
		is_binding = true
		key_binding.visible = true

func _on_dash_button_down():
	if not is_binding:
		where = 3
		is_binding = true
		key_binding.visible = true

func _input(event):
	if is_binding:
		if event is InputEventKey:
			key_binding.visible = false
			is_binding = false
			if where == 0:
				left.text = event.as_text()
				InputMap.action_erase_events("a")
				var new_event = InputEventKey.new()
				new_event.physical_keycode = event.keycode
			if where == 1:
				jump.text = event.as_text()
				InputMap.action_erase_events(" ")
				var new_event = InputEventKey.new()
				new_event.physical_keycode = event.keycode
			if where == 2:
				right.text = event.as_text()
				InputMap.action_erase_events("d")
				var new_event = InputEventKey.new()
				new_event.physical_keycode = event.keycode
			if where == 3:
				dash.text = event.as_text()
				InputMap.action_erase_events("shift")
				var new_event = InputEventKey.new()
				new_event.physical_keycode = event.keycode
			if where > 3:
				where -= 3
				labels[where-1].text = event.as_text()
				InputMap.action_erase_events("skill"+str(where))
				var new_event = InputEventKey.new()
				new_event.physical_keycode = event.keycode
				

func _on_exit_button_down():
	visible = false


func _on__pressed(extra_arg_0):
	if not is_binding:
		where = extra_arg_0 + 3
		is_binding = true
		key_binding.visible = true
		
