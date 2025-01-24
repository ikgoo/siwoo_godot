extends Node2D

@onready var label = $Sprite2D/Node2D/Label
@onready var area_2d = $Area2D

var m_in = false
# Called when the node enters the scene tree for the first time.
func _ready():
	# Gamemaneger의 change_money 시그널을 연결
	Gamemaneger.connect("change_money", _on_money_changed)
	pass # Replace with function body.

func _on_money_changed(amoney):
	# 돈이 변경되었을 때의 로직 추가
	add_money(amoney)


# Called every frame. 'delta' is the elapsed time since the previous frame.	 
func _process(delta):

	label.text = str(Gamemaneger.money)
	Gamemaneger.m_in = m_in
	area_2d.position = get_local_mouse_position()
	

var current_tween: Tween
var target_value_old : int

func add_money(amoney : int) -> void:
	var current_value = int(label.text)
	var target_value = current_value + amoney

	# 현재 실행 중인 트윈이 있다면 즉시 완료하고 새로운 트윈 시작
	if current_tween and current_tween.is_running():
		current_tween.kill() # 현재 트윈 중지
		label.text = str(target_value_old) # 이전 목표값으로 즉시 설정
		current_value = target_value_old # 현재 값 업데이트
		target_value = current_value + amoney # 새로운 목표값 설정
	
	target_value_old = target_value

	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_EXPO)
	current_tween.set_ease(Tween.EASE_IN)

	current_tween.tween_method(
		func(value: float): 
			label.text = str(int(value)),
		float(current_value),
		float(target_value),
		0.5
	)


	
func see():
	pass
	


func danger():
	pass
	
	
func store():
	pass
	
	
func paper():
	pass
