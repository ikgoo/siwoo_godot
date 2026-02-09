extends Control

## /** 업그레이드 메뉴 스크립트
##  * NPC 대화 형태로 업그레이드를 선택/구매하는 UI
##  * - 해금된 업그레이드만 선택 가능 (잠긴 건 반투명 + 🔒)
##  * - 선택 시 상세 정보 표시, 구매 버튼 활성화
##  * - process_mode = ALWAYS로 일시정지 중에도 동작
##  *
##  * 사용법:
##  *   upgrade.gd에서 instantiate 후 open_menu() 호출
##  */

# ========================================
# 시그널
# ========================================
signal upgrade_purchased(type_id: int)  # 업그레이드 구매 완료 시
signal menu_closed()                     # 메뉴 닫힐 때

# ========================================
# 노드 참조 (upgrade_menu.tscn에서 미리 배치)
# ========================================
@onready var dialogue_label: Label = $Panel/VBox/DialogueLabel
@onready var info_label: Label = $Panel/VBox/InfoLabel
@onready var buy_button: Button = $Panel/VBox/ActionBox/BuyButton
@onready var close_button: Button = $Panel/VBox/ActionBox/CloseButton

# 7개 업그레이드 버튼 (Btn0~Btn6)
@onready var buttons: Array[Button] = [
	$Panel/VBox/ButtonGrid/Btn0,
	$Panel/VBox/ButtonGrid/Btn1,
	$Panel/VBox/ButtonGrid/Btn2,
	$Panel/VBox/ButtonGrid/Btn3,
	$Panel/VBox/ButtonGrid/Btn4,
	$Panel/VBox/ButtonGrid/Btn5,
	$Panel/VBox/ButtonGrid/Btn6,
]

# ========================================
# 상수
# ========================================
# 버튼 라벨 번역 키 (type_id 순서)
const TYPE_LABEL_KEYS: Array[String] = [
	"UPGRADE DIAMOND",  # 0
	"UPGRADE SPEED",    # 1
	"UPGRADE RANDOM",   # 2
	"UPGRADE TIER",     # 3
	"UPGRADE AUTO",     # 4
	"UPGRADE KEY",      # 5
	"UPGRADE TILE",     # 6
]

# NPC 대사 번역 키 (랜덤)
const NPC_DIALOGUE_KEYS: Array[String] = [
	"UPGRADE NPC 1",
	"UPGRADE NPC 2",
	"UPGRADE NPC 3",
	"UPGRADE NPC 4",
	"UPGRADE NPC 5",
]

# ========================================
# 내부 변수
# ========================================
## 현재 선택된 업그레이드 타입 (-1 = 미선택)
var selected_type: int = -1

func _ready():
	visible = false

## /** 메뉴를 열고 게임을 일시정지한다 */
func open_menu():
	visible = true
	selected_type = -1
	
	# 랜덤 NPC 대사
	var key = NPC_DIALOGUE_KEYS[randi() % NPC_DIALOGUE_KEYS.size()]
	dialogue_label.text = Globals.get_text(key)
	
	# 정보 초기화
	info_label.text = Globals.get_text("UPGRADE SELECT")
	buy_button.visible = false
	
	# 버튼 상태 갱신
	_refresh_buttons()
	
	# 게임 일시정지
	get_tree().paused = true

## /** 메뉴를 닫고 게임을 재개한다 */
func close_menu():
	visible = false
	get_tree().paused = false
	menu_closed.emit()

# ========================================
# 입력 처리 (_input으로 직접 처리)
# ========================================
## /** 일시정지 상태에서도 버튼 클릭이 동작하도록
##  * _gui_input 대신 _input + is_hovered() 방식 사용
##  */
func _input(event: InputEvent):
	if not visible:
		return
	
	# 마우스 클릭 처리
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		# 업그레이드 버튼 클릭 체크
		for i in range(buttons.size()):
			if buttons[i] and buttons[i].is_hovered():
				Globals.play_click_sound()
				_on_upgrade_button_pressed(i)
				get_viewport().set_input_as_handled()
				return
		
		# 구매 버튼 클릭 체크
		if buy_button.is_hovered() and buy_button.visible and not buy_button.disabled:
			Globals.play_click_sound()
			_on_buy_pressed()
			get_viewport().set_input_as_handled()
			return
		
		# 닫기 버튼 클릭 체크
		if close_button.is_hovered() and close_button.visible:
			Globals.play_click_sound()
			_on_close_pressed()
			get_viewport().set_input_as_handled()
			return
	
	# ESC로 닫기
	if event.is_action_pressed("ui_cancel"):
		close_menu()
		get_viewport().set_input_as_handled()

