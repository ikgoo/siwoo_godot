extends Control

@onready var v_box_container = $ScrollContainer/VBoxContainer

## material_banner 씬 프리로드
const MATERIAL_BANNER = preload("res://material_banner.tscn")

## 각 making_note의 UI 배너를 저장하는 딕셔너리 {making_note 인스턴스: material_banner 인스턴스}
var note_banners : Dictionary = {}

## 이전 버전과의 호환성을 위한 변수들 (사용되지 않음)
var current_resipis : resipi = null
var contributed_materials : Dictionary = {}


## 노드가 씬 트리에 추가될 때 호출
func _ready():
	# 초기에는 UI를 숨김
	visible = false


## UI가 표시될 때 호출 - 초기 배너 생성
func show_ui():
	visible = true
	update_all_banners()


## UI가 숨겨질 때 호출
func hide_ui():
	visible = false


## 매 프레임 호출 - Area에 변화가 있을 때만 업데이트
func _process(_delta):
	# UI가 열려있을 때만 체크
	if visible:
		# nearby_making_notes의 변화가 있는지 확인
		check_and_update_banners()


## 변화가 있는지 체크하고 필요할 때만 업데이트
func check_and_update_banners():
	var nearby_notes = Globals.nearby_making_notes
	
	# 배너에 있지만 무효화된 note가 있는지 확인
	for note in note_banners.keys():
		if note == null or not is_instance_valid(note):
			update_all_banners()
			return
	
	# 배너 개수가 달라지면 업데이트 필요
	if note_banners.size() != nearby_notes.size():
		update_all_banners()
		return
	
	# 배너에 없는 note가 있으면 업데이트 필요
	for note in nearby_notes:
		if not note_banners.has(note):
			update_all_banners()
			return


## 모든 활성 making_note들의 UI 배너를 업데이트하는 함수
func update_all_banners():
	# Area에 들어간 making_note들만 가져오기 (플레이어 근처)
	var nearby_notes = Globals.nearby_making_notes
	
	# 제거된 making_note의 배너 삭제
	var notes_to_remove = []
	for note in note_banners.keys():
		# note가 null이거나, 유효하지 않거나, nearby_notes에 없으면 제거 대상
		if note == null or not is_instance_valid(note) or not nearby_notes.has(note):
			notes_to_remove.append(note)
	
	for note in notes_to_remove:
		if note != null:  # null이 아닐 때만 remove_banner 호출
			remove_banner(note)
		else:
			# null인 경우 딕셔너리에서만 제거
			note_banners.erase(note)
	
	# 새로 추가된 making_note의 배너 생성 (Area에 들어간 것만)
	for note in nearby_notes:
		if not note_banners.has(note):
			create_banner(note)


## 특정 making_note의 배너를 생성하는 함수
func create_banner(note: Node3D):
	if not note or not note.thing or not note.resipis:
		return
	
	# material_banner 인스턴스 생성
	var banner = MATERIAL_BANNER.instantiate()
	
	# 건물 이름 레이블 추가 (배너 중앙에 표시)
	var name_label = Label.new()
	name_label.text = note.thing.name if note.thing else "알 수 없음"
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.position = Vector2(10, 8)
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.add_child(name_label)
	
	# VBoxContainer에 추가 (먼저 씬 트리에 추가)
	# Control 래퍼로 감싸서 VBoxContainer에 추가 (Node2D는 직접 추가 불가)
	var wrapper = Control.new()
	wrapper.custom_minimum_size = Vector2(0, 50)  # 최소 높이 설정 (배너 + 여백)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(banner)
	
	v_box_container.add_child(wrapper)
	
	# 딕셔너리에 저장
	note_banners[note] = banner
	
	# 씬 트리에 추가된 후 재료 정보 업데이트
	await get_tree().process_frame
	banner.update_materials(note)
	
	print("배너 생성됨: ", note.thing.name)


## 특정 배너의 재료 정보를 갱신하는 함수
func refresh_banner(note: Node3D):
	if not note_banners.has(note):
		return
	
	var banner = note_banners[note]
	if banner and is_instance_valid(banner):
		banner.update_materials(note)


## 특정 making_note의 배너를 제거하는 함수
func remove_banner(note: Node3D):
	if not note_banners.has(note):
		return
	
	var banner = note_banners[note]
	if banner and is_instance_valid(banner):
		# 배너가 펼쳐져 있으면 즉시 접기
		if banner.is_expanded:
			banner.collapse_immediate()  # 즉시 접기 (애니메이션 없이)
		
		# 건물 스프라이트 색상 원래대로 복원 (note가 유효한 경우만)
		if is_instance_valid(note) and note.has_node("Sprite3D"):
			var sprite_3d = note.get_node("Sprite3D")
			if sprite_3d and is_instance_valid(sprite_3d):
				sprite_3d.modulate = Color(0.0, 1.0, 1.0, 1.0)  # 청록색(원래 색)
		
		# 래퍼도 함께 제거
		var wrapper = banner.get_parent()
		if wrapper:
			wrapper.queue_free()
	
	note_banners.erase(note)
	print("배너 제거됨 - 색상 및 상태 복원")


## 모든 배너를 제거하는 함수
func clear_all_banners():
	for note in note_banners.keys():
		remove_banner(note)
	
	note_banners.clear()
	print("모든 배너 제거됨")


## 이전 버전과의 호환성을 위한 함수 - clear_all_banners()와 동일
func clear_materials():
	clear_all_banners()


## 이전 버전과의 호환성을 위한 함수 - 새 아코디언 스타일에서는 자동 업데이트됨
func update_materials(resipis_data: resipi, saved_materials: Dictionary = {}):
	# 호환성을 위해 변수만 저장 (실제로는 _process에서 자동 업데이트됨)
	current_resipis = resipis_data
	if not saved_materials.is_empty():
		contributed_materials = saved_materials.duplicate()
	print("update_materials 호출됨 (material_banner 스타일에서는 자동 업데이트)")
