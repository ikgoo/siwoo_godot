extends Node2D

var current_constellation = 0  # 현재 보여지는 별자리 인덱스
@onready var for_see = $for_see
@onready var for_see2 = $for_see2
@onready var for_see3 = $for_see3
@onready var for_see4 = $for_see4
@onready var for_see5 = $for_see5
@onready var for_see6 = $for_see6
@onready var thing = $thing
@onready var detail_panel = $detail_p
@onready var detail_label = $detail_l

# 별자리 정보를 딕셔너리로 저장
var constellation_info = {
	0: {"name": "작은곰자리", "node": "for_see2"},
	1: {"name": "천칭자리", "node": "for_see"},
	2: {"name": "게자리", "node": "for_see3"},
	3: {"name": "물병자리", "node": "for_see4"},
	4: {"name": "양자리", "node": "for_see5"},
	5: {"name": "황소자리", "node": "for_see6"}
}

var constellation_details = {
	0: """
작은곰자리: 밤하늘에서 가장 식별하기 쉬운 별자리입니다. 북쪽 하늘에 항상 떠있는 북극성이 꼬리 끝에 위치해 있으며, 고대부터 방향을 찾는 중요한 이정표 역할을 해왔습니다. 특히 항해를 하는 사람들에게는 필수적인 존재였으며, 밤하늘의 중심점 역할을 하고 있습니다. 7개의 주요 별들이 뚜렷하게 보여 쉽게 찾을 수 있습니다.""",
	1: """
천칭자리: 하늘의 저울로 알려진 별자리입니다. 그리스에서는 공정함을 상징하는 여신의 저울로 여겨졌으며, 가을철 밤하늘에서 선명한 저울 형상을 관측할 수 있습니다. 별자리를 구성하는 주요 별들은 저울의 양팔을 형상화하고 있으며, 균형과 조화를 상징하는 의미를 담고 있습니다. 가을의 시작을 알리는 역할도 합니다.""",
	2: """
게자리: 여름철 밤하늘에서 관측되는 게 형상의 별자리입니다. 별들이 게의 집게발과 몸통을 형상화하고 있으며, 중심부에는 수많은 별들이 모여 있어 독특한 광경을 연출합니다. 맑은 날 밤하늘에서는 흐릿한 구름처럼 보이는 성단도 관측할 수 있습니다. 여름철 별자리 중에서도 특히 찾기 쉬운 별자리로 알려져 있습니다.""",
	3: """
물병자리: 겨울 밤하늘을 수놓는 특징적인 별자리입니다. 상단의 뿔과 하단의 물고기 꼬리 형상이 독특한 모습을 보여주며, 겨울을 대표하는 별자리로 알려져 있습니다. 12월 말경에 가장 잘 관측할 수 있으며, 겨울철 밤하늘에서 독특한 형태로 쉽게 구별할 수 있습니다. 그리스 신화에서는 바다의 신 포세이돈과 관련된 이야기도 전해지고 있습니다.""",
	4: """
양자리: 봄의 대표 별자리로 하늘의 양으로 불립니다. 고대 그리스의 전설 속 금빛 양이 위기에 처한 남매를 구하고 별이 되었다는 이야기가 전해집니다. 봄철 저녁 하늘에서 가장 잘 관측되며, 별자리를 구성하는 별들이 양의 뿔과 몸체를 표현하고 있습니다. 봄의 시작을 알리는 상징적인 별자리이기도 합니다.""",
	5: """
황소자리: 겨울철을 대표하는 별자리 중 하나입니다. 밝은 주황색 별이 황소의 눈을 표현하고 있으며, 주변의 별들과 어우러져 겨울 밤하늘의 장관을 선사합니다. 이 밝은 별은 알데바란이라고 하며, 겨울철 밤하늘에서 가장 눈에 띄는 별 중 하나입니다. 신화에서는 제우스가 아름다운 공주를 만나기 위해 황소로 변신한 이야기가 전해져 옵니다."""
}

# 완성된 별자리만 보여주기 위한 함수
func get_next_completed_constellation(current_index: int, direction: int) -> int:
	var size = constellation_info.size()
	var index = current_index
	
	for i in range(size):
		index = (index + direction) % size
		if index < 0:
			index = size - 1
		# bbul_set의 completed_constellations 배열 확인
		if get_parent().get_node("Node2D").completed_constellations[index]:
			return index
	
	return current_index

func _ready():
	hide_all_constellations()
	show_constellation(0)
	# 초기에는 패널과 라벨 숨기기
	detail_panel.visible = false
	detail_label.visible = false

func hide_all_constellations():
	for_see.visible = false
	for_see2.visible = false
	for_see3.visible = false
	for_see4.visible = false
	for_see5.visible = false
	for_see6.visible = false

func show_constellation(index):
	hide_all_constellations()
	var node_name = constellation_info[index]["node"]
	var node = get_node(node_name)
	
	# 별자리가 완성되었는지 확인
	if get_parent().get_node("Node2D").completed_constellations[index]:
		# 완성된 별자리는 보이게
		node.visible = true
		thing.text = constellation_info[index]["name"]
	else:
		# 미완성 별자리는 숨기고 "잠금됨" 표시
		node.visible = false
		thing.text = "???"

func _on_left_button_down():
	var new_index = (current_constellation - 1)
	if new_index < 0:
		new_index = constellation_info.size() - 1
	current_constellation = new_index
	show_constellation(new_index)

func _on_right_button_down():
	var new_index = (current_constellation + 1) % constellation_info.size()
	current_constellation = new_index
	show_constellation(new_index)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_detail_b_button_down():
	# 현재 별자리가 완성되었는지 확인
	if get_parent().get_node("Node2D").completed_constellations[current_constellation]:
		# 완성된 별자리만 정보 표시
		detail_panel.visible = true
		detail_label.visible = true
		# 줄바꿈을 더 추가하여 텍스트가 잘 보이도록 조정
		detail_label.text = "\n" + constellation_details[current_constellation]
	else:
		# 미완성 별자리는 "???" 표시
		detail_panel.visible = true
		detail_label.visible = true
		detail_label.text = "\n\n\n이 별자리는 아직 발견되지 않았습니다."

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if detail_panel.visible:
			detail_panel.visible = false
			detail_label.visible = false
