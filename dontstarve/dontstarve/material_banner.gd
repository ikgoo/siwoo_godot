extends Node2D

@onready var v_box_container = $VBoxContainer
@onready var button = $Button
@onready var nine_patch_rect = $NinePatchRect

## 이 배너가 표시하는 making_note 참조
var target_note : Node3D = null

## 펼쳐진 상태인지 여부
var is_expanded : bool = false

## 기본 높이 (접힌 상태)
const COLLAPSED_HEIGHT : float = 40.0

## 재료 아이템 하나당 높이
@export var item_height : float = 50.0

## 재료 아이템 이미지 크기
@export var item_icon_size : Vector2 = Vector2(40, 40)

## 재료 넣기 버튼 크기
@export var put_button_size : Vector2 = Vector2(50, 30)

## 재료 텍스트 폰트 크기
@export var item_text_font_size : int = 16

## 버튼 텍스트 폰트 크기
@export var button_text_font_size : int = 14

## 재료 아이템 전체 위치 오프셋 (HBoxContainer 기준)
@export var item_position_offset : Vector2 = Vector2(0, 0)

## 아이콘 위치 오프셋
@export var icon_position_offset : Vector2 = Vector2(0, 0)

## 텍스트 위치 오프셋
@export var text_position_offset : Vector2 = Vector2(0, 0)

## 버튼 위치 오프셋
@export var button_position_offset : Vector2 = Vector2(0, 0)

## 최대 높이 (스크롤 시작)
const MAX_HEIGHT : float = 300.0


## 노드가 씬 트리에 추가될 때 호출
func _ready():
	# 초기 상태: 접힌 상태
	collapse_immediate()


## 재료 정보를 업데이트하는 함수
func update_materials(note: Node3D):
	if not note or not note.resipis:
		return
	
	# 노드가 준비되지 않았으면 종료
	if not is_node_ready():
		return
	
	target_note = note
	
	# 기존 재료 아이템들 제거
	clear_materials()
	
	# 새로운 재료 아이템들 추가
	for needed_item in note.resipis.item_need:
		create_material_item(needed_item)


## 기존 재료 아이템들을 제거하는 함수
func clear_materials():
	# 노드가 준비되지 않았으면 종료
	if not is_node_ready():
		return
	
	if not v_box_container:
		return
	
	for child in v_box_container.get_children():
		if child and is_instance_valid(child):
			child.queue_free()


## 단일 재료 아이템 UI를 생성하는 함수
func create_material_item(needed_item: resipi_resorce):
	if not needed_item or not needed_item.r_item or not target_note:
		return
	
	# 노드가 준비되지 않았으면 종료
	if not is_node_ready() or not v_box_container:
		return
	
	# HBoxContainer 생성
	var h_box = HBoxContainer.new()
	h_box.custom_minimum_size = Vector2(0, item_height)
	h_box.position = item_position_offset
	
	# 아이템 이미지를 Control로 감싸기
	var icon_wrapper = Control.new()
	icon_wrapper.custom_minimum_size = item_icon_size
	var texture_rect = TextureRect.new()
	texture_rect.texture = needed_item.r_item.img
	texture_rect.custom_minimum_size = item_icon_size
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_rect.position = icon_position_offset
	icon_wrapper.add_child(texture_rect)
	
	# 아이템 이름
	var item_name = needed_item.r_item.name
	
	# 투입된 재료 개수 가져오기
	var contributed_count = target_note.contributed_materials.get(item_name, 0)
	var required_count = needed_item.count
	
	# 아이템 이름과 개수 Label을 Control로 감싸기
	var label_wrapper = Control.new()
	label_wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label = Label.new()
	label.text = item_name + " " + str(contributed_count) + "/" + str(required_count)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", item_text_font_size)
	label.position = text_position_offset
	
	# 재료가 충분한지에 따라 색상 설정
	if contributed_count >= required_count:
		label.modulate = Color.GREEN
	else:
		label.modulate = Color.WHITE
	
	label_wrapper.add_child(label)
	
	# "넣기" 버튼을 Control로 감싸기
	var button_wrapper = Control.new()
	button_wrapper.custom_minimum_size = put_button_size
	var put_button = Button.new()
	put_button.text = "넣기"
	put_button.custom_minimum_size = put_button_size
	put_button.add_theme_font_size_override("font_size", button_text_font_size)
	put_button.position = button_position_offset
	
	# 버튼 클릭 시 재료 투입
	put_button.pressed.connect(_on_put_button_pressed.bind(needed_item))
	
	# 이미 충족된 재료라면 버튼 비활성화
	if contributed_count >= required_count:
		put_button.disabled = true
	
	button_wrapper.add_child(put_button)
	
	# HBoxContainer에 추가
	h_box.add_child(icon_wrapper)
	h_box.add_child(label_wrapper)
	h_box.add_child(button_wrapper)
	
	# VBoxContainer에 추가
	v_box_container.add_child(h_box)


