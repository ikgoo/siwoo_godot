extends Line2D

@onready var arrow = $".."

@export var max_line : int
var t_points : Array
#트레일 그리기
func line():
	#새 위치
	t_points.push_front(arrow.global_position)
	#너무 많으면 뒤에꺼 하나 지우기
	if len(t_points) > max_line:
		t_points.pop_back()
		
	#새로 그리기 위한 다 지우기
	clear_points()
	#하나씩 그리기
	for i in t_points:
		add_point(i)
		
	
func deleting():
	t_points.pop_back()
		
	clear_points()

	for i in t_points:
		add_point(i)
