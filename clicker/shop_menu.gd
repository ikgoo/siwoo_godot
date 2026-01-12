extends Control

## /** 스킨 상점 UI 관리
##  * 스킨 목록 표시, 구매, 적용 기능 제공
##  */

# 노드 참조
@onready var background: ColorRect = $Background
@onready var title: Label = $Title
@onready var money_label: Label = $MoneyLabel
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var skin_list_container: VBoxContainer = $ScrollContainer/SkinListContainer
@onready var close_button: Button = $CloseButton
@onready var skin_item_template: PanelContainer = $SkinItemTemplate

func _ready():
	# 템플릿은 숨김 상태 유지 (이미 tscn에서 visible=false)
	skin_item_template.visible = false
	
	# 스킨 목록 업데이트
	_update_skin_list()

## /** 스킨 목록을 업데이트한다
##  * @returns void
##  */
func _update_skin_list() -> void:
	# 기존 아이템 제거
	for child in skin_list_container.get_children():
		child.queue_free()
	
	# 스킨 목록 생성
	for skin_id in Globals.available_skins.keys():
		var skin: SkinItem = Globals.available_skins[skin_id]
		var item = _create_skin_item(skin)
		skin_list_container.add_child(item)
	
	# 보유 돈 업데이트
	money_label.text = "보유: 🪙 " + str(Globals.auto_money)

## /** 스킨 아이템 UI를 생성한다 (템플릿 복제 방식)
##  * @param skin SkinItem 스킨 데이터
##  * @returns PanelContainer 생성된 스킨 아이템 UI
##  */
func _create_skin_item(skin: SkinItem) -> PanelContainer:
	# 템플릿 복제
	var panel: PanelContainer = skin_item_template.duplicate()
	panel.visible = true
	
	# 패널 스타일 설정
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	panel.add_theme_stylebox_override("panel", style)
	
	# 자식 노드들 가져오기
	var vbox: VBoxContainer = panel.get_node("VBoxContainer")
	var name_label: Label = vbox.get_node("NameLabel")
	var desc_label: Label = vbox.get_node("DescriptionLabel")
	var color_preview: ColorRect = vbox.get_node("ColorPreview")
	var button_container: HBoxContainer = vbox.get_node("ButtonContainer")
	var price_label: Label = button_container.get_node("PriceLabel")
	var buy_button: Button = button_container.get_node("BuyButton")
	var apply_button: Button = button_container.get_node("ApplyButton")
	var applied_label: Label = button_container.get_node("AppliedLabel")
	
	# 데이터 바인딩
	name_label.text = skin.name
	desc_label.text = skin.description
	color_preview.color = skin.bg_color
	
	# 가격 표시
	price_label.text = "🪙 " + str(skin.price) if skin.price > 0 else "무료"
	
	# 소유 여부에 따라 버튼 표시
	if Globals.is_skin_owned(skin.id):
		buy_button.visible = false
		
		if Globals.current_skin == skin.id:
			# 적용됨 표시
			apply_button.visible = false
			applied_label.visible = true
		else:
			# 적용 버튼 표시
			apply_button.visible = true
			applied_label.visible = false
			apply_button.pressed.connect(_on_apply_skin.bind(skin.id))
	else:
		# 구매 버튼 표시
		buy_button.visible = true
		apply_button.visible = false
		applied_label.visible = false
		buy_button.disabled = Globals.auto_money < skin.price
		buy_button.pressed.connect(_on_buy_skin.bind(skin.id))
	
	return panel

## /** 스킨 구매 버튼 핸들러
##  * @param skin_id String 구매할 스킨 ID
##  * @returns void
##  */
func _on_buy_skin(skin_id: String) -> void:
	if Globals.buy_skin(skin_id):
		_update_skin_list()
		print("스킨 구매 성공: ", skin_id)
	else:
		print("스킨 구매 실패: ", skin_id)

## /** 스킨 적용 버튼 핸들러
##  * @param skin_id String 적용할 스킨 ID
##  * @returns void
##  */
func _on_apply_skin(skin_id: String) -> void:
	if Globals.apply_skin(skin_id):
		_update_skin_list()
		print("스킨 적용 성공: ", skin_id)
	else:
		print("스킨 적용 실패: ", skin_id)

## /** 닫기 버튼 핸들러
##  * @returns void
##  */
func _on_close_button_pressed() -> void:
	visible = false
