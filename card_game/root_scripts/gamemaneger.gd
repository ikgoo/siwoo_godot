extends Node

signal change_money(amoney)

## 카드 종류
enum card_thing {
	## 적
	DANGER,
	## 종이
	LITTLEPAPER,
	## 독보기
	SEE,
	## 상점
	STORE
}

enum playing_state {
	## 카드 선택 상태
	SELECT,
	## 카드 보기 상태
	SEE,
	STORE,
	DANGER,
	LITTLE_PAPER,
}

var flip_cards = [
	preload("res://tscn/danger_card.tscn"),
	preload("res://tscn/little_paper_card.tscn"),
	preload("res://tscn/see_card.tscn"),
	preload("res://tscn/selling_card.tscn"),
]

var my_charater_f = null

var my_charater_s = null

var my_charater_t = null

var mob_f = null

var mob_s = null

var mob_t = null

var m_in = false

var money : int = 0 :
	set(value):
		money = value
		change_money.emit(value)

var now_playing: playing_state = playing_state.SELECT
