extends Node

# ========================================
# Signals - 다른 노드들이 구독할 수 있는 이벤트
# ========================================
signal money_changed(new_amount: int, delta: int)  # 돈이 변경될 때 (새 금액, 변화량)
signal rock_mined(amount: int)  # 일반 돌(rock)이 채굴되었을 때 (보상 금액)
signal tier_up(new_tier: int)  # 티어가 올라갈 때
signal action_text_changed(text: String, visible: bool)  # 액션 텍스트 변경 시그널
signal skin_changed(skin_id: String)  # 스킨이 변경될 때
signal upgrade_type_unlocked(type_id: int)  # 업그레이드 타입이 해금될 때

func _ready():
	# 초기 값 계산
	update_pickaxe_speed()
	update_diamond_value()
	update_mining_tier()
	update_auto_mining_speed()
	update_mining_key_count()
	update_money_randomize()
	update_rock_money()
	# 스킨 시스템 초기화
	_initialize_skins()
	_load_skin_data()
	# 설정 로드
	load_settings()

# ========================================
# 업그레이드 해금 시스템 (동굴 아이템)
# ========================================
# 업그레이드 타입 ID:
# 0 = money_up (다이아몬드 획득량) - 기본 해금
# 1 = money_time (곡괭이 속도)
# 2 = money_randomize (돈 랜덤 확률)
# 3 = mining_tier (채굴 티어)
# 4 = auto_mining_speed (자동 채굴 속도)
# 5 = mining_key_count (채굴 키 개수)
# 6 = rock_money_up (타일 채굴 보너스)

# 해금된 업그레이드 타입 목록 (0 = money_up은 기본 해금)
var unlocked_upgrade_types: Array[int] = [0]

# 동굴에서 발견한 아이템 ID 목록
var cave_items_found: Array[String] = []

# 수집한 요정 아이템 ID 목록 (중복 획득 방지)
var collected_fairy_items: Array[String] = []

# 업그레이드 타입별 이름 (번역 시스템 사용)
func get_upgrade_type_name(type_id: int) -> String:
	return get_text("UPGRADE TYPE %d" % type_id)

# 동굴 아이템 ID → 해금되는 업그레이드 타입 ID 매핑
var cave_item_unlock_map: Dictionary = {
	"speed_scroll": 1,       # 속도의 두루마리 → 곡괭이 속도
	"lucky_charm": 2,        # 행운의 부적 → 돈 랜덤 확률
	"depth_crystal": 3,      # 깊이의 수정 → 채굴 티어
	"auto_gear": 4,          # 자동 톱니바퀴 → 자동 채굴 속도
	"multi_key_stone": 5,    # 다중 키 석판 → 채굴 키 개수
	"rock_hammer": 6         # 바위 망치 → 타일 채굴 보너스
}

# 동굴 아이템별 설명 (번역 시스템 사용)
var _cave_item_key_map: Dictionary = {
	"speed_scroll": "CAVE SPEED SCROLL",
	"lucky_charm": "CAVE LUCKY CHARM",
	"depth_crystal": "CAVE DEPTH CRYSTAL",
	"auto_gear": "CAVE AUTO GEAR",
	"multi_key_stone": "CAVE MULTI KEY",
	"rock_hammer": "CAVE ROCK HAMMER",
}
func get_cave_item_description(item_id: String) -> String:
	if _cave_item_key_map.has(item_id):
		return get_text(_cave_item_key_map[item_id])
	return ""

## /** 업그레이드 타입을 해금한다
##  * @param type_id int 해금할 업그레이드 타입 ID
##  * @returns bool 해금 성공 여부 (이미 해금되면 false)
##  */
func unlock_upgrade_type(type_id: int) -> bool:
	if type_id in unlocked_upgrade_types:
		return false
	unlocked_upgrade_types.append(type_id)
	unlocked_upgrade_types.sort()  # 정렬 유지
	upgrade_type_unlocked.emit(type_id)
	save_settings()
	return true

## /** 동굴 아이템을 수집한다
##  * 아이템에 연결된 업그레이드 타입이 자동으로 해금된다
##  * @param item_id String 동굴 아이템 ID
##  * @returns bool 수집 성공 여부 (이미 수집했으면 false)
##  */
func collect_cave_item(item_id: String) -> bool:
	if item_id in cave_items_found:
		return false
	cave_items_found.append(item_id)
	# 아이템에 연결된 업그레이드 타입 해금
	if cave_item_unlock_map.has(item_id):
		var type_id = cave_item_unlock_map[item_id]
		unlock_upgrade_type(type_id)
	save_settings()
	return true

## /** 업그레이드 타입이 해금되었는지 확인한다
##  * @param type_id int 확인할 업그레이드 타입 ID
##  * @returns bool 해금 여부
##  */
func is_upgrade_unlocked(type_id: int) -> bool:
	return type_id in unlocked_upgrade_types

## /** 동굴 아이템이 이미 수집되었는지 확인한다
##  * @param item_id String 확인할 아이템 ID
##  * @returns bool 수집 여부
##  */
func is_cave_item_found(item_id: String) -> bool:
	return item_id in cave_items_found

# ========================================
# 게임 밸런스 변수
# ========================================
# 곡괭이 속도 레벨 (pv Lv) - 0부터 시작, 최대 10
var pickaxe_speed_level : int = 0
# 다이아몬드 획득량 레벨 (dv Lv) - 0부터 시작, 최대 20
var diamond_value_level : int = 0
# 채굴 티어 레벨 (mt Lv) - 0부터 시작, 최대 20
var mining_tier_level : int = 0
# 자동 채굴 속도 레벨 (as Lv) - 0부터 시작, 최대 10
var auto_mining_speed_level : int = 0
# 채굴 키 개수 레벨 (mk Lv) - 0부터 시작, 최대 2 (최대 4키)
var mining_key_count_level : int = 0
# 돈 랜덤 레벨 (mr Lv) - 0부터 시작, 최대 5
var money_randomize_level : int = 0
# 타일 채굴 보너스 레벨 (rm Lv) - 0부터 시작, 최대 2
var rock_money_level : int = 0

# 실제 게임 값들 (레벨에 따라 계산됨)
var money_up : int = 1  # 채굴 시 획득하는 다이아몬드 (dv 레벨에 따라 결정)
var mining_clicks_required : int = 5  # 채굴에 필요한 클릭 수 (pv 레벨에 따라 감소) - 테스트용으로 1로 설정
var mining_tier : int = 1  # 채굴 가능한 최대 레이어 (mt 레벨에 따라 결정, 1 = layer1만)
var auto_mining_interval : float = 0.5  # 자동 채굴 간격 (초) - 레벨에 따라 감소
var mining_key_count : int = 2  # 채굴 키 개수 (기본 2개: F, J)
var x2_chance : float = 0.10  # x2배 확률 (기본 10%)
var x3_chance : float = 0.01  # x3배 확률 (기본 1%)
var rock_money_bonus : int = 1  # 타일 채굴 시 추가 보너스 (기본 1)

