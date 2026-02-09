extends Node2D

## /** 업그레이드 해금 아이템 스크립트
##  * 동굴에 배치된 아이템으로, 캐릭터가 Area2D 근처에 오면
##  * "[F] 획득" 문구가 표시되고, F키를 눌러 획득합니다.
##  * 수집 시 해당 업그레이드 타입이 해금됩니다.
##  *
##  * 사용법:
##  *   1. upgrade_item.tscn을 씬에 인스턴스
##  *   2. 인스펙터에서 item_type 선택
##  */

# ========================================
# 아이템 종류 enum
# ========================================
enum UpgradeItemType {
	SPEED_SCROLL,    ## 속도의 두루마리 → 곡괭이 속도 업그레이드 해금
	LUCKY_CHARM,     ## 행운의 부적 → 돈 랜덤 확률 업그레이드 해금
	DEPTH_CRYSTAL,   ## 깊이의 수정 → 채굴 티어 업그레이드 해금
	AUTO_GEAR,       ## 자동화 톱니 → 자동 채굴 속도 업그레이드 해금
	MULTI_KEY_STONE, ## 다중 키스톤 → 채굴 키 개수 업그레이드 해금
	ROCK_HAMMER,     ## 바위 망치 → 타일 채굴 보너스 업그레이드 해금
}

# enum → Globals.cave_item_unlock_map 키 매핑
const ITEM_ID_MAP: Dictionary = {
	UpgradeItemType.SPEED_SCROLL: "speed_scroll",
	UpgradeItemType.LUCKY_CHARM: "lucky_charm",
	UpgradeItemType.DEPTH_CRYSTAL: "depth_crystal",
	UpgradeItemType.AUTO_GEAR: "auto_gear",
	UpgradeItemType.MULTI_KEY_STONE: "multi_key_stone",
	UpgradeItemType.ROCK_HAMMER: "rock_hammer",
}

# 아이템별 번역 키 (이름, 획득 문구)
const ITEM_KEYS: Dictionary = {
	UpgradeItemType.SPEED_SCROLL: {
		"name_key": "CAVE ITEM SPEED SCROLL",
		"acquire_key": "CAVE SPEED SCROLL",
	},
	UpgradeItemType.LUCKY_CHARM: {
		"name_key": "CAVE ITEM LUCKY CHARM",
		"acquire_key": "CAVE LUCKY CHARM",
	},
	UpgradeItemType.DEPTH_CRYSTAL: {
		"name_key": "CAVE ITEM DEPTH CRYSTAL",
		"acquire_key": "CAVE DEPTH CRYSTAL",
	},
	UpgradeItemType.AUTO_GEAR: {
		"name_key": "CAVE ITEM AUTO GEAR",
		"acquire_key": "CAVE AUTO GEAR",
	},
	UpgradeItemType.MULTI_KEY_STONE: {
		"name_key": "CAVE ITEM MULTI KEY",
		"acquire_key": "CAVE MULTI KEY",
	},
	UpgradeItemType.ROCK_HAMMER: {
		"name_key": "CAVE ITEM ROCK HAMMER",
		"acquire_key": "CAVE ROCK HAMMER",
	},
}

# ========================================
# Export 설정
# ========================================

## 아이템 종류 (인스펙터에서 드롭다운으로 선택)
@export var item_type: UpgradeItemType = UpgradeItemType.SPEED_SCROLL

# ========================================
# 노드 참조 (씬에서 미리 배치)
# ========================================
@onready var area_2d: Area2D = $Area2D
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var label: Label = $Label
@onready var glow_particles: GPUParticles2D = $GlowParticles

# ========================================
# 내부 변수
# ========================================
## 떠다니는 애니메이션용 시간
var float_time: float = 0.0
## 초기 Y 위치 (떠다니는 효과 기준점)
var original_y: float = 0.0
## 이미 수집했는지 여부
var is_collected: bool = false
## 플레이어가 상호작용 영역 안에 있는지
var is_character_inside: bool = false

