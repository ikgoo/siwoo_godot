extends Control

## /** 스킨 상점 UI 관리
##  * 스킨 목록 표시, 구매, 적용, 인벤토리 기능 제공
##  */

# 상점 노드 참조
@onready var background: ColorRect = $Background
@onready var title: Label = $Title
@onready var money_label: Label = $MoneyLabel
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var skin_list_container: VBoxContainer = $ScrollContainer/SkinListContainer
@onready var close_button: Button = $CloseButton
@onready var skin_item_template: PanelContainer = $SkinItemTemplate
@onready var inventory_button: Button = $InventoryButton

# 인벤토리 노드 참조
@onready var inventory_panel: Panel = $InventoryPanel
@onready var sprite1_grid: GridContainer = $InventoryPanel/VBoxContainer/Sprite1Grid
@onready var sprite2_grid: GridContainer = $InventoryPanel/VBoxContainer/Sprite2Grid

# 인벤토리 아이템 크기
const INVENTORY_ITEM_SIZE = 40

func _ready():
	# 템플릿은 숨김 상태 유지 (이미 tscn에서 visible=false)
	if skin_item_template:
		skin_item_template.visible = false
	if inventory_panel:
		inventory_panel.visible = false
	
	# UI 텍스트 번역 적용
	_update_ui_texts()
	
	# 스킨 목록 업데이트
	_update_skin_list()


## UI 텍스트에 번역 적용
func _update_ui_texts() -> void:
	title.text = Globals.get_text("SHOP TITLE")
	close_button.text = Globals.get_text("SHOP CLOSE")
	inventory_button.text = Globals.get_text("SHOP INVENTORY")

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
	money_label.text = Globals.get_text("SHOP OWNED") + " 🪙 " + str(Globals.auto_money)

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
	var texture_preview: TextureRect = vbox.get_node("TexturePreview")
	var button_container: HBoxContainer = vbox.get_node("ButtonContainer")
	var price_container: Control = button_container.get_node("PriceContainer")
	var price_label: Label = price_container.get_node("PriceLabel")
	var buy_button: Button = button_container.get_node("BuyButton")
	var apply_button: Button = button_container.get_node("ApplyButton")
	var applied_label: Label = button_container.get_node("AppliedLabel")
	
	# 데이터 바인딩
	name_label.text = skin.name
	# 스킨 타입 표시 (Sprite1 = 캐릭터, Sprite2 = 도구)
	var type_str = "[" + Globals.get_text("SHOP CHARACTER SKIN") + "] " if skin.target_sprite == 1 else "[" + Globals.get_text("SHOP TOOL SKIN") + "] "
	desc_label.text = type_str + skin.description
	# 텍스처 미리보기 설정
	if skin.texture:
		texture_preview.texture = skin.texture
	
	# 가격 표시
	price_label.text = "🪙 " + str(skin.price) if skin.price > 0 else Globals.get_text("SHOP FREE")
	
	# 상점에서는 구매만 가능 (적용은 인벤토리에서)
	# 소유 여부에 따라 버튼 표시
	if Globals.is_skin_owned(skin.id):
		# 이미 소유한 스킨 - 구매 불가 표시
		buy_button.visible = true
		buy_button.disabled = true
		buy_button.text = Globals.get_text("SHOP OWNED ITEM")
		apply_button.visible = false
		applied_label.visible = false
	else:
		# 구매 버튼 표시
		buy_button.visible = true
		buy_button.text = Globals.get_text("SHOP BUY")
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

## /** 스킨 적용 버튼 핸들러
##  * @param skin_id String 적용할 스킨 ID
##  * @returns void
##  */
func _on_apply_skin(skin_id: String) -> void:
	if Globals.apply_skin(skin_id):
		_update_skin_list()

## /** 닫기 버튼 핸들러
##  * @returns void
##  */
func _on_close_button_pressed() -> void:
	visible = false

## /** 인벤토리 버튼 핸들러 - 상점 숨기고 인벤토리 표시
##  * @returns void
##  */
func _on_inventory_button_pressed() -> void:
	_show_inventory()

