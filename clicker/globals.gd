extends Node

# ========================================
# Signals - 다른 노드들이 구독할 수 있는 이벤트
# ========================================
signal money_changed(new_amount: int, delta: int)  # 돈이 변경될 때 (새 금액, 변화량)
signal tier_up(new_tier: int)  # 티어가 올라갈 때
signal action_text_changed(text: String, visible: bool)  # 액션 텍스트 변경 시그널

func _ready():
	# 초기 값 계산
	update_pickaxe_speed()
	update_diamond_value()
	update_diamond_per_second()
	update_mining_key_count()
	# 초기 티어 계산
	update_tier()
	max_tier = current_tier
	print("Globals 초기화: money=", money, ", current_tier=", current_tier, ", max_tier=", max_tier)
	print("  곡괭이 속도 레벨: ", pickaxe_speed_level, " (필요 클릭: ", mining_clicks_required, "회)")
	print("  다이아 획득량 레벨: ", diamond_value_level, " (획득량: ", money_up, ")")
	print("  초당 다이아 레벨: ", diamond_per_second_level, " (추가량: ", money_per_second_upgrade, ")")
	print("  채굴 키 개수 레벨: ", mining_key_count_level, " (키 개수: ", mining_key_count, "개)")

# ========================================
# 게임 밸런스 변수
# ========================================
# 곡괭이 속도 레벨 (pv Lv) - 0부터 시작, 최대 10
var pickaxe_speed_level : int = 0
# 다이아몬드 획득량 레벨 (dv Lv) - 0부터 시작, 최대 20
var diamond_value_level : int = 0
# 초당 다이아몬드 레벨 (da Lv) - 0부터 시작, 최대 5
var diamond_per_second_level : int = 0
# 자동 채굴 속도 레벨 (as Lv) - 0부터 시작, 최대 10
var auto_mining_speed_level : int = 0
# 채굴 키 개수 레벨 (mk Lv) - 0부터 시작, 최대 4
var mining_key_count_level : int = 0

# 실제 게임 값들 (레벨에 따라 계산됨)
var money_up : int = 1  # 채굴 시 획득하는 다이아몬드 (dv 레벨에 따라 결정)
var mining_clicks_required : int = 5  # 채굴에 필요한 클릭 수 (pv 레벨에 따라 감소)
var money_per_second : int = 0  # 초당 자동으로 증가하는 돈 (알바 + 광물 채굴로 누적)
var money_per_second_upgrade : int = 0  # 업그레이드로 얻은 초당 돈 증가량 (da 레벨에 따라 결정)
var auto_mining_interval : float = 0.5  # 자동 채굴 간격 (초) - 레벨에 따라 감소
var mining_key_count : int = 2  # 채굴 키 개수 (기본 2개: F, J)

# ========================================
# 피버 시스템
# ========================================
var fever_multiplier : float = 1.0  # 현재 피버 배율 (1.0 = 정상, 2.0 = 2배)
var is_fever_active : bool = false  # 피버 활성화 여부

# ========================================
# 경제 시스템
# ========================================
# 플레이어가 보유한 돈 (전역 변수)
var _money : int = 1000
var money : int:
	get:
		return _money
	set(value):
		var old_money = _money
		_money = value
		var delta_money = _money - old_money
		
		# Signal 발생 - UI 업데이트용
		money_changed.emit(_money, delta_money)
		
		# 티어 계산 (초반 느림 → 후반 빌드업)
		var old_max_tier = max_tier
		update_tier()
		
		# 최대 티어 업데이트 (한번 올라가면 내려가지 않음) - Signal 발생 전에 먼저!
		if current_tier > max_tier:
			max_tier = current_tier
			print("✨ 최대 티어 갱신! ", old_max_tier, " → ", max_tier)
			# 최대 티어가 갱신될 때만 Signal 발생
			print("🎉 티어 상승! ", old_max_tier, " → ", max_tier, " (돈: ", _money, ")")
			tier_up.emit(max_tier)

# ========================================
# 티어 시스템 (빌드업 느낌)
# ========================================
# 현재 티어
var current_tier : int = 0
# 최대 달성 티어 (한번 올라가면 내려가지 않음)
var max_tier : int = 0