func _ready():
	# 이미 획득한 아이템이면 제거
	var item_id = _get_item_id()
	if Globals.is_cave_item_found(item_id):
		queue_free()
		return
	
	# 초기 위치 저장 (떠다니는 효과용)
	original_y = position.y
	
	# Area2D 시그널 연결 (근접 감지용)
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.body_exited.connect(_on_body_exited)
	
	# 아이템 이름 라벨 표시
	if label:
		var keys = ITEM_KEYS.get(item_type, {})
		label.text = Globals.get_text(keys.get("name_key", ""))
		label.visible = true

func _process(delta):
	if is_collected:
		return
	
	# 떠다니는 효과 (위아래로 천천히 움직임)
	float_time += delta * 2.0
	if sprite_2d:
		sprite_2d.position.y = sin(float_time) * 3.0
	
	# 반짝이는 효과 (밝기 변화)
	var glow = 0.8 + sin(float_time * 1.5) * 0.2
	if sprite_2d:
		sprite_2d.modulate = Color(glow, glow, glow + 0.3)
	
	# 플레이어가 영역 안에 있을 때 F키 입력 처리
	if is_character_inside and Input.is_action_just_pressed("f"):
		is_collected = true
		_collect()

# ========================================
# 근접 감지 (Area2D 시그널)
# ========================================

## /** 플레이어가 아이템 영역에 들어왔을 때 - "[F] 획득" 표시
##  * @param body Node2D 충돌한 바디
##  */
func _on_body_entered(body):
	if is_collected:
		return
	if not body is CharacterBody2D:
		return
	
	is_character_inside = true
	# 하단에 "[F] 획득" 문구 표시
	var keys = ITEM_KEYS.get(item_type, {})
	var item_name = Globals.get_text(keys.get("name_key", "FAIRY ITEM DEFAULT"))
	Globals.show_action_text(Globals.get_text("FAIRY ACQUIRE FORMAT") % item_name)

## /** 플레이어가 아이템 영역에서 나갔을 때 - 문구 숨김
##  * @param body Node2D 충돌한 바디
##  */
func _on_body_exited(body):
	if not body is CharacterBody2D:
		return
	
	is_character_inside = false
	# 아직 수집 안 했으면 문구 숨김
	if not is_collected:
		Globals.hide_action_text()

# ========================================
# 수집 로직
# ========================================

## /** 아이템 수집 처리
##  * 1. Globals에 수집 기록 + 업그레이드 해금
##  * 2. 액션바에 acquire_message 표시
##  * 3. 수집 애니메이션 재생 후 제거
##  */
func _collect():
	# Globals에 아이템 수집 등록 (업그레이드 자동 해금)
	var item_id = _get_item_id()
	var success = Globals.collect_cave_item(item_id)
	
	# 파티클 끄기 (수집됐으므로)
	if glow_particles:
		glow_particles.emitting = false
	
	if success:
		# 액션바에 획득 문구 표시
		var keys = ITEM_KEYS.get(item_type, {})
		var msg = Globals.get_text(keys.get("acquire_key", "UPGRADE NEW UNLOCKED"))
		Globals.show_action_text(msg)
	
	# 수집 애니메이션 재생
	_play_collect_animation()

# ========================================
# 유틸리티
# ========================================

## /** enum 값을 문자열 item_id로 변환 (Globals 키와 매칭)
##  * @returns String 아이템 고유 ID
##  */
func _get_item_id() -> String:
	return ITEM_ID_MAP.get(item_type, "unknown")

## /** 수집 애니메이션을 재생하고 노드를 제거한다
##  */
func _play_collect_animation():
	# 위로 올라가면서 사라지는 효과
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# 크기도 약간 커지는 효과
	if sprite_2d:
		tween.tween_property(sprite_2d, "scale", Vector2(1.5, 1.5), 0.5)
	
	await tween.finished
	
	# 3초 후 액션 텍스트 숨김
	await get_tree().create_timer(3.0).timeout
	Globals.hide_action_text()
	
	queue_free()