## "넣기" 버튼 클릭 시 호출되는 함수
func _on_put_button_pressed(needed_item: resipi_resorce):
	if not target_note or not needed_item:
		return
	
	var item_name = needed_item.r_item.name
	var required_count = needed_item.count
	var contributed_count = target_note.contributed_materials.get(item_name, 0)
	
	# 이미 충족된 재료라면 무시
	if contributed_count >= required_count:
		print("재료가 이미 충족되었습니다: ", item_name)
		return
	
	# 인벤토리에서 필요한 만큼 꺼내기
	var remaining_needed = required_count - contributed_count
	var inventory_count = InventoryManeger.get_item_count_in_inventory(needed_item.r_item)
	var to_contribute = min(remaining_needed, inventory_count)
	
	if to_contribute <= 0:
		print("인벤토리에 ", item_name, "이(가) 없습니다")
		return
	
	# 인벤토리에서 아이템 제거
	var removed_count = InventoryManeger.remove_item_from_inventory(needed_item.r_item, to_contribute)
	
	if removed_count > 0:
		# 투입된 재료 개수 업데이트
		target_note.contributed_materials[item_name] = target_note.contributed_materials.get(item_name, 0) + removed_count
		
		print("재료 투입: ", item_name, " x", removed_count)
		
		# UI 갱신
		update_materials(target_note)
		
		# 모든 재료가 충족되었는지 확인
		check_all_materials_satisfied()


## 모든 재료가 충족되었는지 확인하는 함수
func check_all_materials_satisfied():
	if not target_note or not target_note.resipis:
		return
	
	# 모든 재료가 충족되었는지 확인
	for needed_item in target_note.resipis.item_need:
		var item_name = needed_item.r_item.name
		var required_count = needed_item.count
		var contributed_count = target_note.contributed_materials.get(item_name, 0)
		
		if contributed_count < required_count:
			return
	
	# 모든 재료가 충족됨
	print("모든 재료가 충족되었습니다! 건물 완성: ", target_note.thing.name if target_note.thing else "없음")
	
	# making_note 참조를 임시 저장
	var note_to_complete = target_note
	var recipe_to_complete = target_note.resipis
	
	# 완성 처리하기 전에 먼저 배너를 제거 (순서 중요!)
	var making_need = get_tree().current_scene.get_node_or_null("CanvasLayer/making_need")
	if not making_need:
		# 다른 경로 시도
		making_need = get_tree().root.find_child("making_need", true, false)
	
	if making_need and making_need.has_method("remove_banner"):
		# making_note가 해제되기 전에 배너 먼저 제거
		making_need.remove_banner(note_to_complete)
	
	# 배너를 제거한 후 making_note의 완성 처리 호출
	if note_to_complete.has_method("_on_all_materials_satisfied"):
		note_to_complete._on_all_materials_satisfied(recipe_to_complete)


## 버튼 클릭 시 펼치기/접기 토글
func _on_button_button_down():
	toggle_expansion()


func _on_button_button_up():
	pass


## 펼치기/접기 토글 함수
func toggle_expansion():
	if is_expanded:
		collapse()
	else:
		expand()


