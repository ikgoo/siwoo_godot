extends Node2D
@export var flip : bool
enum upgrade {
	money_up,
	money_time,
	money_randomize,
	mining_tier,  # 채굴 티어 (더 깊은 레이어의 돌을 캘 수 있음)
	auto_mining_speed,  # 자동 채굴 속도 (키 꾹 누르기)
	mining_key_count,  # 채굴 키 개수 증가
	rock_money_up  # 타일 채굴 보너스 (타일 돌 캘 때 추가 돈)
}
@export var type : upgrade

# 현재 업그레이드 단계 (0부터 시작)
var current_level: int = 0

# 랜덤 혼잣말 목록
var monologues_success: Array[String] = [
	"이제 좀 쓸만해졌네",
	"돈이 아깝지 않군",
	"이 정도면 괜찮지?",
	"이제 채굴이 더 쉬워지겠지",
]
@onready var animation_player = $AnimationPlayer

var monologues_fail: Array[String] = [
	"돈이 부족해",
	"아직 못 사네",
	"열심히 더 캐야지",
	"돈이 없다니",
]

var monologues_max: Array[String] = [
	"이미 최고야!",
	"더 이상 못 올려",
	"이미 완벽해졌어",
	"이 이상은 없어",
]

# 업그레이드 타입별 자동 대사 (가끔씩 혼자 말함)
var idle_monologues_money_up: Array[String] = [
	"돌 캐는 건 맡기라고",
	"다이아가 더 나왔으면",
	"한 번에 더 많이",
]

var idle_monologues_money_time: Array[String] = [
	"더 빨리 캘 수 있으면",
	"곡괭이가 좀 느린데",
	"속도가 생명이야",
	"속도를 좀 올려볼까",
]

var idle_monologues_mining_tier: Array[String] = [
	"더 깊이 파고 싶어",
	"아래층엔 뭐가 있을까",
	"더 좋은 광물이 있을 거야",
]

var idle_monologues_auto_mining_speed: Array[String] = [
	"더 빨리 캘 수 있으면",
	"꾹 누르면 편하지",
	"자동 채굴 최고",
]

var idle_monologues_mining_key_count: Array[String] = [
	"손가락이 더 필요해",
	"키가 더 있으면 좋겠는데",
	"더 많이 누를 수 있으면",
	"양손을 다 써야지",
]

var idle_monologues_money_randomize: Array[String] = [
	"운이 좋으면 더 많이",
	"잭팟이 터지려나",
	"대박이 나올 것 같아",
	"오늘은 뭔가 느낌이 좋아",
]

var idle_monologues_rock_money_up: Array[String] = [
	"돌 하나에 더 많이",
	"캘 때마다 보너스가",
	"타일 채굴이 꿀이네",
	"한 번 캘 때 더 벌고 싶어",
]

# 자동 대사 타이머
var idle_monologue_timer: float = randf_range(0.0, 8.0)  # 랜덤 시작으로 동시 출력 방지
var idle_monologue_interval: float = 8.0  # 8초마다 체크
var idle_monologue_chance: float = 0.3  # 30% 확률로 말함

# 현재 업그레이드 단계의 비용 가져오기
func get_current_cost() -> int:
	match type:
		upgrade.money_time:  # 곡괭이 속도 (pv)
			if current_level < Globals.pickaxe_speed_upgrades.size():
				return Globals.pickaxe_speed_upgrades[current_level].x
			else:
				return -1  # MAX
		upgrade.money_up:  # 다이아몬드 획득량 (dv)
			if current_level < Globals.diamond_value_upgrades.size():
				return Globals.diamond_value_upgrades[current_level].x
			else:
				return -1  # MAX
		upgrade.mining_tier:  # 채굴 티어 (mt)
			if current_level < Globals.mining_tier_upgrades.size():
				return Globals.mining_tier_upgrades[current_level].x
			else:
				return -1  # MAX
		upgrade.auto_mining_speed:  # 자동 채굴 속도 (as)
			if current_level < Globals.auto_mining_speed_upgrades.size():
				return int(Globals.auto_mining_speed_upgrades[current_level].x)
			else:
				return -1  # MAX
		upgrade.mining_key_count:  # 채굴 키 개수 (mk)
			if current_level < Globals.mining_key_count_upgrades.size():
				return Globals.mining_key_count_upgrades[current_level].x
			else:
				return -1  # MAX
		upgrade.money_randomize:  # 돈 랜덤 (mr)
			if current_level < Globals.money_randomize_upgrades.size():
				return Globals.money_randomize_upgrades[current_level].x
			else:
				return -1  # MAX
		upgrade.rock_money_up:  # 타일 채굴 보너스 (rm)
			if current_level < Globals.rock_money_upgrades.size():
				return Globals.rock_money_upgrades[current_level].x
			else:
				return -1  # MAX
		_:
			return 0

