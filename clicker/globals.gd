extends Node

# ========================================
# Signals - 다른 노드들이 구독할 수 있는 이벤트
# ========================================
signal money_changed(new_amount: int, delta: int)  # 돈이 변경될 때 (새 금액, 변화량)
signal tier_up(new_tier: int)  # 티어가 올라갈 때
signal action_text_changed(text: String, visible: bool)  # 액션 텍스트 변경 시그널
signal skin_changed(skin_id: String)  # 스킨이 변경될 때

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
	Vector2i(800, 16),    # Lv 4
	Vector2i(1250, 25),  # Lv 5
	Vector2i(2000, 30),  # Lv 6
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

# 채굴 티어 강화 (mt Lv) - 3레벨
# [가격, 해금 티어] 형식 - 티어가 높을수록 더 깊은 레이어의 돌을 캘 수 있음
var mining_tier_upgrades: Array[Vector2i] = [
	Vector2i(5000, 2),     # Lv 1: 티어 2 (layer 1~2 채굴 가능)
	Vector2i(60000, 3),    # Lv 2: 티어 3 (layer 1~3 채굴 가능)
	Vector2i(100000, 4),   # Lv 3 (MAX): 티어 4 (layer 1~4 채굴 가능)
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

# 채굴 키 개수 강화 (mk Lv) - 2레벨
# [가격, 총 키 개수] 형식 - 기본 2개에서 최대 4개까지
# 총 비용: 3,240 (기존 5,400 대비 약 40% 감소)
var mining_key_count_upgrades: Array[Vector2i] = [
	Vector2i(240, 3),      # Lv 1: 2개 → 3개 (D 추가)
	Vector2i(3000, 4),     # Lv 2 (MAX): 3개 → 4개 (K 추가)
]

# 돈 랜덤 강화 (mr Lv) - 5레벨
# [가격, x2확률(%), x3확률(%)] 형식 - 채굴 시 x2배, x3배 확률
# 기본값: x2 10%, x3 1%
var money_randomize_upgrades: Array[Vector3i] = [
	Vector3i(200, 15, 2),      # Lv 1: x2 15%, x3 2%
	Vector3i(600, 20, 4),      # Lv 2: x2 20%, x3 4%
	Vector3i(5000, 30, 8),     # Lv 3: x2 30%, x3 8%
	Vector3i(20000, 40, 12),   # Lv 4: x2 40%, x3 12%
	Vector3i(100000, 50, 20),  # Lv 5 (MAX): x2 50%, x3 20%
]

# 타일 채굴 보너스 강화 (rm Lv) - 실험적
# [가격, 추가 획득량] 형식 - 타일 돌을 캘 때 추가 보너스
var rock_money_upgrades: Array[Vector2i] = [
	Vector2i(100, 10),    # Lv 1: +10
	Vector2i(1000, 100),  # Lv 2 (MAX): +100
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
		# MAX 레벨 = 100
		rock_money_bonus = 100

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
		"AUTO GO BACK": "돌아가기",
		"AUTO SHOP": "상점",
		"AUTO SETTING": "설정",
		"AUTO SETTING TITLE": "설정",
		"AUTO UI SCALE": "UI 크기",
		"AUTO CHAR SCALE": "캐릭터 크기",
		"AUTO SETTING APPLY": "적용",
		"AUTO SETTING CLOSE": "닫기",
		"LOBBY PRESS KEY": "- 아무 키나 누르세요 -",
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
		"AUTO GO BACK": "Go Back",
		"AUTO SHOP": "Shop",
		"AUTO SETTING": "Settings",
		"AUTO SETTING TITLE": "Settings",
		"AUTO UI SCALE": "UI Scale",
		"AUTO CHAR SCALE": "Character",
		"AUTO SETTING APPLY": "Apply",
		"AUTO SETTING CLOSE": "Close",
		"LOBBY PRESS KEY": "- Press Any Key -",
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
# 액션 텍스트 시스템
# ========================================
# 액션 텍스트 표시
func show_action_text(text: String):
	action_text_changed.emit(text, true)

# 액션 텍스트 숨김
func hide_action_text():
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
##  * @returns SkinItem 현재 적용중인 Sprite1 스킨
##  */
func get_current_sprite1_skin() -> SkinItem:
	if available_skins.has(current_sprite1_skin):
		return available_skins[current_sprite1_skin]
	return available_skins["default_sprite1"]

## /** 현재 Sprite2 스킨을 가져온다
##  * @returns SkinItem 현재 적용중인 Sprite2 스킨
##  */
func get_current_sprite2_skin() -> SkinItem:
	if available_skins.has(current_sprite2_skin):
		return available_skins[current_sprite2_skin]
	return available_skins["default_sprite2"]

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