# ========================================
# 버튼 상태 갱신
# ========================================

## /** 모든 업그레이드 버튼의 텍스트/투명도를 갱신한다 */
func _refresh_buttons():
	for i in range(buttons.size()):
		var is_unlocked = Globals.is_upgrade_unlocked(i)
		var level = _get_level(i)
		var max_level = _get_max_level(i)
		var is_max = (level >= max_level)
		var label_text = Globals.get_text(TYPE_LABEL_KEYS[i])
		
		if is_unlocked:
			if is_max:
				buttons[i].text = "%s (MAX)" % label_text
				buttons[i].modulate = Color(0.6, 0.6, 0.6)
			else:
				buttons[i].text = "%s Lv%d" % [label_text, level]
				buttons[i].modulate = Color(1, 1, 1)
		else:
			# 잠긴 상태 — 반투명 + 자물쇠
			buttons[i].text = "🔒 %s" % label_text
			buttons[i].modulate = Color(1, 1, 1, 0.4)

# ========================================
# 버튼 클릭 핸들러
# ========================================

## /** 업그레이드 버튼 클릭 시
##  * @param type_id int 클릭한 업그레이드 타입 ID (0~6)
##  */
func _on_upgrade_button_pressed(type_id: int):
	# 잠긴 업그레이드면 메시지만 표시
	if not Globals.is_upgrade_unlocked(type_id):
		info_label.text = Globals.get_text("UPGRADE LOCKED")
		buy_button.visible = false
		return
	
	# 선택 업데이트
	selected_type = type_id
	_update_info_label()

## /** 구매 버튼 클릭 시 */
func _on_buy_pressed():
	if selected_type < 0:
		return
	
	var cost = _get_cost(selected_type)
	if cost == -1:
		info_label.text = Globals.get_text("UPGRADE MAX REACHED")
		return
	
	# 돈 부족 체크
	if Globals.money < cost:
		info_label.text = Globals.get_text("UPGRADE NOT ENOUGH") % [cost, Globals.money]
		return
	
	# 돈 차감
	Globals.money -= cost
	
	# 업그레이드 적용
	_apply_upgrade(selected_type)
	
	# UI 갱신
	_refresh_buttons()
	_update_info_label()
	
	# 메뉴 닫기 + 시그널 (카메라 연출용)
	close_menu()
	upgrade_purchased.emit(selected_type)

## /** 닫기 버튼 클릭 시 */
func _on_close_pressed():
	close_menu()

# ========================================
# 정보 라벨 갱신
# ========================================

## /** 선택된 업그레이드의 상세 정보를 표시한다 */
func _update_info_label():
	if selected_type < 0:
		info_label.text = Globals.get_text("UPGRADE SELECT")
		buy_button.visible = false
		return
	
	var level = _get_level(selected_type)
	var max_level = _get_max_level(selected_type)
	var is_max = (level >= max_level)
	var label_text = Globals.get_text(TYPE_LABEL_KEYS[selected_type])
	
	if is_max:
		info_label.text = "%s\n%s" % [label_text, Globals.get_text("UPGRADE MAX STAR")]
		buy_button.visible = false
		return
	
	var cost = _get_cost(selected_type)
	var effect = _get_effect_text(selected_type)
	var can_afford = Globals.money >= cost
	
	info_label.text = Globals.get_text("UPGRADE INFO FORMAT") % [
		label_text, level, level + 1, Globals.get_text("UPGRADE COST") % cost, effect
	]
	
	buy_button.visible = true
	buy_button.disabled = not can_afford
	buy_button.text = Globals.get_text("UPGRADE BUY AFFORD") % cost if can_afford else Globals.get_text("UPGRADE BUY CANT")

# ========================================
# 헬퍼 함수 (Globals 데이터 접근)
# ========================================

## /** 해당 타입의 현재 레벨을 반환한다
##  * @param type_id int 업그레이드 타입 ID
##  * @returns int 현재 레벨
##  */
func _get_level(type_id: int) -> int:
	match type_id:
		0: return Globals.diamond_value_level
		1: return Globals.pickaxe_speed_level
		2: return Globals.money_randomize_level
		3: return Globals.mining_tier_level
		4: return Globals.auto_mining_speed_level
		5: return Globals.mining_key_count_level
		6: return Globals.rock_money_level
	return 0

