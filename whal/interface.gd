extends Control
#인벤토리 창

#등급별 색깔
const RARITY_COLOR = {
	"normal": Color(0.85, 0.85, 0.85),
	"rare": Color(0.4, 0.65, 1),
	"epic": Color(0.75, 0.45, 1),
	"mistic": Color(1, 0.65, 0.2),
}
const ITEM = preload("uid://b0ca4v3shdut")
@onready var active = $active

#얘들
@onready var skill_set = $skill_set
@onready var nine_patch_rect = $NinePatchRect
@onready var color_rect = $ColorRect
@onready var grid_container = $GridContainer
@onready var texture_rect = $TextureRect
@onready var name_ = $name
@onready var rarity = $rarity
@onready var real_tmi = $real_tmi
@onready var full = $full
@onready var not_active = $NinePatchRect/not_active

@onready var key_binder = $NinePatchRect/key_binder
var change = false
var pending : Scroll
var slots = []
var picked : Scroll
var is_binding = false

func cancel_change():
	if pending:
		if not i_thing:
			drop_scroll(pending)
		pending = null
	i_thing = null
	change = false
	skill_set.text = "skill set"

func _ready():
	Gamemaneger.interface = self
	slots = grid_container.get_children()
	for i in slots.size():
		slots[i].pressed.connect(_on_slot_pressed.bind(i))
	hide()

#i 누르면 열고 닫기
func _input(event):
	if event.is_action_pressed("i"):
		if visible:
			change = false
			skill_set.text = "skill set"
			close()
		else:
			open()

	if is_binding:

		if event is InputEventKey:

			if event.is_action_pressed("ui_cancel"):
				pass
			elif event.is_action_pressed("skill1"):
				Gamemaneger.skill_setting[0] = picked
			elif event.is_action_pressed("skill2"):
				Gamemaneger.skill_setting[1] = picked
			elif event.is_action_pressed("skill3"):
				Gamemaneger.skill_setting[2] = picked
			elif event.is_action_pressed("skill4"):
				Gamemaneger.skill_setting[3] = picked
			elif event.is_action_pressed("skill5"):
				Gamemaneger.skill_setting[4] = picked
			elif event.is_action_pressed("skill6"):
				Gamemaneger.skill_setting[5] = picked
			elif event.is_action_pressed("skill7"):
				Gamemaneger.skill_setting[6] = picked
			elif event.is_action_pressed("skill8"):
				Gamemaneger.skill_setting[7] = picked
			elif event.is_action_pressed("skill9"):
				Gamemaneger.skill_setting[8] = picked
			else:
				return
			Gamemaneger.ui.reset_skill()
			key_binder.visible = false
			is_binding = false
			#여기서 먹어야 esc 로 취소할때 esc_menu 까지 안 열림
			get_viewport().set_input_as_handled()



var i_thing = null
func open():
	visible = true
	refresh()
	Gamemaneger.push_ui(self)

func close():
	visible = false
	Gamemaneger.pop_ui(self)

func full_in(item,thing=null):
	i_thing = thing
	pending = item
	picked = null
	open()
	change = true
	skill_set.text = "change"
#가진 아이템으로 칸 채우기
func refresh():
	for i in slots.size():
		if i < Gamemaneger.my_scrolls.size():
			slots[i].icon = Gamemaneger.my_scrolls[i].texture
			slots[i].disabled = false
		else:
			slots[i].icon = null
			slots[i].disabled = true
	if Gamemaneger.my_scrolls.size() > 0:
		show_detail(Gamemaneger.my_scrolls[0])
	else:
		show_detail(null)

#칸 눌렀을때
func _on_slot_pressed(i):
	show_detail(Gamemaneger.my_scrolls[i])
	picked = Gamemaneger.my_scrolls[i]
#오른쪽에 자세히 보여주기
func show_detail(s : Scroll):
	if not s:
		texture_rect.texture = null
		name_.text = ""
		rarity.text = ""
		real_tmi.text = ""
		return
	texture_rect.texture = s.texture
	name_.text = s.name
	rarity.text = s.rarity
	real_tmi.text = s.real_tmi
	var c = RARITY_COLOR.get(s.rarity, Color.WHITE)
	name_.add_theme_color_override("font_color", c)
	rarity.add_theme_color_override("font_color", c)


func drop_scroll(s : Scroll):
	var item = ITEM.instantiate()
	item.thing = s
	get_parent().get_parent().add_child(item)
	item.sprite_2d.texture = s.texture
	if Gamemaneger.character:
		item.global_position = Gamemaneger.character.global_position

func _on_skill_set_pressed():
	if not picked:
		return
	if not picked.can_use:
		active.start()
		not_active.visible = true
		return
	if change:
		drop_scroll(picked)
		Gamemaneger.lose_scroll(picked)
		picked = null
		change = false
		skill_set.text = "skill set"
		var got = pending
		pending = null
		Gamemaneger.get_scroll(got)
		refresh()
		close()
	elif not is_binding:
		is_binding = true
		key_binder.visible = true


func _on_break_button_down():

	if not picked:
		return
	if not is_binding:
		Gamemaneger.break_scroll(picked)
		picked = null
		
	if change:
		Gamemaneger.break_scroll(picked)
		picked = null
		change = false
		skill_set.text = "skill set"
		var got = pending
		pending = null
		Gamemaneger.get_scroll(got)
		close()
	refresh()


func _on_active_timeout():
	not_active.visible = false
