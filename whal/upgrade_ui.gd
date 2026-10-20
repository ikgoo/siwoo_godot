extends Control
const ARMOR = preload("uid://xoipx34efolj")
const BOSS_DAM = preload("uid://yco504rbuwue")
const CRIT = preload("uid://coj2pjtgaknon")
const HP = preload("uid://c1hqq5srds8l6")
const MONEY = preload("uid://dkxfnt533po6h")
const PROTECT = preload("uid://dyk5d5s73sbsn")
const RESPAWN = preload("uid://bco0n2ap4liic")
const RIGHT_SPEED = preload("uid://dwabcbf2ta5ir")
const F = preload("uid://d3c8h0dre21cv")
const GAKSUNG = preload("uid://dq1ifjnjmwvrx")
const SPEED = preload("uid://b21ohytvjdan2")

@onready var name_ = $NinePatchRect/name
@onready var tmi = $NinePatchRect/tmi
@onready var line = $NinePatchRect/line
@onready var now_level = $NinePatchRect/now_level
@onready var next_level = $"NinePatchRect/next level"
@onready var max_level = $NinePatchRect/max_level
@onready var icon = $NinePatchRect/NinePatchRect/icon
@onready var price = $NinePatchRect/price
@onready var money_2 = $NinePatchRect/money2

var ups = [
	F,
	HP,
	GAKSUNG,
	ARMOR,
	RESPAWN,
	PROTECT,
	CRIT,
	MONEY,
	SPEED,
	BOSS_DAM,
	RIGHT_SPEED,
]

var now_arg = -1

func _ready():
	money_2.text = str(Gamemaneger.money)


func on(num):
	money_2.text = str(Gamemaneger.money)
	if num == -1:
		visible = false
		return
	visible = true
	now_arg = num

	var up = ups[num]
	var lv = Gamemaneger.upgrade[num]
	var last = up.upgrade_much.size()

	name_.text = up.name
	icon.texture = up.icon
	tmi.text = up.tmi
	if lv >= last:
		now_level.text = ""
		next_level.text = ""
		max_level.text = "Max level\n" + str(up.upgrade_much[last - 1]) + "%"
		price.text = ""
	else:
		max_level.text = ""
		if lv == 0:
			now_level.text = ""
		else:
			now_level.text = "level" + str(lv) + "\n" + str(up.upgrade_much[lv - 1]) + "%"
		next_level.text = "level" + str(lv + 1) + "\n" + str(up.upgrade_much[lv]) + "%"
		price.text = str(up.price[lv])
	upgrading()
func _on_button_pressed():
	if not len(ups[now_arg].price) == Gamemaneger.upgrade[now_arg]:
		var price = ups[now_arg].price[Gamemaneger.upgrade[now_arg]]
		if price < 0:
			return
		
		if Gamemaneger.money < price:
			return
		Gamemaneger.money -= price
		Gamemaneger.upgrade[now_arg] += 1
		on(now_arg)
	get_parent().get_parent().refresh()

func upgrading():
	var lv = Gamemaneger.upgrade[now_arg]
	if now_arg <= 0 or lv == 0:
		return
	var a = ups[now_arg].upgrade_much[lv - 1]
	if now_arg == 1:
		Gamemaneger.hp = a + 100
		Gamemaneger.max_hp = a + 100
	elif now_arg == 2:
		Gamemaneger.gaksung = a
	elif now_arg == 3:
		Gamemaneger.plus_hp_round = a
	elif now_arg == 4:
		Gamemaneger.respawn = a
	elif now_arg == 5:
		Gamemaneger.protect = a
	elif now_arg == 6:
		Gamemaneger.crit = a
	elif now_arg == 7:
		Gamemaneger.money_per = a
	elif now_arg == 8:
		Gamemaneger.speed = a
		Gamemaneger.character.reloadtimer.wait_time = ((100-Gamemaneger.speed) / 100.0)
	elif now_arg == 9:
		Gamemaneger.boss_dam = a
	elif now_arg == 10:
		Gamemaneger.r_click_speed = a
		Gamemaneger.character.big_arrow_t.wait_time = ((100-Gamemaneger.r_click_speed) / 100.0)