# ========================================
# 피버 시스템
# ========================================
var fever_multiplier : float = 1.0  # 현재 피버 배율 (1.0 = 정상, 2.0 = 2배)
var is_fever_active : bool = false  # 피버 활성화 여부

# ========================================
# 경제 시스템
# ========================================
# 플레이어가 보유한 돈 (전역 변수)
var _money : int = 0
var money : int:
	get:
		return _money
	set(value):
		var old_money = _money
		_money = value
		var delta_money = _money - old_money
		
		# Signal 발생 - UI 업데이트용
		money_changed.emit(_money, delta_money)

# auto_scene에서 사용할 새로운 돈 시스템
var auto_money : int = 0

# 초당 수입 (알바 시스템용)
var money_per_second : int = 0

# ========================================
# 클리어 시스템
# ========================================
var goal_money : int = 1000000  # 목표 금액 (100만원)
var game_clear_points : int = 0  # 클리어 시 획득한 포인트
var total_points : int = 0  # 누적 포인트 (auto_scene에서 사용)
var is_game_cleared : bool = false  # 게임 클리어 여부

## 클리어 시간에 따른 포인트 계산
## 15분(900초) = 10000포인트 기준, 빠를수록 더 많이, 느릴수록 적게
## 45분(2700초) 이상이면 불쌍 보너스 +1000점
func calculate_clear_points(clear_time_seconds: float) -> int:
	# 기준: 900초에 10000점
	# 공식: points = 10000 * (900 / clear_time)
	var base_time = 900.0  # 15분
	var base_points = 10000.0
	var points = int(base_points * (base_time / max(clear_time_seconds, 60.0)))
	
	# 45분 이상이면 불쌍 보너스 +1000점
	if clear_time_seconds >= 2700.0:
		points += 1000
	
	return clampi(points, 1000, 100000)

# ========================================
# 스킨 상점 시스템
# ========================================
var owned_skins: Array[String] = ["normal1", "normal2"]  # 구매한 스킨 ID 목록
var current_sprite1_skin: String = "normal1"  # Sprite2D에 적용중인 스킨
var current_sprite2_skin: String = "normal2"  # Sprite2D2에 적용중인 스킨
var available_skins: Dictionary = {}  # 구매 가능한 스킨 데이터 (id -> SkinItem)

# ========================================
# 티어 시스템 (mining_tier 업그레이드 기반)
# ========================================
# 현재 채굴 가능 티어 (mining_tier_level + 1)
# 티어 1 = layer 1만 캘 수 있음, 티어 2 = layer 1~2 캘 수 있음

# 채굴 티어 업데이트 함수
func update_mining_tier():
	# mining_tier_level이 0이면 티어 1 (layer 1만)
	# mining_tier_level이 1이면 티어 2 (layer 1~2)
	mining_tier = mining_tier_level + 1

# ========================================
# 업그레이드 시스템 (마인크래프트 타이쿤 맵과 동일)
# ========================================
# 곡괭이 속도 강화 (pv Lv) - 4레벨 (5번 클릭 → 1번 클릭)
# [가격, 필요 클릭 수] 형식
var pickaxe_speed_upgrades: Array[Vector2i] = [
	Vector2i(150, 4),     # Lv 1: 5회 → 4회 (초반에 빠르게 구매 가능)
	Vector2i(800, 3),     # Lv 2: 4회 → 3회
	Vector2i(5000, 2),    # Lv 3: 3회 → 2회
	Vector2i(30000, 1),   # Lv 4 (MAX): 2회 → 1회
]

# 다이아몬드 획득량 증가 (dv Lv) - 20레벨
# [가격, 획득량] 형식 - 초반 저렴, 후반 비쌈
var diamond_value_upgrades: Array[Vector2i] = [
	Vector2i(10, 3),      # Lv 1: 빠른 시작
	Vector2i(50, 5),      # Lv 2
	Vector2i(120, 8),     # Lv 3
	Vector2i(300, 12),    # Lv 4
	Vector2i(600, 18),    # Lv 5
	Vector2i(1200, 25),   # Lv 6
	Vector2i(2500, 35),   # Lv 7
	Vector2i(5000, 50),   # Lv 8
	Vector2i(8000, 70),   # Lv 9
	Vector2i(12000, 100), # Lv 10
	Vector2i(18000, 140), # Lv 11
	Vector2i(25000, 190), # Lv 12
	Vector2i(35000, 250), # Lv 13
	Vector2i(50000, 330), # Lv 14
	Vector2i(65000, 420), # Lv 15
	Vector2i(80000, 520), # Lv 16
	Vector2i(95000, 630), # Lv 17
	Vector2i(110000, 750),# Lv 18
	Vector2i(130000, 900),# Lv 19
	Vector2i(150000, 1100)# Lv 20 (MAX)
]

# 채굴 티어 강화 (mt Lv) - 3레벨
# [가격, 해금 티어] 형식 - 티어가 높을수록 더 깊은 레이어의 돌을 캘 수 있음
var mining_tier_upgrades: Array[Vector2i] = [
	Vector2i(1500, 2),     # Lv 1: 티어 2 (layer 1~2 채굴 가능)
	Vector2i(15000, 3),    # Lv 2: 티어 3 (layer 1~3 채굴 가능)
	Vector2i(60000, 4),    # Lv 3 (MAX): 티어 4 (layer 1~4 채굴 가능)
]

# 자동 채굴 속도 강화 (as Lv) - 10레벨
# [가격, 채굴 간격(초)] 형식 - 간격이 짧을수록 빠름
var auto_mining_speed_upgrades: Array[Vector2] = [
	Vector2(50, 0.45),    # Lv 1: 0.5초 → 0.45초 (저렴하게 시작)
	Vector2(150, 0.40),   # Lv 2: 0.40초
	Vector2(400, 0.35),   # Lv 3: 0.35초
	Vector2(1000, 0.30),  # Lv 4: 0.30초
	Vector2(2500, 0.25),  # Lv 5: 0.25초
	Vector2(6000, 0.20),  # Lv 6: 0.20초
	Vector2(15000, 0.15), # Lv 7: 0.15초
	Vector2(35000, 0.12), # Lv 8: 0.12초
	Vector2(60000, 0.10), # Lv 9: 0.10초
	Vector2(100000, 0.08) # Lv 10 (MAX): 0.08초
]

# 채굴 키 개수 강화 (mk Lv) - 2레벨
# [가격, 총 키 개수] 형식 - 기본 2개에서 최대 4개까지
var mining_key_count_upgrades: Array[Vector2i] = [
	Vector2i(100, 3),      # Lv 1: 2개 → 3개 (D 추가) - 초반에 쉽게
	Vector2i(1500, 4),     # Lv 2 (MAX): 3개 → 4개 (K 추가)
]

