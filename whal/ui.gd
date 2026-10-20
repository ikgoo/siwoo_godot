extends Control
#등급별 색깔
const RARITY_COLOR = {
	"normal": Color(0.85, 0.85, 0.85),
	"rare": Color(0.4, 0.65, 1),
	"epic": Color(0.75, 0.45, 1),
	"mistic": Color(1, 0.65, 0.2),
}
#얘들
@onready var money = $money
@onready var label = $Label
@onready var label_2 = $Label2
@onready var mesh_instance_2d = $MeshInstance2D
@onready var progress_bar = $ProgressBar
@onready var hp_label = $ProgressBar/hp_label
@onready var big_cool_bar = $BigCoolBar
@onready var animation_player = $AnimationPlayer
@onready var scroll_popup = $scroll_popup
@onready var scroll_icon = $scroll_popup/icon
@onready var scroll_name = $scroll_popup/item_name
@onready var scroll_rarity = $scroll_popup/rarity
@onready var scroll_real = $scroll_popup/real_tmi
@onready var _1 = $"weapon_panel3/GridContainer/Button/1"
@onready var _2 = $"weapon_panel3/GridContainer/Button2/2"
@onready var _3 = $"weapon_panel3/GridContainer/Button3/3"
@onready var _4 = $"weapon_panel3/GridContainer/Button4/4"
@onready var _5 = $"weapon_panel3/GridContainer/Button5/5"
@onready var _6 = $"weapon_panel3/GridContainer/Button6/6"
@onready var _7 = $"weapon_panel3/GridContainer/Button7/7"
@onready var _8 = $"weapon_panel3/GridContainer/Button8/8"
@onready var cool1 = $"weapon_panel3/GridContainer/Button/cool1"
@onready var cool2 = $"weapon_panel3/GridContainer/Button2/cool2"
@onready var cool3 = $"weapon_panel3/GridContainer/Button3/cool3"
@onready var cool4 = $"weapon_panel3/GridContainer/Button4/cool4"
@onready var cool5 = $"weapon_panel3/GridContainer/Button5/cool5"
@onready var cool6 = $"weapon_panel3/GridContainer/Button6/cool6"
@onready var cool7 = $"weapon_panel3/GridContainer/Button7/cool7"
@onready var cool8 = $"weapon_panel3/GridContainer/Button8/cool8"
@onready var dead_ui = $dead_ui
@onready var money_2 = $money2
@onready var interface = $interface
@onready var piece = $piece
@onready var make_ui = $make_ui
@onready var close = $close
@onready var open = $open
var skill_t
var cool_t
var popup_tween : Tween
var popup_y : float
var showing = false
func _ready():
	Gamemaneger.ui = self
	popup_y = scroll_popup.position.y
	skill_t = [_1,_2,_3,_4,_5,_6,_7,_8]
	cool_t = [cool1,cool2,cool3,cool4,cool5,cool6,cool7,cool8]
	for c in cool_t:
		c.label_settings = c.label_settings.duplicate()
func reset_skill():
	for i in range(9):
		if Gamemaneger.skill_setting[i]:
			skill_t[i].texture = Gamemaneger.skill_setting[i].texture

func refresh():
	for i in range(9):
		if Gamemaneger.skill_setting[i]:
			skill_t[i].texture = Gamemaneger.skill_setting[i].texture
	

func _process(delta):
	refresh()
	#업데이트
	piece.text = str(int(Gamemaneger.piece))
	for i in range(8):
		if Gamemaneger.character.skill_cool[i] > 0:
			cool_t[i].label_settings.font_color = Color(1.0, 0.526, 0.46, 1.0)
		else:
			cool_t[i].label_settings.font_color = Color(0.309, 0.664, 0.0, 1.0)
		cool_t[i].text = str(snapped(Gamemaneger.character.skill_cool[i],0.1))
	money.text = str(int(Gamemaneger.money))
	money_2.text = str(int(Gamemaneger.in_money))
	progress_bar.max_value = Gamemaneger.max_hp
	progress_bar.value = Gamemaneger.hp
	hp_label.text = str(ceili(Gamemaneger.hp)) + "/" + str(ceili(Gamemaneger.max_hp))
	label.text = str(Gamemaneger.small_attack_n) + "/" + str(Gamemaneger.small_attack_p)
	label_2.text = str(Gamemaneger.big_attack_n) + "/" + str(Gamemaneger.big_attack_p)
	big_cool_bar.value = Gamemaneger.big_attack_cool * 100
#데미지 입었을때 이펙트
func hurt():
	mesh_instance_2d.self_modulate.a = 0.3
	var tween = create_tween()
	tween.tween_property(mesh_instance_2d, "self_modulate:a", 0, 0.1)
#페이드 아웃
func  fade_out():

	animation_player.play('fade_out')

#페이드 인
func fade_black():
	animation_player.play('fade_black')
#아이템 설명
func show_scroll(s:Scroll):
	scroll_icon.texture = s.texture
	scroll_name.text = s.name
	scroll_rarity.text = s.rarity
	scroll_real.text = s.real_tmi
	var c = RARITY_COLOR.get(s.rarity, Color.WHITE)
	scroll_name.add_theme_color_override("font_color", c)
	scroll_rarity.add_theme_color_override("font_color", c)
	animation_player.play('show_in')
func hide_scroll():
	animation_player.play_backwards("show_in")


func change(item,thing=null):
	Gamemaneger.interface.full_in(item,thing)
	