## /** 해당 타입의 최대 레벨을 반환한다
##  * @param type_id int 업그레이드 타입 ID
##  * @returns int 최대 레벨
##  */
func _get_max_level(type_id: int) -> int:
	match type_id:
		0: return Globals.diamond_value_upgrades.size()
		1: return Globals.pickaxe_speed_upgrades.size()
		2: return Globals.money_randomize_upgrades.size()
		3: return Globals.mining_tier_upgrades.size()
		4: return Globals.auto_mining_speed_upgrades.size()
		5: return Globals.mining_key_count_upgrades.size()
		6: return Globals.rock_money_upgrades.size()
	return 0

## /** 해당 타입의 다음 레벨 비용을 반환한다
##  * @param type_id int 업그레이드 타입 ID
##  * @returns int 비용 (-1이면 MAX)
##  */
func _get_cost(type_id: int) -> int:
	var level = _get_level(type_id)
	var max_level = _get_max_level(type_id)
	if level >= max_level:
		return -1
	
	match type_id:
		0: return Globals.diamond_value_upgrades[level].x
		1: return Globals.pickaxe_speed_upgrades[level].x
		2: return Globals.money_randomize_upgrades[level].x
		3: return Globals.mining_tier_upgrades[level].x
		4: return int(Globals.auto_mining_speed_upgrades[level].x)
		5: return Globals.mining_key_count_upgrades[level].x
		6: return Globals.rock_money_upgrades[level].x
	return 0

## /** 해당 타입의 다음 레벨 효과 텍스트를 반환한다
##  * @param type_id int 업그레이드 타입 ID
##  * @returns String 효과 설명
##  */
func _get_effect_text(type_id: int) -> String:
	var level = _get_level(type_id)
	var max_level = _get_max_level(type_id)
	if level >= max_level:
		return Globals.get_text("UPGRADE MAX")
	
	match type_id:
		0:  # 다이아 획득량
			var new_val = Globals.diamond_value_upgrades[level].y
			return Globals.get_text("UPGRADE EFFECT YIELD") % new_val
		1:  # 곡괭이 속도
			var new_clicks = Globals.pickaxe_speed_upgrades[level].y
			return Globals.get_text("UPGRADE EFFECT CLICKS") % new_clicks
		2:  # 돈 랜덤 확률
			var x2 = Globals.money_randomize_upgrades[level].y
			var x3 = Globals.money_randomize_upgrades[level].z
			return "x2: %d%%, x3: %d%%" % [x2, x3]
		3:  # 채굴 티어
			var new_tier = Globals.mining_tier_upgrades[level].y
			return Globals.get_text("UPGRADE EFFECT TIER") % [new_tier, new_tier]
		4:  # 자동 채굴 속도
			var new_interval = Globals.auto_mining_speed_upgrades[level].y
			return Globals.get_text("UPGRADE EFFECT INTERVAL") % new_interval
		5:  # 채굴 키 개수
			var new_count = Globals.mining_key_count_upgrades[level].y
			var key_names = ["F", "J", "D", "K", "S", "L"]
			var keys_str = ", ".join(key_names.slice(0, new_count))
			return Globals.get_text("UPGRADE EFFECT KEYS") % [new_count, keys_str]
		6:  # 타일 보너스
			var new_bonus = Globals.rock_money_upgrades[level].y
			return Globals.get_text("UPGRADE EFFECT BONUS") % new_bonus
	return ""

## /** 업그레이드를 실제로 적용한다 (레벨 증가 + Globals 갱신)
##  * @param type_id int 업그레이드 타입 ID
##  */
func _apply_upgrade(type_id: int):
	match type_id:
		0:  # 다이아 획득량
			Globals.diamond_value_level += 1
			Globals.update_diamond_value()
		1:  # 곡괭이 속도
			Globals.pickaxe_speed_level += 1
			Globals.update_pickaxe_speed()
		2:  # 돈 랜덤 확률
			Globals.money_randomize_level += 1
			Globals.update_money_randomize()
		3:  # 채굴 티어
			Globals.mining_tier_level += 1
			Globals.update_mining_tier()
		4:  # 자동 채굴 속도
			Globals.auto_mining_speed_level += 1
			Globals.update_auto_mining_speed()
		5:  # 채굴 키 개수
			Globals.mining_key_count_level += 1
			Globals.update_mining_key_count()
		6:  # 타일 보너스
			Globals.rock_money_level += 1
			Globals.update_rock_money()
	
	Globals.save_settings()