# 현재 업그레이드 단계의 증가량 가져오기 (표시용)
func get_current_increment() -> int:
	match type:
		upgrade.money_time:  # 곡괭이 속도 (필요 클릭 수)
			if current_level < Globals.pickaxe_speed_upgrades.size():
				return Globals.pickaxe_speed_upgrades[current_level].y
			else:
				return 1  # MAX
		upgrade.money_up:  # 다이아몬드 획득량
			if current_level < Globals.diamond_value_upgrades.size():
				return Globals.diamond_value_upgrades[current_level].y
			else:
				return 1100  # MAX
		upgrade.mining_tier:  # 채굴 티어
			if current_level < Globals.mining_tier_upgrades.size():
				return Globals.mining_tier_upgrades[current_level].y
			else:
				return 10  # MAX
		upgrade.auto_mining_speed:  # 자동 채굴 속도
			return 0  # 간격은 float이라서 별도 처리
		upgrade.mining_key_count:  # 채굴 키 개수
			if current_level < Globals.mining_key_count_upgrades.size():
				return Globals.mining_key_count_upgrades[current_level].y
			else:
				return 4  # MAX
		upgrade.money_randomize:  # 돈 랜덤
			return 0  # 확률은 별도 처리
		upgrade.rock_money_up:  # 타일 채굴 보너스
			if current_level < Globals.rock_money_upgrades.size():
				return Globals.rock_money_upgrades[current_level].y
			else:
				return 50  # MAX
		_:
			return 0

# Area2D 노드 참조
@onready var area_2d = $Area2D2

# 플레이어가 영역 안에 있는지 추적하는 변수
var is_character_inside: bool = false
@onready var animated_sprite_2d = $AnimatedSprite2D

# UI 노드 참조
var ui_node: Control = null

# 시각 효과용 스프라이트 (있다면)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

# 구매 가능 여부 표시용 파티클 (GPU)
@onready var glow_particles: GPUParticles2D = $GlowParticles

func _ready():
	# upgrade 그룹에 추가 (튜토리얼에서 찾을 수 있도록)
	add_to_group("upgrade")
	
	if flip:
		animated_sprite_2d.flip_h = true
	animation_player.play("idle")
	# Area2D의 body_shape_entered/exited 시그널 연결
	if area_2d:
		area_2d.body_shape_entered.connect(_on_area_2d_body_shape_entered)
		area_2d.body_shape_exited.connect(_on_area_2d_body_shape_exited)
	
	# UI 노드 찾기 (CanvasLayer/UI 경로)
	var parent = get_tree().current_scene
	if parent:
		var canvas_layer = parent.get_node_or_null("CanvasLayer")
		if canvas_layer:
			ui_node = canvas_layer.get_node_or_null("UI")
	
	# Globals Signal 구독
	Globals.money_changed.connect(_on_money_changed)