# 티어별 필요 금액 (초반은 빠르게, 후반은 느리게)
var tier_thresholds: Array[int] = [
	0,      # 티어 0
	100,    # 티어 1
	200,    # 티어 2 (300 → 200으로 낮춤)
	400,    # 티어 3 (700 → 400으로 낮춤)
	800,    # 티어 4 (1500 → 800으로 낮춤)
	1600,   # 티어 5 (3000 → 1600으로 낮춤)
	3200,   # 티어 6 (6000 → 3200으로 낮춤)
	6400,   # 티어 7 (12000 → 6400으로 낮춤)
	12800,  # 티어 8 (24000 → 12800으로 낮춤)
	25600   # 티어 9 (48000 → 25600으로 낮춤)
]

# 현재 돈으로 티어 계산
func update_tier():
	for i in range(tier_thresholds.size() - 1, -1, -1):
		if _money >= tier_thresholds[i]:
			current_tier = i
			return
	current_tier = 0

# ========================================
# 업그레이드 시스템 (마인크래프트 타이쿤 맵과 동일)
# ========================================
# 곡괭이 속도 강화 (pv Lv) - 4레벨 (5번 클릭 → 1번 클릭)
# [가격, 필요 클릭 수] 형식
var pickaxe_speed_upgrades: Array[Vector2i] = [
	Vector2i(1000, 4),    # Lv 1: 5회 → 4회
	Vector2i(10000, 3),   # Lv 2: 4회 → 3회
	Vector2i(50000, 2),   # Lv 3: 3회 → 2회
	Vector2i(100000, 1),  # Lv 4 (MAX): 2회 → 1회
]

# 다이아몬드 획득량 증가 (dv Lv) - 20레벨, 총 591,940
# [가격, 획득량] 형식
var diamond_value_upgrades: Array[Vector2i] = [
	Vector2i(40, 2),      # Lv 1
	Vector2i(100, 4),    # Lv 2
	Vector2i(250, 8),    # Lv 3
	Vector2i(800, 10),    # Lv 4
	Vector2i(1250, 14),  # Lv 5
	Vector2i(2000, 20),  # Lv 6
	Vector2i(3000, 45),  # Lv 7
	Vector2i(5000, 60),  # Lv 8
	Vector2i(10000, 100), # Lv 9
	Vector2i(18500, 110),# Lv 10
	Vector2i(25000, 155),# Lv 11
	Vector2i(38000, 250),# Lv 12
	Vector2i(44000, 280),# Lv 13
	Vector2i(58000, 350),# Lv 14
	Vector2i(65000, 420),# Lv 15
	Vector2i(75000, 500),# Lv 16
	Vector2i(84000, 550),# Lv 17
	Vector2i(90000, 600),# Lv 18
	Vector2i(95000, 650),# Lv 19
	Vector2i(100000, 800) # Lv 20 (MAX: 800)
]

# 초당 다이아몬드 강화 (da Lv) - 5레벨, 총 330,000
# [가격, 초당 추가량] 형식
var diamond_per_second_upgrades: Array[Vector2i] = [
	Vector2i(25000, 2),  # Lv 1
	Vector2i(40000, 4),  # Lv 2
	Vector2i(60000, 6),  # Lv 3
	Vector2i(80000, 10),  # Lv 4
	Vector2i(125000, 25) # Lv 5 (MAX: 25)
]

# 자동 채굴 속도 강화 (as Lv) - 10레벨
# [가격, 채굴 간격(초)] 형식 - 간격이 짧을수록 빠름
var auto_mining_speed_upgrades: Array[Vector2] = [
	Vector2(100, 0.45),   # Lv 1: 0.5초 → 0.45초
	Vector2(300, 0.40),   # Lv 2: 0.40초
	Vector2(800, 0.35),   # Lv 3: 0.35초
	Vector2(2000, 0.30),  # Lv 4: 0.30초
	Vector2(5000, 0.25),  # Lv 5: 0.25초
	Vector2(10000, 0.20), # Lv 6: 0.20초
	Vector2(20000, 0.15), # Lv 7: 0.15초
	Vector2(40000, 0.12), # Lv 8: 0.12초
	Vector2(70000, 0.10), # Lv 9: 0.10초
	Vector2(100000, 0.08) # Lv 10 (MAX): 0.08초
]