# 돈 랜덤 강화 (mr Lv) - 5레벨
# [가격, x2확률(%), x3확률(%)] 형식 - 채굴 시 x2배, x3배 확률
# 기본값: x2 10%, x3 1%
var money_randomize_upgrades: Array[Vector3i] = [
	Vector3i(80, 15, 3),       # Lv 1: x2 15%, x3 3%
	Vector3i(400, 22, 6),      # Lv 2: x2 22%, x3 6%
	Vector3i(2000, 32, 10),    # Lv 3: x2 32%, x3 10%
	Vector3i(10000, 42, 15),   # Lv 4: x2 42%, x3 15%
	Vector3i(50000, 55, 22),   # Lv 5 (MAX): x2 55%, x3 22%
]

# 타일 채굴 보너스 강화 (rm Lv) - 실험적
# [가격, 추가 획득량] 형식 - 타일 돌을 캘 때 추가 보너스
var rock_money_upgrades: Array[Vector2i] = [
	Vector2i(60, 8),      # Lv 1: +8
	Vector2i(500, 50),    # Lv 2 (MAX): +50
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
		# MAX 레벨 (21) = 1100
		money_up = 1100


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
		mining_key_count = 4  # MAX (F, J, D, K)

func update_money_randomize():
	# 돈 랜덤 확률 계산 (레벨에 따라 증가)
	if money_randomize_level == 0:
		x2_chance = 0.10  # 기본값 10%
		x3_chance = 0.01  # 기본값 1%
	elif money_randomize_level <= money_randomize_upgrades.size():
		# 레벨에 해당하는 확률 사용 (레벨 1 = 인덱스 0)
		x2_chance = money_randomize_upgrades[money_randomize_level - 1].y / 100.0
		x3_chance = money_randomize_upgrades[money_randomize_level - 1].z / 100.0
	else:
		# MAX 레벨 = 50%, 20%
		x2_chance = 0.50
		x3_chance = 0.20

func update_rock_money():
	# 타일 채굴 보너스 계산 (레벨에 따라 증가)
	if rock_money_level == 0:
		rock_money_bonus = 1  # 기본값 1
	elif rock_money_level <= rock_money_upgrades.size():
		# 레벨에 해당하는 보너스 사용 (레벨 1 = 인덱스 0)
		rock_money_bonus = rock_money_upgrades[rock_money_level - 1].y
	else:
		# MAX 레벨 = 50
		rock_money_bonus = 50

# ========================================
# 참조
# ========================================
# 플레이어 캐릭터 참조 (다른 스크립트에서 접근 가능)
var player = null

# ========================================
# 설치 모드 상태 (전역)
# ========================================
var is_build_mode: bool = false  # 플랫폼 설치 모드
var is_torch_mode: bool = false  # 횃불 설치 모드

# 모드 변경 시그널
signal build_mode_changed(mode: String)  # "pickaxe", "torch", "platform"

## 현재 모드를 반환 (pickaxe/torch/platform)
func get_current_mode() -> String:
	if is_torch_mode:
		return "torch"
	elif is_build_mode:
		return "platform"
	else:
		return "pickaxe"

## 모드 변경 시 호출 (시그널 발생)
func emit_mode_changed():
	var mode = get_current_mode()
	build_mode_changed.emit(mode)
	print("🔧 모드 변경: %s" % mode)

# ========================================
# 튜토리얼 시스템
# ========================================
var is_tutorial_completed: bool = false  # 튜토리얼 완료 여부
var show_tutorial_popup: bool = true     # 팝업 표시 여부 (설정에서 제어)
var is_tutorial_active: bool = false     # 튜토리얼 진행 중 여부

## 튜토리얼 초기화 (다시 보기)
func reset_tutorial():
	is_tutorial_completed = false
	show_tutorial_popup = true
	is_tutorial_active = false
	save_settings()
	print("🔄 튜토리얼 초기화 완료")

# ========================================
# 채굴 키 설정
# ========================================
# 채굴 키 배열 (레벨에 따라 사용 가능한 키가 증가)
# WASD는 이동 키라서 제외, 대신 다른 키 사용
var all_mining_keys : Array[int] = [KEY_F, KEY_J, KEY_G, KEY_K, KEY_H, KEY_L]
var mining_key1 : int = KEY_F
var mining_key2 : int = KEY_J

# ========================================
# 게임 설정 (Settings)
# ========================================
# 볼륨 설정 (0.0 ~ 1.0)
var master_volume: float = 1.0
var bgm_volume: float = 1.0
var sfx_volume: float = 1.0

# 언어 설정
var current_language: String = "ko"  # "ko" = 한국어, "en" = 영어
var available_languages: Dictionary = {
	"ko": "한국어",
	"en": "English"
}

# ========================================
# Auto Scene 설정
# ========================================
# UI 크기 배율 (0.5 ~ 3.0)
var auto_ui_scale: float = 1.0
# 캐릭터 크기 배율 (0.5 ~ 3.0)
var auto_character_scale: float = 1.0

# 번역 데이터
var translations: Dictionary = {
	"ko": {
		"MENU TITLE": "메뉴",
		"MENU RESUME": "계속하기",
		"MENU SETTING": "설정",
		"MENU EXIT": "나가기",
		"SETTING TITLE": "설정",
		"SETTING MASTER": "마스터",
		"SETTING BGM": "BGM",
		"SETTING SFX": "효과음",
		"SETTING LANGUAGE": "언어",
		"SETTING BACK": "뒤로가기",
		"SETTING TUTORIAL POPUP": "튜토리얼 팝업 표시",
		"SETTING TUTORIAL RESTART": "튜토리얼 다시 보기",
		"SETTING TUTORIAL SKIP": "스킵하기",
		"SHOP TITLE": "상점",
		"SHOP OWNED": "보유:",
		"SHOP CLOSE": "닫기",
		"SHOP BUY": "구매",
		"SHOP APPLY": "적용",
		"SHOP APPLIED": "✓ 적용됨",
		"SHOP FREE": "무료",
		"SHOP OWNED ITEM": "보유중",
		"SHOP DEFAULT": "기본",
		"SHOP INVENTORY": "인벤토리",
		"SHOP CHARACTER SKIN": "캐릭터 스킨",
		"SHOP TOOL SKIN": "도구 스킨",
		"SHOP BACK": "뒤로",
		"UI PRESS KEY": "키를 누르세요...",
		"UI KEY BLOCKED": "사용 불가!",
		"UI TIER UP": "티어 %d 달성!",
		"UI MINING KEY N": "채굴 키 %d:",
		"UI GOAL": "목표: %s / %s",
		"UI GOAL INIT": "목표: 0 / %s",
		"UI PASSIVE INCOME": "+%d/초 (알바)",
		"UI INCOME SUFFIX": "/초",
		"UI TUTORIAL RESTART": "🔄 튜토리얼을 다시 시작합니다...",
		"UI GAME CLEAR": "🎉 게임 클리어! 🎉",
		"UI CLEAR TIME": "클리어 시간: %s",
		"UI POINTS EARNED": "획득 포인트: %s P",
		"UI TOTAL POINTS": "누적 포인트: %s P",
		"UI CONTINUE": "auto_scene으로 이동",
		"AUTO GO BACK": "<-",
		"AUTO SHOP": "상점",
		"AUTO SETTING": "설정",
		"AUTO SETTING TITLE": "설정",
		"AUTO UI SCALE": "UI 크기",
		"AUTO CHAR SCALE": "캐릭터 크기",
		"AUTO SETTING APPLY": "적용",
		"AUTO SETTING CLOSE": "닫기",
		"LOBBY PRESS KEY": "- 아무 키나 누르세요 -",
		"NPC TALK": "[F] 대화하기",
		"NPC IDLE 1": "오늘도 장사가 안 되네",
		"NPC IDLE 2": "손님 없나...",
		"NPC IDLE 3": "업그레이드 하나 사가세요",
		"NPC IDLE 4": "좋은 물건 많아요",
		"NPC IDLE 5": "할인은 없어요",
		"NPC SUCCESS 1": "좋은 선택이야!",
		"NPC SUCCESS 2": "이제 좀 쓸만해졌네",
		"NPC SUCCESS 3": "돈이 아깝지 않을걸?",
		"NPC SUCCESS 4": "잘 골랐어!",
		"NPC FAIL 1": "돈이 부족해",
		"NPC FAIL 2": "아직 못 사네",
		"NPC FAIL 3": "열심히 더 캐야지",
		"UPGRADE DIAMOND": "다이아 획득량",
		"UPGRADE SPEED": "곡괭이 속도",
		"UPGRADE RANDOM": "돈 랜덤 확률",
		"UPGRADE TIER": "채굴 티어",
		"UPGRADE AUTO": "자동 채굴",
		"UPGRADE KEY": "채굴 키",
		"UPGRADE TILE": "타일 보너스",
		"UPGRADE NPC 1": "뭐 할거있어?",
		"UPGRADE NPC 2": "뭐가 필요해?",
		"UPGRADE NPC 3": "업그레이드 할래?",
		"UPGRADE NPC 4": "오늘도 열심히 캐?",
		"UPGRADE NPC 5": "이것저것 다 있어",
		"UPGRADE SELECT": "업그레이드를 선택하세요",
		"UPGRADE LOCKED": "🔒 아직 해금되지 않았습니다\n동굴에서 아이템을 찾아보세요!",
		"UPGRADE MAX REACHED": "이미 최대 레벨입니다!",
		"UPGRADE NOT ENOUGH": "💎 부족! 필요: 💎%d\n보유: 💎%d",
		"UPGRADE MAX STAR": "⭐ 최대 레벨 도달!",
		"UPGRADE COST": "💎 %d 필요",
		"UPGRADE BUY AFFORD": "구매 💎%d",
		"UPGRADE BUY CANT": "💎 부족",
		"UPGRADE MAX": "최대 레벨",
		"UPGRADE EFFECT YIELD": "획득량: %d",
		"UPGRADE EFFECT CLICKS": "필요 클릭: %d회",
		"UPGRADE EFFECT TIER": "티어 %d (레이어 1~%d)",
		"UPGRADE EFFECT INTERVAL": "채굴 간격: %.2f초",
		"UPGRADE EFFECT KEYS": "키 %d개 (%s)",
		"UPGRADE EFFECT BONUS": "추가 획득: +%d",
		"UPGRADE INFO FORMAT": "%s (Lv%d → Lv%d)\n%s\n%s",
		"ALBA INFO": "알바 고용\n가격: %d\n수입: %d/초",
		"UPGRADE TYPE 0": "다이아몬드 획득량",
		"UPGRADE TYPE 1": "곡괭이 속도",
		"UPGRADE TYPE 2": "돈 랜덤 확률",
		"UPGRADE TYPE 3": "채굴 티어",
		"UPGRADE TYPE 4": "자동 채굴 속도",
		"UPGRADE TYPE 5": "채굴 키 개수",
		"UPGRADE TYPE 6": "타일 채굴 보너스",
		"CAVE SPEED SCROLL": "속도의 두루마리를 발견했다!\n곡괭이 속도 업그레이드가 해금되었다!",
		"CAVE LUCKY CHARM": "행운의 부적을 발견했다!\n돈 랜덤 확률 업그레이드가 해금되었다!",
		"CAVE DEPTH CRYSTAL": "깊이의 수정을 발견했다!\n채굴 티어 업그레이드가 해금되었다!",
		"CAVE AUTO GEAR": "자동 톱니바퀴를 발견했다!\n자동 채굴 속도 업그레이드가 해금되었다!",
		"CAVE MULTI KEY": "다중 키 석판을 발견했다!\n채굴 키 개수 업그레이드가 해금되었다!",
		"CAVE ROCK HAMMER": "바위 망치를 발견했다!\n타일 채굴 보너스 업그레이드가 해금되었다!",
		"CAVE ITEM SPEED SCROLL": "속도의 두루마리",
		"CAVE ITEM LUCKY CHARM": "행운의 부적",
		"CAVE ITEM DEPTH CRYSTAL": "깊이의 수정",
		"CAVE ITEM AUTO GEAR": "자동화 톱니",
		"CAVE ITEM MULTI KEY": "다중 키스톤",
		"CAVE ITEM ROCK HAMMER": "바위 망치",
		"UPGRADE NEW UNLOCKED": "새로운 업그레이드가 해금되었다!",
		"FAIRY PICKAXE NAME": "요정의 곡괭이",
		"FAIRY PICKAXE DESC": "요정에게 곡괭이를 쥐여줍니다",
		"FAIRY PICKAXE ACQUIRE": "요정이 곡괭이를 사용할 수 있게 되었습니다",
		"FAIRY LIGHT NAME": "요정의 빛",
		"FAIRY LIGHT DESC": "요정이 은은한 빛을 냅니다",
		"FAIRY LIGHT ACQUIRE": "요정이 빛을 낼 수 있게 되었습니다",
		"FAIRY ITEM DEFAULT": "아이템",
		"FAIRY ACQUIRE DEFAULT": "요정이 새로운 능력을 얻었습니다",
		"FAIRY ACQUIRE FORMAT": "[F] %s 획득",
		"TUTORIAL POPUP TITLE": "튜토리얼",
		"TUTORIAL POPUP QUESTION": "튜토리얼을 진행하시겠습니까?\n기본 조작법과 게임 방법을 배울 수 있습니다.",
		"TUTORIAL POPUP YES": "예",
		"TUTORIAL POPUP NO": "아니오",
		"TUTORIAL INTRO 1": "안녕! 나는 광산 요정이야!",
		"TUTORIAL INTRO 2": "여기는 오래된 광산이야.",
		"TUTORIAL INTRO 3": "이곳에서 돌을 캐서 돈을 벌 수 있어!",
		"TUTORIAL INTRO 4": "기본적인 방법을 알려줄게!",
		"TUTORIAL SHOW ROCK 1": "저기 보이는 돌을 봐!",
		"TUTORIAL SHOW ROCK 2": "F키를 눌러서 돌을 캘 수 있어.",
		"TUTORIAL SHOW ROCK 3": "키를 여러 번 눌러서 게이지를 채우면 돼!",
		"TUTORIAL MINE ROCK 1": "좋아! 이제 돌을 10개 캐보자!",
		"TUTORIAL MINE ROCK 2": "F키를 눌러서 채굴해줘!",
		"TUTORIAL MINE ROCK 3": "(돌 근처로 가서 F키를 누르세요)",
		"TUTORIAL MINE PROGRESS": "돌 채굴: %d / 10개",
		"TUTORIAL MINE COMPLETE 1": "잘했어! 10개를 모았네!",
		"TUTORIAL MINE COMPLETE 2": "이제 이 돌로 뭘 할 수 있는지 보여줄게.",
		"TUTORIAL SHOW UPGRADE 1": "저기 있는 NPC를 봐!",
		"TUTORIAL SHOW UPGRADE 2": "그 친구한테 가면 돈으로 업그레이드를 할 수 있어.",
		"TUTORIAL SHOW UPGRADE 3": "더 빨리, 더 많이 캘 수 있게 해주지!",
		"TUTORIAL DO UPGRADE 1": "NPC 근처로 가서 F키를 눌러봐!",
		"TUTORIAL DO UPGRADE 2": "한 번만 업그레이드해보자!",
		"TUTORIAL DO UPGRADE 3": "(money_up NPC 근처에서 F키를 누르세요)",
		"TUTORIAL UPGRADE COMPLETE 1": "완벽해! 이제 더 많은 돈을 벌 수 있을 거야!",
		"TUTORIAL UPGRADE COMPLETE 2": "이제 더 깊은 곳으로 가볼까?",
		"TUTORIAL SHOW CAVE 1": "저기 아래에 어두운 동굴이 보이지?",
		"TUTORIAL SHOW CAVE 2": "그곳에 더 좋은 광물이 있을지도 몰라!",
		"TUTORIAL SHOW CAVE 3": "같이 가보자!",
		"TUTORIAL BREAK WALL 1": "이 벽을 부수면 들어갈 수 있어!",
		"TUTORIAL BREAK WALL 2": "마우스 왼쪽 클릭으로 벽을 부술 수 있어.",
		"TUTORIAL BREAK WALL 3": "(마우스로 벽을 가리키고 왼쪽 클릭하세요)",
		"TUTORIAL BREAK PROGRESS": "벽 파괴 중...",
		"TUTORIAL ENTER CAVE": "동굴 안으로 들어가세요!",
		"TUTORIAL GO DEEPER": "동굴 안쪽으로 더 들어가세요!",
		"TUTORIAL TORCH 1": "너무 어둡네! 횃불이 필요해.",
		"TUTORIAL TORCH 2": "2번 키를 눌러서 횃불 설치 모드로 전환해.",
		"TUTORIAL TORCH 3": "그 다음 B키를 눌러서 설치할 수 있어!",
		"TUTORIAL TORCH 4": "(2번 키 → 마우스로 위치 선택 → B키)",
		"TUTORIAL TORCH PLACED 1": "좋아! 이제 훨씬 밝네!",
		"TUTORIAL TORCH PLACED 2": "앞으로도 어두운 곳에서 이렇게 하면 돼.",
		"TUTORIAL TORCH PLACED 3": "이제 2번 키를 다시 눌러서 채굴 모드로 돌아가자!",
		"TUTORIAL NEED MONEY 1": "앗, 동굴 안의 업그레이드를 하려면 돈이 부족해!",
		"TUTORIAL NEED MONEY 2": "다시 밖으로 나가서 돌을 더 캐야겠어.",
		"TUTORIAL NEED MONEY 3": "그런데 입구가 위에 있네...",
		"TUTORIAL PLATFORM 1": "이제 밖으로 나가보자! 입구가 위에 있네...",
		"TUTORIAL PLATFORM 2": "3번 키를 눌러서 플랫폼 설치 모드로 전환해.",
		"TUTORIAL PLATFORM 3": "플랫폼을 계단처럼 쌓아서 올라갈 수 있어!",
		"TUTORIAL PLATFORM 4": "(3번 키 → 마우스로 위치 → B키 반복)",
		"TUTORIAL PLATFORM PROGRESS": "플랫폼 설치 중... 입구까지 올라가세요!",
		"TUTORIAL COMPLETE 1": "완벽해! 기본적인 건 다 배웠어!",
		"TUTORIAL COMPLETE 2": "이제 나도 너를 도와줄게!",
		"TUTORIAL COMPLETE 3": "앞으로는 J키로도 돌을 캘 수 있어!",
		"TUTORIAL COMPLETE 4": "함께 광산의 비밀을 찾아보자!",
	},
	"en": {
		"MENU TITLE": "Menu",
		"MENU RESUME": "Resume",
		"MENU SETTING": "Settings",
		"MENU EXIT": "Exit",
		"SETTING TITLE": "Settings",
		"SETTING MASTER": "Master",
		"SETTING BGM": "BGM",
		"SETTING SFX": "SFX",
		"SETTING LANGUAGE": "Language",
		"SETTING BACK": "Back",
		"SETTING TUTORIAL POPUP": "Show Tutorial Popup",
		"SETTING TUTORIAL RESTART": "Restart Tutorial",
		"SETTING TUTORIAL SKIP": "Skip",
		"SHOP TITLE": "Shop",
		"SHOP OWNED": "Owned:",
		"SHOP CLOSE": "Close",
		"SHOP BUY": "Buy",
		"SHOP APPLY": "Apply",
		"SHOP APPLIED": "✓ Applied",
		"SHOP FREE": "Free",
		"SHOP OWNED ITEM": "Owned",
		"SHOP DEFAULT": "Default",
		"SHOP INVENTORY": "Inventory",
		"SHOP CHARACTER SKIN": "Character",
		"SHOP TOOL SKIN": "Tool",
		"SHOP BACK": "Back",
		"UI PRESS KEY": "Press a key...",
		"UI KEY BLOCKED": "Not Available!",
		"UI TIER UP": "Tier %d Reached!",
		"UI MINING KEY N": "Mining Key %d:",
		"UI GOAL": "Goal: %s / %s",
		"UI GOAL INIT": "Goal: 0 / %s",
		"UI PASSIVE INCOME": "+%d/s (Worker)",
		"UI INCOME SUFFIX": "/s",
		"UI TUTORIAL RESTART": "🔄 Restarting tutorial...",
		"UI GAME CLEAR": "🎉 Game Clear! 🎉",
		"UI CLEAR TIME": "Clear Time: %s",
		"UI POINTS EARNED": "Points Earned: %s P",
		"UI TOTAL POINTS": "Total Points: %s P",
		"UI CONTINUE": "Go to Auto Scene",
		"AUTO GO BACK": "<-",
		"AUTO SHOP": "Shop",
		"AUTO SETTING": "Settings",
		"AUTO SETTING TITLE": "Settings",
		"AUTO UI SCALE": "UI Scale",
		"AUTO CHAR SCALE": "Character",
		"AUTO SETTING APPLY": "Apply",
		"AUTO SETTING CLOSE": "Close",
		"LOBBY PRESS KEY": "- Press Any Key -",
		"NPC TALK": "[F] Talk",
		"NPC IDLE 1": "Business is slow today",
		"NPC IDLE 2": "No customers...",
		"NPC IDLE 3": "Buy an upgrade",
		"NPC IDLE 4": "I have great stuff",
		"NPC IDLE 5": "No discounts",
		"NPC SUCCESS 1": "Good choice!",
		"NPC SUCCESS 2": "Now that's useful",
		"NPC SUCCESS 3": "Worth every penny!",
		"NPC SUCCESS 4": "Nice pick!",
		"NPC FAIL 1": "Not enough money",
		"NPC FAIL 2": "Can't afford that yet",
		"NPC FAIL 3": "Keep mining!",
		"UPGRADE DIAMOND": "Diamond Yield",
		"UPGRADE SPEED": "Pickaxe Speed",
		"UPGRADE RANDOM": "Luck Chance",
		"UPGRADE TIER": "Mining Tier",
		"UPGRADE AUTO": "Auto Mining",
		"UPGRADE KEY": "Mining Keys",
		"UPGRADE TILE": "Tile Bonus",
		"UPGRADE NPC 1": "Need something?",
		"UPGRADE NPC 2": "What do you need?",
		"UPGRADE NPC 3": "Want an upgrade?",
		"UPGRADE NPC 4": "Mining hard today?",
		"UPGRADE NPC 5": "I've got everything",
		"UPGRADE SELECT": "Select an upgrade",
		"UPGRADE LOCKED": "🔒 Not unlocked yet\nFind items in the cave!",
		"UPGRADE MAX REACHED": "Already at max level!",
		"UPGRADE NOT ENOUGH": "💎 Not enough! Need: 💎%d\nOwned: 💎%d",
		"UPGRADE MAX STAR": "⭐ Max level reached!",
		"UPGRADE COST": "💎 %d needed",
		"UPGRADE BUY AFFORD": "Buy 💎%d",
		"UPGRADE BUY CANT": "💎 Not enough",
		"UPGRADE MAX": "Max Level",
		"UPGRADE EFFECT YIELD": "Yield: %d",
		"UPGRADE EFFECT CLICKS": "Required clicks: %d",
		"UPGRADE EFFECT TIER": "Tier %d (Layer 1~%d)",
		"UPGRADE EFFECT INTERVAL": "Mining interval: %.2fs",
		"UPGRADE EFFECT KEYS": "%d keys (%s)",
		"UPGRADE EFFECT BONUS": "Extra yield: +%d",
		"UPGRADE INFO FORMAT": "%s (Lv%d → Lv%d)\n%s\n%s",
		"ALBA INFO": "Hire Worker\nPrice: %d\nIncome: %d/s",
		"UPGRADE TYPE 0": "Diamond Yield",
		"UPGRADE TYPE 1": "Pickaxe Speed",
		"UPGRADE TYPE 2": "Luck Chance",
		"UPGRADE TYPE 3": "Mining Tier",
		"UPGRADE TYPE 4": "Auto Mining Speed",
		"UPGRADE TYPE 5": "Mining Key Count",
		"UPGRADE TYPE 6": "Tile Mining Bonus",
		"CAVE SPEED SCROLL": "Found a Speed Scroll!\nPickaxe Speed upgrade unlocked!",
		"CAVE LUCKY CHARM": "Found a Lucky Charm!\nLuck Chance upgrade unlocked!",
		"CAVE DEPTH CRYSTAL": "Found a Depth Crystal!\nMining Tier upgrade unlocked!",
		"CAVE AUTO GEAR": "Found an Auto Gear!\nAuto Mining Speed upgrade unlocked!",
		"CAVE MULTI KEY": "Found a Multi-Key Stone!\nMining Key Count upgrade unlocked!",
		"CAVE ROCK HAMMER": "Found a Rock Hammer!\nTile Mining Bonus upgrade unlocked!",
		"CAVE ITEM SPEED SCROLL": "Speed Scroll",
		"CAVE ITEM LUCKY CHARM": "Lucky Charm",
		"CAVE ITEM DEPTH CRYSTAL": "Depth Crystal",
		"CAVE ITEM AUTO GEAR": "Auto Gear",
		"CAVE ITEM MULTI KEY": "Multi-Key Stone",
		"CAVE ITEM ROCK HAMMER": "Rock Hammer",
		"UPGRADE NEW UNLOCKED": "New upgrade unlocked!",
		"FAIRY PICKAXE NAME": "Fairy's Pickaxe",
		"FAIRY PICKAXE DESC": "Give the fairy a pickaxe",
		"FAIRY PICKAXE ACQUIRE": "The fairy can now use a pickaxe",
		"FAIRY LIGHT NAME": "Fairy's Light",
		"FAIRY LIGHT DESC": "The fairy emits a gentle glow",
		"FAIRY LIGHT ACQUIRE": "The fairy can now emit light",
		"FAIRY ITEM DEFAULT": "Item",
		"FAIRY ACQUIRE DEFAULT": "The fairy gained a new ability",
		"FAIRY ACQUIRE FORMAT": "[F] Get %s",
		"TUTORIAL POPUP TITLE": "Tutorial",
		"TUTORIAL POPUP QUESTION": "Would you like to play the tutorial?\nLearn basic controls and gameplay.",
		"TUTORIAL POPUP YES": "Yes",
		"TUTORIAL POPUP NO": "No",
		"TUTORIAL INTRO 1": "Hi! I'm the mine fairy!",
		"TUTORIAL INTRO 2": "This is an old mine.",
		"TUTORIAL INTRO 3": "You can mine rocks to earn money here!",
		"TUTORIAL INTRO 4": "Let me show you the basics!",
		"TUTORIAL SHOW ROCK 1": "Look at that rock over there!",
		"TUTORIAL SHOW ROCK 2": "Press F to mine rocks.",
		"TUTORIAL SHOW ROCK 3": "Press the key multiple times to fill the gauge!",
		"TUTORIAL MINE ROCK 1": "Alright! Let's mine 10 rocks!",
		"TUTORIAL MINE ROCK 2": "Press F to mine!",
		"TUTORIAL MINE ROCK 3": "(Go near a rock and press F)",
		"TUTORIAL MINE PROGRESS": "Rocks mined: %d / 10",
		"TUTORIAL MINE COMPLETE 1": "Great job! You mined 10!",
		"TUTORIAL MINE COMPLETE 2": "Let me show you what you can do with these.",
		"TUTORIAL SHOW UPGRADE 1": "Look at that NPC over there!",
		"TUTORIAL SHOW UPGRADE 2": "You can spend money on upgrades with them.",
		"TUTORIAL SHOW UPGRADE 3": "They'll help you mine faster and earn more!",
		"TUTORIAL DO UPGRADE 1": "Go near the NPC and press F!",
		"TUTORIAL DO UPGRADE 2": "Let's upgrade once!",
		"TUTORIAL DO UPGRADE 3": "(Press F near the money_up NPC)",
		"TUTORIAL UPGRADE COMPLETE 1": "Perfect! Now you can earn more money!",
		"TUTORIAL UPGRADE COMPLETE 2": "Shall we go deeper?",
		"TUTORIAL SHOW CAVE 1": "See that dark cave below?",
		"TUTORIAL SHOW CAVE 2": "There might be better minerals down there!",
		"TUTORIAL SHOW CAVE 3": "Let's go together!",
		"TUTORIAL BREAK WALL 1": "Break this wall to enter!",
		"TUTORIAL BREAK WALL 2": "Left-click to break walls.",
		"TUTORIAL BREAK WALL 3": "(Point at the wall and left-click)",
		"TUTORIAL BREAK PROGRESS": "Breaking wall...",
		"TUTORIAL ENTER CAVE": "Enter the cave!",
		"TUTORIAL GO DEEPER": "Go deeper into the cave!",
		"TUTORIAL TORCH 1": "Too dark! We need a torch.",
		"TUTORIAL TORCH 2": "Press 2 to switch to torch mode.",
		"TUTORIAL TORCH 3": "Then press B to place it!",
		"TUTORIAL TORCH 4": "(Press 2 → Point with mouse → Press B)",
		"TUTORIAL TORCH PLACED 1": "Nice! Much brighter now!",
		"TUTORIAL TORCH PLACED 2": "Do this whenever it's too dark.",
		"TUTORIAL TORCH PLACED 3": "Press 2 again to switch back to mining mode!",
		"TUTORIAL NEED MONEY 1": "Oops, not enough money for cave upgrades!",
		"TUTORIAL NEED MONEY 2": "Let's go back outside and mine more rocks.",
		"TUTORIAL NEED MONEY 3": "But the entrance is up there...",
		"TUTORIAL PLATFORM 1": "Let's head out! The entrance is up there...",
		"TUTORIAL PLATFORM 2": "Press 3 to switch to platform mode.",
		"TUTORIAL PLATFORM 3": "Stack platforms like stairs to climb up!",
		"TUTORIAL PLATFORM 4": "(Press 3 → Point with mouse → Press B repeatedly)",
		"TUTORIAL PLATFORM PROGRESS": "Placing platforms... Climb to the entrance!",
		"TUTORIAL COMPLETE 1": "Perfect! You've learned the basics!",
		"TUTORIAL COMPLETE 2": "I'll help you from now on!",
		"TUTORIAL COMPLETE 3": "You can also mine with J key now!",
		"TUTORIAL COMPLETE 4": "Let's discover the mine's secrets together!",
	}
}

## 번역된 텍스트를 가져온다
## @param key String 번역 키
## @returns String 번역된 텍스트
func get_text(key: String) -> String:
	if translations.has(current_language):
		var lang_dict = translations[current_language]
		if lang_dict.has(key):
			return lang_dict[key]
	# 키를 찾지 못하면 키 자체를 반환
	return key

# 설정 저장/로드
func save_settings() -> void:
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("locale", "language", current_language)
	config.set_value("auto_scene", "ui_scale", auto_ui_scale)
	config.set_value("auto_scene", "character_scale", auto_character_scale)
	config.set_value("tutorial", "is_completed", is_tutorial_completed)
	config.set_value("tutorial", "show_popup", show_tutorial_popup)
	# 업그레이드 해금 데이터 저장
	var unlock_str = ",".join(unlocked_upgrade_types.map(func(x): return str(x)))
	config.set_value("upgrades", "unlocked_types", unlock_str)
	var cave_str = ",".join(cave_items_found)
	config.set_value("upgrades", "cave_items", cave_str)
	# 요정 아이템 수집 데이터 저장
	var fairy_str = ",".join(collected_fairy_items)
	config.set_value("fairy", "collected_items", fairy_str)
	config.save("user://settings.cfg")
	
	# 오디오 버스에 볼륨 적용
	_apply_audio_settings()

func load_settings() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		# 파일이 없으면 기본값 사용
		return
	
	master_volume = config.get_value("audio", "master_volume", 1.0)
	bgm_volume = config.get_value("audio", "bgm_volume", 1.0)
	sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
	current_language = config.get_value("locale", "language", "ko")
	auto_ui_scale = config.get_value("auto_scene", "ui_scale", 1.0)
	auto_character_scale = config.get_value("auto_scene", "character_scale", 1.0)
	is_tutorial_completed = config.get_value("tutorial", "is_completed", false)
	show_tutorial_popup = config.get_value("tutorial", "show_popup", true)
	
	# 업그레이드 해금 데이터 로드
	var unlock_str = config.get_value("upgrades", "unlocked_types", "0")
	if unlock_str != "":
		unlocked_upgrade_types.clear()
		for s in unlock_str.split(",", false):
			unlocked_upgrade_types.append(int(s))
	# 동굴 아이템 데이터 로드
	var cave_str = config.get_value("upgrades", "cave_items", "")
	if cave_str != "":
		cave_items_found.assign(cave_str.split(",", false))
	else:
		cave_items_found.clear()
	# 요정 아이템 수집 데이터 로드
	var fairy_str = config.get_value("fairy", "collected_items", "")
	if fairy_str != "":
		collected_fairy_items.assign(fairy_str.split(",", false))
	else:
		collected_fairy_items.clear()
	
	# 오디오 버스에 볼륨 적용
	_apply_audio_settings()
	# 언어 적용
	_apply_language()

func _apply_audio_settings() -> void:
	# Master 버스 (인덱스 0)
	var master_db = linear_to_db(master_volume) if master_volume > 0 else -80.0
	AudioServer.set_bus_volume_db(0, master_db)
	
	# BGM 버스 (인덱스 1, 존재하는 경우)
	if AudioServer.bus_count > 1:
		var bgm_db = linear_to_db(bgm_volume) if bgm_volume > 0 else -80.0
		AudioServer.set_bus_volume_db(1, bgm_db)
	
	# SFX 버스 (인덱스 2, 존재하는 경우)
	if AudioServer.bus_count > 2:
		var sfx_db = linear_to_db(sfx_volume) if sfx_volume > 0 else -80.0
		AudioServer.set_bus_volume_db(2, sfx_db)

func _apply_language() -> void:
	# Godot의 번역 시스템 사용
	TranslationServer.set_locale(current_language)

# ========================================
# UI 클릭 사운드 시스템
# ========================================
# UI 클릭 효과음 (전역에서 재생 가능)
var _click_sfx_player: AudioStreamPlayer = null
var _click_sfx_stream = preload("res://CONCEPT/asset/ESM_SFSG_cinematic_fx_science_fiction_ui_general_positive_popup_window_synth_fast.wav")

## /** UI 클릭 사운드를 재생한다
##  * 어떤 씬에서든 Globals.play_click_sound() 로 호출 가능
##  * @returns void
##  */
func play_click_sound():
	if _click_sfx_player == null:
		_click_sfx_player = AudioStreamPlayer.new()
		_click_sfx_player.stream = _click_sfx_stream
		_click_sfx_player.volume_db = -5.0
		_click_sfx_player.bus = "Master"
		add_child(_click_sfx_player)
	_click_sfx_player.play()

# ========================================
# 액션 텍스트 시스템
# ========================================
# 액션 텍스트가 표시 중인지 (상호작용 가능 상태)
var is_action_text_visible: bool = false

# 액션 텍스트 표시
func show_action_text(text: String):
	is_action_text_visible = true
	action_text_changed.emit(text, true)

# 액션 텍스트 숨김
func hide_action_text():
	is_action_text_visible = false
	action_text_changed.emit("", false)

# ========================================
# 스킨 상점 관리 함수
# ========================================

## /** 기본 스킨 데이터를 초기화한다
##  * @returns void
##  */
func _initialize_skins() -> void:
	# bongo_cat_skins 폴더에서 모든 .tres 파일 로드
	# normal1, normal2가 초기 스킨으로 사용됨
	_load_skins_from_folder("res://bongo_cat_skins/")

## /** 폴더에서 스킨 리소스 파일들을 로드한다
##  * @param folder_path String 스킨 폴더 경로
##  * @returns void
##  */
func _load_skins_from_folder(folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	if dir == null:
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# .tres 파일만 처리
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var full_path = folder_path + file_name
			var skin_resource = load(full_path)
			
			if skin_resource is SkinItem:
				# 스킨 ID가 비어있으면 파일명을 ID로 사용
				if skin_resource.id == "":
					skin_resource.id = file_name.get_basename()
				
				# 이름이 비어있으면 ID를 이름으로 사용
				if skin_resource.name == "":
					skin_resource.name = skin_resource.id
				
				available_skins[skin_resource.id] = skin_resource
		
		file_name = dir.get_next()
	
	dir.list_dir_end()

## /** 스킨을 구매한다
##  * @param skin_id String 구매할 스킨 ID
##  * @returns bool 구매 성공 여부
##  */
func buy_skin(skin_id: String) -> bool:
	if not available_skins.has(skin_id):
		return false
	
	if is_skin_owned(skin_id):
		return false
	
	var skin: SkinItem = available_skins[skin_id]
	if auto_money < skin.price:
		return false
	
	auto_money -= skin.price
	owned_skins.append(skin_id)
	_save_skin_data()
	return true

## /** 스킨을 적용한다
##  * @param skin_id String 적용할 스킨 ID
##  * @returns bool 적용 성공 여부
##  */
func apply_skin(skin_id: String) -> bool:
	if not available_skins.has(skin_id):
		return false
	
	if not is_skin_owned(skin_id):
		return false
	
	var skin: SkinItem = available_skins[skin_id]
	# 스킨 타입에 따라 적용
	if skin.target_sprite == 1:
		current_sprite1_skin = skin_id
	else:
		current_sprite2_skin = skin_id
	
	_save_skin_data()
	skin_changed.emit(skin_id)
	return true

## /** 스킨을 소유하고 있는지 확인한다
##  * @param skin_id String 확인할 스킨 ID
##  * @returns bool 소유 여부
##  */
func is_skin_owned(skin_id: String) -> bool:
	return owned_skins.has(skin_id)

## /** 현재 Sprite1 스킨을 가져온다
##  * @returns SkinItem 현재 적용중인 Sprite1 스킨, 없으면 null
##  */
func get_current_sprite1_skin() -> SkinItem:
	if available_skins.has(current_sprite1_skin):
		return available_skins[current_sprite1_skin]
	# fallback: normal1 또는 첫 번째 스킨, 없으면 null
	if available_skins.has("normal1"):
		return available_skins["normal1"]
	if available_skins.size() > 0:
		return available_skins.values()[0]
	return null

## /** 현재 Sprite2 스킨을 가져온다
##  * @returns SkinItem 현재 적용중인 Sprite2 스킨, 없으면 null
##  */
func get_current_sprite2_skin() -> SkinItem:
	if available_skins.has(current_sprite2_skin):
		return available_skins[current_sprite2_skin]
	# fallback: normal2 또는 첫 번째 스킨, 없으면 null
	if available_skins.has("normal2"):
		return available_skins["normal2"]
	if available_skins.size() > 0:
		return available_skins.values()[0]
	return null

## /** 스킨 데이터를 저장한다
##  * @returns void
##  */
func _save_skin_data() -> void:
	var config = ConfigFile.new()
	config.set_value("skins", "owned_skins", ",".join(owned_skins))
	config.set_value("skins", "current_sprite1_skin", current_sprite1_skin)
	config.set_value("skins", "current_sprite2_skin", current_sprite2_skin)
	config.save("user://skins.cfg")

## /** 스킨 데이터를 로드한다
##  * @returns void
##  */
func _load_skin_data() -> void:
	var config = ConfigFile.new()
	var err = config.load("user://skins.cfg")
	if err != OK:
		return
	
	var owned_str = config.get_value("skins", "owned_skins", "normal1,normal2")
	if owned_str != "":
		# Array[String] 타입에 맞게 assign() 사용
		owned_skins.assign(owned_str.split(",", false))
	
	current_sprite1_skin = config.get_value("skins", "current_sprite1_skin", "normal1")
	current_sprite2_skin = config.get_value("skins", "current_sprite2_skin", "normal2")