## /** 인벤토리 뒤로가기 버튼 핸들러 - 인벤토리 숨기고 상점 표시
##  * @returns void
##  */
func _on_inventory_back_pressed() -> void:
	_show_shop()

## /** 상점 UI를 표시한다
##  * @returns void
##  */
func _show_shop() -> void:
	# 상점 UI 표시
	if background:
		background.visible = true
	if title:
		title.visible = true
	if money_label:
		money_label.visible = true
	if scroll_container:
		scroll_container.visible = true
	if close_button:
		close_button.visible = true
	if inventory_button:
		inventory_button.visible = true
	
	# 인벤토리 숨김
	if inventory_panel:
		inventory_panel.visible = false
	
	# 상점 목록 업데이트
	_update_skin_list()

## /** 인벤토리 UI를 표시한다
##  * @returns void
##  */
func _show_inventory() -> void:
	# 상점 UI 숨김
	if background:
		background.visible = false
	if title:
		title.visible = false
	if money_label:
		money_label.visible = false
	if scroll_container:
		scroll_container.visible = false
	if close_button:
		close_button.visible = false
	if inventory_button:
		inventory_button.visible = false
	
	# 인벤토리 표시
	if inventory_panel:
		inventory_panel.visible = true
		_update_inventory()

## /** 인벤토리를 업데이트한다
##  * @returns void
##  */
func _update_inventory() -> void:
	if not sprite1_grid or not sprite2_grid:
		return
	
	# 기존 아이템 제거
	for child in sprite1_grid.get_children():
		child.queue_free()
	for child in sprite2_grid.get_children():
		child.queue_free()
	
	# 소유한 스킨들을 타입별로 분류하여 표시
	for skin_id in Globals.owned_skins:
		if not Globals.available_skins.has(skin_id):
			continue
		
		var skin: SkinItem = Globals.available_skins[skin_id]
		var item = _create_inventory_item(skin)
		
		if skin.target_sprite == 1:
			sprite1_grid.add_child(item)
		else:
			sprite2_grid.add_child(item)

## /** 인벤토리 아이템 UI를 생성한다
##  * @param skin SkinItem 스킨 데이터
##  * @returns Control 생성된 인벤토리 아이템
##  */
func _create_inventory_item(skin: SkinItem) -> Control:
	# 버튼으로 감싸서 클릭 가능하게
	var button = Button.new()
	button.custom_minimum_size = Vector2(INVENTORY_ITEM_SIZE, INVENTORY_ITEM_SIZE)
	button.tooltip_text = skin.name
	
	# 현재 적용된 스킨인지 확인
	var is_current = false
	if skin.target_sprite == 1:
		is_current = (Globals.current_sprite1_skin == skin.id)
	else:
		is_current = (Globals.current_sprite2_skin == skin.id)
	
	# 스타일 설정
	var style = StyleBoxFlat.new()
	if is_current:
		# 적용된 스킨은 노란색 테두리
		style.bg_color = Color(0.3, 0.3, 0.35, 1.0)
		style.border_color = Color(1.0, 0.8, 0.2, 1.0)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
	else:
		style.bg_color = Color(0.2, 0.2, 0.25, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	
	# 텍스처 이미지 추가
	if skin.texture:
		var tex_rect = TextureRect.new()
		tex_rect.texture = skin.texture
		tex_rect.custom_minimum_size = Vector2(INVENTORY_ITEM_SIZE - 8, INVENTORY_ITEM_SIZE - 8)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.anchors_preset = Control.PRESET_CENTER
		tex_rect.position = Vector2(4, 4)
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(tex_rect)
	else:
		# 텍스처가 없으면 기본 아이콘 표시
		button.text = Globals.get_text("SHOP DEFAULT")
		button.add_theme_font_size_override("font_size", 10)
	
	# 클릭 시 스킨 적용
	button.pressed.connect(_on_inventory_item_clicked.bind(skin.id))
	
	return button

## /** 인벤토리 아이템 클릭 핸들러
##  * @param skin_id String 클릭한 스킨 ID
##  * @returns void
##  */
func _on_inventory_item_clicked(skin_id: String) -> void:
	if Globals.apply_skin(skin_id):
		_update_inventory()
		_update_skin_list()
