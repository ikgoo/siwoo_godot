extends Node2D

# 별이 생성될 전체 영역 정의
const MIN_X = 55
const MAX_X = 765
const MIN_Y = 23.5
const MAX_Y = 311

# 별자리 영역을 정의 (이 영역은 피할 영역)
const CONSTELLATION_MIN_X = 250
const CONSTELLATION_MAX_X = 500
const CONSTELLATION_MIN_Y = 100
const CONSTELLATION_MAX_Y = 250
const AVOID_PADDING = 30
const CLICK_DISTANCE = 10.0  # 클릭 감지 최대 거리
const MIN_STAR_DISTANCE = 20.0  # 별들 사이의 최소 거리
const MIN_LINE_DISTANCE = 30.0  # 선으로부터의 최소 거리

var clicked_named_stars = []  # 클릭한 네임드 별들을 저장할 배열
var named_stars = []  # 모든 네임드 별들을 저장할 배열
var placed_positions = []  # 배치된 별들의 위치를 저장할 배열

# 선과 관련된 별들의 매핑
var line_star_pairs = {
	"fir_plus_seo": ["1", "2"],
	"seo_plus_third": ["2", "3"],
	"third_plus_four": ["3", "4"],
	"four_plus_five": ["4", "5"],
	"five_plus_six": ["5", "6"],
	"six_plus_seven": ["6", "7"],
	"seven_plus_eight": ["7", "8"],
	"eight_plus_nine": ["8", "9"],
	"nine_plus_ten": ["9", "10"],
	"ten_plus_eleven": ["10", "11"],
	"nine_plus_twelve": ["9", "12"],
	"twelve_plus_thirteen": ["12", "13"]
}

func _ready():
	randomize()
	
	# 모든 선을 처음에 숨김
	for line_name in line_star_pairs:
		var line = get_node_or_null(line_name)
		if line:
			line.visible = false
			line.width = 1.0
	
	var line_segments = []  # 선들의 시작점과 끝점을 저장
	
	# 네임드 별들을 회색으로 설정하고 배열에 저장
	for child in get_children():
		if child is Sprite2D and child.name.is_valid_int():
			named_stars.append(child)
			placed_positions.append(child.position)
		elif child is Line2D:
			# 선의 모든 점들을 세그먼트로 저장
			for i in range(child.points.size() - 1):
				line_segments.append([child.points[i], child.points[i + 1]])
	
	# 일반 별들 랜덤 배치 및 회색으로 설정
	var normal_stars = $Node2D
	if normal_stars:
		for star in normal_stars.get_children():
			if star is Sprite2D:
				var valid_position = false
				var new_pos = Vector2.ZERO
				var attempts = 0
				
				while not valid_position and attempts < 50:
					new_pos = Vector2(
						randf_range(MIN_X, MAX_X),  # 전체 영역에서 랜덤 생성
						randf_range(MIN_Y, MAX_Y)
					)
					
					valid_position = true
					
					# 별자리 영역에 있으면 위치 무효화
					if is_in_constellation_area(new_pos):
						valid_position = false
						continue
					
					# 다른 별들과의 거리 체크
					for pos in placed_positions:
						if new_pos.distance_to(pos) < MIN_STAR_DISTANCE:
							valid_position = false
							break
					
					attempts += 1
				
				if valid_position:
					star.position = new_pos
					star.modulate = Color(1, 1, 1, 1)
					placed_positions.append(new_pos)

func _input(event):
	if not is_visible_in_tree():
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_local_mouse_position()
		var closest_star = null
		var closest_distance = INF
		
		# 네임드 별들 검사
		for star in named_stars:
			var distance = click_pos.distance_to(star.position)
			if distance < closest_distance:
				closest_distance = distance
				closest_star = star
		
		# 일반 별들 검사
		var normal_stars = $Node2D
		if normal_stars:
			for star in normal_stars.get_children():
				if star is Sprite2D:
					var distance = click_pos.distance_to(star.position)
					if distance < closest_distance:
						closest_distance = distance
						closest_star = star
		
		# 가장 가까운 별이 있고, 거리가 10 이내면 처리
		if closest_star and closest_distance <= CLICK_DISTANCE:
			if closest_star.name.is_valid_int():  # 네임드 별인 경우
				var parent = get_parent()
				var cost = parent.constellation_info[parent.current_constellation]["cost"]
				
				if Gamemaneger.stardust >= cost:  # 스타더스트가 충분한 경우에만
					Gamemaneger.stardust -= cost  # 매번 스타더스트 차감
					if not closest_star.modulate.is_equal_approx(Color(1, 1, 2, 1)):
						closest_star.modulate = Color(1, 1, 2, 1)  # 파란색
						clicked_named_stars.append(closest_star)
						Main.tting(clicked_named_stars.size(), named_stars.size())
						check_lines_visibility()
			else:  # 일반 별인 경우
				var parent = get_parent()
				var cost = parent.constellation_info[parent.current_constellation]["cost"]
				
				if Gamemaneger.stardust >= cost:  # 스타더스트가 충분한 경우에만
					Gamemaneger.stardust -= cost  # 스타더스트 차감
					closest_star.modulate = Color(1, 0, 0, 1)  # 빨간색
					Gamemaneger.stardust += Gamemaneger.get_collect_amount()  # 현재 수집량만큼 스타더스트 증가

func check_lines_visibility():
	for line_name in line_star_pairs:
		var line = get_node_or_null(line_name)
		if line:
			var star_names = line_star_pairs[line_name]
			var all_stars_clicked = true
			
			for star_name in star_names:
				var star_clicked = false
				for clicked_star in clicked_named_stars:
					if clicked_star.name == star_name:
						star_clicked = true
						break
				if not star_clicked:
					all_stars_clicked = false
					break
			
			line.visible = all_stars_clicked

# 점과 선분 사이의 최단 거리를 계산하는 함수
func get_distance_to_line_segment(point, segment_start, segment_end):
	var A = point - segment_start
	var B = segment_end - segment_start
	var dot = A.dot(B)
	if dot < 0:
		return A.length()
	var length_sq = B.length_squared()
	if dot > length_sq:
		return (point - segment_end).length()
	var proj = dot / length_sq
	return (A - B * proj).length()

func get_total_named_stars() -> int:
	return named_stars.size()

func _on_animation_finished(anim_name: String):
	Gamemaneger.stardust += 450  # 물병자리는 450 스타더스트

func is_in_constellation_area(pos: Vector2) -> bool:
	return (pos.x > CONSTELLATION_MIN_X - AVOID_PADDING and 
			pos.x < CONSTELLATION_MAX_X + AVOID_PADDING and 
			pos.y > CONSTELLATION_MIN_Y - AVOID_PADDING and 
			pos.y < CONSTELLATION_MAX_Y + AVOID_PADDING)
