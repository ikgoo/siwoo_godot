extends Control

@onready var v_box_container = $ScrollContainer/VBoxContainer

var thing : obsticle
var current_resipis : resipi

## 노드가 씬 트리에 추가될 때 호출
func _ready():
	# 초기에는 UI를 숨김
	visible = false


## 매 프레임 호출 (현재 사용 안 함)
func _process(_delta):
	pass


## 재료 정보를 업데이트하는 함수
## resipis_data: 레시피 데이터 (resipi)
func update_materials(resipis_data: resipi):
	if not resipis_data:
		print("레시피 데이터가 없습니다")
		return
	
	current_resipis = resipis_data
	
	# 기존 재료 아이템들 제거
	clear_materials()
	
	# 새로운 재료 아이템들 추가
	add_material_items()


## 기존 재료 아이템들을 모두 제거하는 함수
func clear_materials():
	if not v_box_container:
		return
	
	# VBoxContainer의 모든 자식 노드 제거
	for child in v_box_container.get_children():
		child.queue_free()


## 재료 아이템들을 VBoxContainer에 추가하는 함수
func add_material_items():
	if not current_resipis or not v_box_container:
		return
	
	# 필요한 재료들을 순회
	for needed_item in current_resipis.item_need:
		# 재료 아이템 UI 생성
		create_material_item(needed_item)


## 단일 재료 아이템 UI를 생성하는 함수
## needed_item: 필요한 재료 정보 (resipi_resorce)
func create_material_item(needed_item: resipi_resorce):
	if not needed_item or not needed_item.r_item:
		return
	
	# HBoxContainer 생성 (이미지와 텍스트를 가로로 배치)
	var h_box = HBoxContainer.new()
	h_box.custom_minimum_size = Vector2(200, 40)
	
	# 아이템 이미지 TextureRect 생성
	var texture_rect = TextureRect.new()
	texture_rect.texture = needed_item.r_item.img
	texture_rect.custom_minimum_size = Vector2(32, 32)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST  # 픽셀 아트 스타일
	
	# 아이템 이름과 개수 Label 생성
	var label = Label.new()
	label.text = needed_item.r_item.name + " x" + str(needed_item.count)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	
	# 인벤토리에 있는 개수 확인
	var current_count = InventoryManeger.get_item_count_in_inventory(needed_item.r_item)
	var required_count = needed_item.count
	
	# 재료가 충분한지에 따라 색상 설정
	if current_count >= required_count:
		label.modulate = Color.WHITE
	else:
		label.modulate = Color.RED
	
	# HBoxContainer에 추가
	h_box.add_child(texture_rect)
	h_box.add_child(label)
	
	# VBoxContainer에 추가
	v_box_container.add_child(h_box)
	
	print("재료 추가됨: ", needed_item.r_item.name, " x", needed_item.count)
