extends Node2D

var current_target: Node2D = null
const MOVE_SPEED = 30.0  # 고정된 이동 속도
const COLLECT_DISTANCE = 10.0  # 별을 수집할 수 있는 거리

func _ready():
	find_closest_star()

func _process(delta):
	if current_target and is_instance_valid(current_target):
		var direction = (current_target.global_position - global_position).normalized()
		var distance = global_position.distance_to(current_target.global_position)
		
		if distance < COLLECT_DISTANCE:
			collect_star(current_target)
			find_closest_star()
			return
		
		# 현재 속도 레벨에 따른 이동
		global_position += direction * Gamemaneger.get_current_speed() * delta
	else:
		find_closest_star()

func find_closest_star():
	var available_stars = Gamemaneger.get_available_stars()
	var closest_distance = INF
	var closest_star = null
	
	for star in available_stars:
		var distance = global_position.distance_to(star.global_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_star = star
	
	if closest_star:
		current_target = closest_star
		Gamemaneger.remove_star(closest_star)  # 타겟으로 정한 별은 목록에서 제거

func collect_star(star: Node2D):
	if star.has_method("collect"):
		star.collect()
