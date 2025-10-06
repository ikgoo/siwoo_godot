extends Control

@export var item_make : resipi
@onready var item_texture_rect : TextureRect = $TextureRect/TextureRect
var is_mouse = false
var item_maker_view_node # item_maker_veiw 노드를 참조할 변수
func _ready():
	update_item_image()
	# item_maker_veiw 노드를 찾아서 참조 저장
	find_item_maker_view()
func set_recipe(recipe: resipi) -> void:
	item_make = recipe
	update_item_image()

func update_item_image() -> void:
	if item_make and item_make.end_tem and item_make.end_tem.img:
		item_texture_rect.texture = item_make.end_tem.img
	else:
		# 레시피가 없거나 완성 아이템이 없을 때는 텍스처를 비웁니다
		item_texture_rect.texture = null

func get_recipe() -> resipi:
	return item_make

func clear_recipe() -> void:
	item_make = null
	item_texture_rect.texture = null

# 사용 예시:
# var recipe_resource = preload("res://resipi/chiken_winner.tres")
# maker_slot.set_recipe(recipe_resource)  # 치킨 위너 레시피 설정 시 완성품 이미지가 표시됨



func _on_area_2d_mouse_entered():
	is_mouse = true


func _on_area_2d_mouse_exited():
	is_mouse = false

# item_maker_veiw 노드를 찾는 함수
func find_item_maker_view():
	# 정확한 경로로 item_maker_veiw 노드를 찾음
	item_maker_view_node = get_parent().get_parent().get_parent().item_maker_veiw
	if item_maker_view_node:
		print("item_maker_veiw 노드를 찾았습니다!")
	else:
		print("item_maker_veiw 노드를 찾을 수 없습니다")

# UI 요소에서 마우스 클릭을 감지하는 함수
func _gui_input(event):
	# 마우스 왼쪽 버튼이 클릭되었을 때
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			on_slot_clicked()
			# 이벤트를 소비해서 다른 시스템(이동 등)으로 전달되지 않게 함
			accept_event()

# 슬롯이 클릭되었을 때 실행되는 함수
func on_slot_clicked():
	print("maker_item_slot이 클릭되었습니다!")
	
	# 레시피가 있고 item_maker_view 노드가 존재할 때
	if item_make and item_maker_view_node:
		# item_maker_veiw의 now_veiwing을 현재 슬롯의 레시피로 설정
		item_maker_view_node.now_veiwing = item_make
		# 뷰 업데이트
		item_maker_view_node.veiwing()
		print("레시피가 veiw에 표시되었습니다: ", item_make.end_tem.name)
	else:
		if not item_make:
			print("이 슬롯에는 레시피가 없습니다")
		if not item_maker_view_node:
			print("item_maker_veiw 노드를 찾을 수 없습니다")