# 업그레이드 정보 텍스트 생성
func get_upgrade_info_text() -> String:
	var cost = get_current_cost()
	
	# MAX 레벨 체크
	var is_max = false
	match type:
		upgrade.money_time:  # 곡괭이 속도
			is_max = (current_level >= Globals.pickaxe_speed_upgrades.size())
		upgrade.money_up:  # 다이아몬드 획득량
			is_max = (current_level >= Globals.diamond_value_upgrades.size())
		upgrade.mining_tier:  # 채굴 티어
			is_max = (current_level >= Globals.mining_tier_upgrades.size())
		upgrade.auto_mining_speed:  # 자동 채굴 속도
			is_max = (current_level >= Globals.auto_mining_speed_upgrades.size())
		upgrade.mining_key_count:  # 채굴 키 개수
			is_max = (current_level >= Globals.mining_key_count_upgrades.size())
		upgrade.money_randomize:  # 돈 랜덤
			is_max = (current_level >= Globals.money_randomize_upgrades.size())
		upgrade.rock_money_up:  # 타일 채굴 보너스
			is_max = (current_level >= Globals.rock_money_upgrades.size())
	
	if is_max or cost == -1:
		return "MAX"
	
	var type_name = ""
	var effect_text = ""
	
	match type:
		upgrade.money_up:
			type_name = "다이아몬드 획득량"
			var new_value = Globals.diamond_value_upgrades[current_level].y
			effect_text = "획득량: %d" % new_value
		upgrade.money_time:
			type_name = "곡괭이 속도"
			var new_clicks = Globals.pickaxe_speed_upgrades[current_level].y
			effect_text = "필요 클릭: %d회" % new_clicks
		upgrade.money_randomize:
			type_name = "돈 랜덤 확률"
			var new_x2 = Globals.money_randomize_upgrades[current_level].y
			var new_x3 = Globals.money_randomize_upgrades[current_level].z
			effect_text = "x2: %d%%, x3: %d%%" % [new_x2, new_x3]
		upgrade.mining_tier:
			type_name = "채굴 티어"
			var new_tier = Globals.mining_tier_upgrades[current_level].y
			effect_text = "티어 %d (layer 1~%d 채굴 가능)" % [new_tier, new_tier]
		upgrade.auto_mining_speed:
			type_name = "자동 채굴 속도"
			var new_interval = Globals.auto_mining_speed_upgrades[current_level].y
			effect_text = "간격: %.2f초" % new_interval
		upgrade.mining_key_count:
			type_name = "채굴 키 개수"
			var new_count = Globals.mining_key_count_upgrades[current_level].y
			# 현재 키와 추가될 키 표시
			var key_names = ["F", "J", "D", "K", "S", "L"]
			var keys_str = ", ".join(key_names.slice(0, new_count))
			effect_text = "키 개수: %d개 (%s)" % [new_count, keys_str]
		upgrade.rock_money_up:
			type_name = "타일 채굴 보너스"
			var new_bonus = Globals.rock_money_upgrades[current_level].y
			effect_text = "추가 획득: +%d💎" % new_bonus
	
	return "가격: 💎%d\n효과: %s\n%s" % [cost, type_name, effect_text]

# 업그레이드 처리
func _process(delta):
	# 구매 가능 여부에 따라 시각 효과 업데이트
	update_visual_feedback()
	
	# 자동 대사 타이머
	idle_monologue_timer += delta
	if idle_monologue_timer >= idle_monologue_interval:
		idle_monologue_timer = 0.0
		# 확률적으로 대사 출력
		if randf() < idle_monologue_chance:
			spawn_idle_monologue()
	
	# 플레이어가 영역 안에 있고 F키를 누르면 업그레이드
	if is_character_inside and Input.is_action_just_pressed("f"):
		# 현재 단계의 비용 가져오기
		var cost = get_current_cost()
		
		# MAX 레벨 체크
		if cost == -1:
			spawn_monologue(monologues_max)
			return
		
		# 돈이 충분한지 확인
		if Globals.money >= cost:
			# 돈 차감
			Globals.money -= cost
			
			# 구매 효과 (반짝임)
			spawn_purchase_effect()
			
			# 성공 혼잣말
			spawn_monologue(monologues_success)
			
			# 타입에 따라 업그레이드 적용
			match type:
				upgrade.money_up:
					# 다이아몬드 획득량 레벨 증가
					Globals.diamond_value_level += 1
					Globals.update_diamond_value()
				upgrade.money_time:
					# 곡괭이 속도 레벨 증가
					Globals.pickaxe_speed_level += 1
					Globals.update_pickaxe_speed()
				upgrade.money_randomize:
					# 돈 랜덤 레벨 증가
					Globals.money_randomize_level += 1
					Globals.update_money_randomize()
				upgrade.mining_tier:
					# 채굴 티어 레벨 증가
					Globals.mining_tier_level += 1
					Globals.update_mining_tier()
				upgrade.auto_mining_speed:
					# 자동 채굴 속도 레벨 증가
					Globals.auto_mining_speed_level += 1
					Globals.update_auto_mining_speed()
				upgrade.mining_key_count:
					# 채굴 키 개수 레벨 증가
					Globals.mining_key_count_level += 1
					Globals.update_mining_key_count()
				upgrade.rock_money_up:
					# 타일 채굴 보너스 레벨 증가
					Globals.rock_money_level += 1
					Globals.update_rock_money()
			
			# 업그레이드 단계 증가
			current_level += 1
			
			# 액션 텍스트 업데이트 (다음 단계 정보 표시)
			Globals.show_action_text(get_upgrade_info_text())
		else:
			# 실패 혼잣말
			spawn_monologue(monologues_fail)