# 채굴 키 개수 강화 (mk Lv) - 4레벨
# [가격, 총 키 개수] 형식 - 기본 2개에서 최대 6개까지
var mining_key_count_upgrades: Array[Vector2i] = [
	Vector2i(400, 3),      # Lv 1: 2개 → 3개 (D 추가)
	Vector2i(5000, 4),     # Lv 2: 3개 → 4개 (K 추가)
	Vector2i(40000, 5),    # Lv 3: 4개 → 5개 (S 추가)
	Vector2i(200000, 6),   # Lv 4 (MAX): 5개 → 6개 (L 추가)
]

# 레벨에 따른 실제 값 계산 함수들
func update_pickaxe_speed():
	# 곡괭이 속도는 레벨에 따라 필요 클릭 수 감소 (기본 5회)
	if pickaxe_speed_level == 0:
		mining_clicks_required = 5  # 기본값
	elif pickaxe_speed_level <= pickaxe_speed_upgrades.size():
		mining_clicks_required = pickaxe_speed_upgrades[pickaxe_speed_level - 1].y
	else:
		mining_clicks_required = 1  # MAX

func update_diamond_value():
	# 다이아몬드 획득량은 레벨에 따라 결정
	# 레벨 0 = 초기값 없음, 레벨 1부터 업그레이드 시작
	if diamond_value_level == 0:
		money_up = 1  # 초기값 (업그레이드 전에는 획득 불가)
	elif diamond_value_level <= diamond_value_upgrades.size():
		# 레벨에 해당하는 획득량 사용 (레벨 1 = 인덱스 0)
		money_up = diamond_value_upgrades[diamond_value_level - 1].y
	else:
		# MAX 레벨 (21) = 800
		money_up = 800

func update_diamond_per_second():
	# 초당 다이아몬드 추가량 계산
	money_per_second_upgrade = 0
	if diamond_per_second_level > 0:
		for i in range(min(diamond_per_second_level, diamond_per_second_upgrades.size())):
			money_per_second_upgrade += diamond_per_second_upgrades[i].y
	# MAX 레벨 (6) = 25
	if diamond_per_second_level >= 6:
		money_per_second_upgrade = 25

func update_auto_mining_speed():
	# 자동 채굴 간격 계산 (레벨에 따라 감소)
	if auto_mining_speed_level == 0:
		auto_mining_interval = 0.5  # 기본값 0.5초
	elif auto_mining_speed_level <= auto_mining_speed_upgrades.size():
		auto_mining_interval = auto_mining_speed_upgrades[auto_mining_speed_level - 1].y
	else:
		auto_mining_interval = 0.08  # MAX

func update_mining_key_count():
	# 채굴 키 개수 계산 (레벨에 따라 증가)
	if mining_key_count_level == 0:
		mining_key_count = 2  # 기본값 2개 (F, J)
	elif mining_key_count_level <= mining_key_count_upgrades.size():
		mining_key_count = mining_key_count_upgrades[mining_key_count_level - 1].y
	else:
		mining_key_count = 6  # MAX (F, J, D, K, S, L)

# ========================================
# 참조
# ========================================
# 플레이어 캐릭터 참조 (다른 스크립트에서 접근 가능)
var player = null

# ========================================
# 채굴 키 설정
# ========================================
# 채굴 키 배열 (레벨에 따라 사용 가능한 키가 증가)
# WASD는 이동 키라서 제외, 대신 다른 키 사용
var all_mining_keys : Array[int] = [KEY_F, KEY_J, KEY_G, KEY_K, KEY_H, KEY_L]
var mining_key1 : int = KEY_F
var mining_key2 : int = KEY_J

# ========================================
# 액션 텍스트 시스템
# ========================================
# 액션 텍스트 표시
func show_action_text(text: String):
	action_text_changed.emit(text, true)

# 액션 텍스트 숨김
func hide_action_text():
	action_text_changed.emit("", false)