## 펼치는 함수 (애니메이션)
func expand():
	if is_expanded:
		return
	
	is_expanded = true
	
	# 필요한 높이 계산
	var material_count = v_box_container.get_child_count()
	var content_height = material_count * item_height
	var total_height = COLLAPSED_HEIGHT + content_height
	
	# VBoxContainer 위치 및 크기 설정 (헤더 아래에 표시)
	v_box_container.position.y = COLLAPSED_HEIGHT
	v_box_container.custom_minimum_size = Vector2(nine_patch_rect.size.x - 4, content_height)
	
	# VBoxContainer의 z_index를 0으로 (오버레이 안 됨)
	v_box_container.z_index = 0
	
	# 애니메이션으로 부드럽게 펼침
	var tween = create_tween()
	tween.set_parallel(true)
	
	# VBoxContainer 표시
	v_box_container.modulate.a = 0.0
	v_box_container.visible = true
	tween.tween_property(v_box_container, "modulate:a", 1.0, 0.2).set_delay(0.1)
	
	# 부모 wrapper의 크기를 증가시켜서 아래 배너들을 밀어냄
	var parent_wrapper = get_parent()
	if parent_wrapper is Control:
		tween.tween_property(parent_wrapper, "custom_minimum_size:y", total_height, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# NinePatchRect를 주황색으로 변경 (강조)
	if nine_patch_rect:
		tween.tween_property(nine_patch_rect, "modulate", Color(1.0, 0.7, 0.3, 1.0), 0.2)  # 주황색
	
	# 실제 건물(making_note)의 스프라이트도 주황색으로 강조
	if target_note and target_note.has_node("Sprite3D"):
		var sprite_3d = target_note.get_node("Sprite3D")
		tween.tween_property(sprite_3d, "modulate", Color(1.0, 0.7, 0.3, 1.0), 0.2)  # 주황색
	
	print("배너 펼침: ", target_note.thing.name if target_note and target_note.thing else "없음", " - 총 높이: ", total_height)


## 접는 함수 (애니메이션)
func collapse():
	if not is_expanded:
		return
	
	is_expanded = false
	
	# 애니메이션으로 부드럽게 접음
	var tween = create_tween()
	tween.set_parallel(true)
	
	# VBoxContainer 숨김
	tween.tween_property(v_box_container, "modulate:a", 0.0, 0.2)
	
	# 부모 wrapper의 크기를 복원하여 아래 배너들을 위로 당김
	var parent_wrapper = get_parent()
	if parent_wrapper is Control:
		tween.tween_property(parent_wrapper, "custom_minimum_size:y", 50, 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	
	# NinePatchRect를 원래 색으로 복원
	if nine_patch_rect:
		tween.tween_property(nine_patch_rect, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)  # 흰색(원래 색)
	
	# 실제 건물(making_note)의 스프라이트도 원래 색으로 복원
	if target_note and target_note.has_node("Sprite3D"):
		var sprite_3d = target_note.get_node("Sprite3D")
		tween.tween_property(sprite_3d, "modulate", Color(0.0, 1.0, 1.0, 1.0), 0.2)  # 청록색(원래 색)
	
	# 애니메이션 완료 후 VBoxContainer 숨김
	tween.tween_callback(func(): 
		v_box_container.visible = false
	).set_delay(0.2)
	
	print("배너 접음: ", target_note.thing.name if target_note and target_note.thing else "없음")


## 즉시 접기 (애니메이션 없음)
func collapse_immediate():
	is_expanded = false
	if nine_patch_rect:
		nine_patch_rect.size.y = COLLAPSED_HEIGHT
		nine_patch_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)  # 흰색(원래 색)
	if v_box_container:
		v_box_container.visible = false
		v_box_container.modulate.a = 0.0
		v_box_container.z_index = 0
	
	# 부모 wrapper 크기도 복원
	var parent_wrapper = get_parent()
	if parent_wrapper is Control:
		parent_wrapper.custom_minimum_size.y = 50
	
	# 건물 스프라이트 색상도 복원
	if target_note and target_note.has_node("Sprite3D"):
		var sprite_3d = target_note.get_node("Sprite3D")
		sprite_3d.modulate = Color(0.0, 1.0, 1.0, 1.0)  # 청록색(원래 색)