# 구매 가능 여부에 따른 시각 효과
func update_visual_feedback():
	# MAX 레벨 체크
	var is_max = false
	match type:
		upgrade.money_time:
			is_max = (current_level >= Globals.pickaxe_speed_upgrades.size())
		upgrade.money_up:
			is_max = (current_level >= Globals.diamond_value_upgrades.size())
		upgrade.mining_tier:
			is_max = (current_level >= Globals.mining_tier_upgrades.size())
		upgrade.auto_mining_speed:
			is_max = (current_level >= Globals.auto_mining_speed_upgrades.size())
		upgrade.mining_key_count:
			is_max = (current_level >= Globals.mining_key_count_upgrades.size())
		upgrade.money_randomize:
			is_max = (current_level >= Globals.money_randomize_upgrades.size())
		upgrade.rock_money_up:
			is_max = (current_level >= Globals.rock_money_upgrades.size())
	
	# 마지막 단계면 파티클 끄기
	if is_max:
		glow_particles.visible = false
		glow_particles.emitting = false
		if sprite:
			sprite.modulate = Color(0.5, 0.5, 0.5)  # 회색 (MAX)
		return
	
	var cost = get_current_cost()
	var can_afford = Globals.money >= cost
	
	# 구매 가능하면 초록색 파티클 표시, 불가능하면 파티클 숨김
	if can_afford:
		glow_particles.modulate = Color(0.3, 1.0, 0.3, 1.0)  # 초록색
		glow_particles.visible = true
		glow_particles.emitting = true
		if sprite:
			sprite.modulate = Color(1.2, 1.2, 1.2)  # 밝게
	else:
		glow_particles.visible = false
		glow_particles.emitting = false
		if sprite:
			sprite.modulate = Color(0.8, 0.8, 0.8)  # 어둡게


# 타입별 자동 대사 출력
func spawn_idle_monologue():
	var monologue_list: Array[String] = []
	
	match type:
		upgrade.money_up:
			monologue_list = idle_monologues_money_up
		upgrade.money_time:
			monologue_list = idle_monologues_money_time
		upgrade.mining_tier:
			monologue_list = idle_monologues_mining_tier
		upgrade.auto_mining_speed:
			monologue_list = idle_monologues_auto_mining_speed
		upgrade.mining_key_count:
			monologue_list = idle_monologues_mining_key_count
		upgrade.money_randomize:
			monologue_list = idle_monologues_money_randomize
		upgrade.rock_money_up:
			monologue_list = idle_monologues_rock_money_up
		_:
			return
	
	if not monologue_list.is_empty():
		spawn_monologue(monologue_list)

# 랜덤 혼잣말 표시 (saying 사용)
func spawn_monologue(monologue_list: Array[String]):
	if monologue_list.is_empty():
		return
	
	# 랜덤 혼잣말 선택
	var text = monologue_list[randi() % monologue_list.size()]
	
	# saying 노드 사용
	if has_node("saying"):
		var saying_label = $saying
		saying_label.text = text
		saying_label.visible = true
		
		# 2초 후 숨김
		await get_tree().create_timer(2.0).timeout
		saying_label.visible = false

# 구매 시 반짝임 효과
func spawn_purchase_effect():
	var particles = CPUParticles2D.new()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 1.0
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 50
	particles.initial_velocity_max = 120
	particles.gravity = Vector2(0, -50)
	particles.scale_amount_min = 3
	particles.scale_amount_max = 6
	particles.color = Color(1, 1, 0.3)  # 금색
	add_child(particles)
	particles.emitting = true
	
	# 스프라이트 펄스 효과
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2(1.3, 1.3), 0.2)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.2)
	
	# 파티클 자동 삭제
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()

# 돈이 변경되었을 때 호출 (Signal)
func _on_money_changed(_new_amount: int, _delta: int):
	# 구매 가능 여부가 변경되었을 수 있으므로 시각 효과 업데이트
	update_visual_feedback()

# 플레이어가 영역에 들어왔을 때
func _on_area_2d_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	# 들어온 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = true
		
		# 액션 텍스트로 업그레이드 정보 표시
		Globals.show_action_text(get_upgrade_info_text())

# 플레이어가 영역에서 나갔을 때
func _on_area_2d_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	# 나간 body가 CharacterBody2D 타입인지 확인
	if body is CharacterBody2D:
		is_character_inside = false
		
		# 액션 텍스트 숨김
		Globals.hide_action_text()
