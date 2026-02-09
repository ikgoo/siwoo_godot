extends Node2D

## /** 요정 능력 아이템 스크립트
##  * 맵에 배치된 아이템으로, 캐릭터가 Area2D 근처에 오면
##  * "[F] 획득" 문구가 표시되고, F키를 눌러 획득합니다.
##  *
##  * 사용법:
##  *   1. fairy_item.tscn을 씬에 인스턴스
##  *   2. 인스펙터에서 item_type 선택
##  */

# ========================================
# 아이템 종류 enum
# ========================================
enum FairyItemType {
	FAIRY_PICKAXE,   ## 요정 곡괭이 - 요정이 곡괭이를 들게 됨
	FAIRY_LIGHT,     ## 요정 빛 - 요정이 빛을 내게 됨 (횃불의 2/3)
}

# 아이템별 번역 키 (이름, 설명, 획득 문구)
const ITEM_KEYS: Dictionary = {
	FairyItemType.FAIRY_PICKAXE: {
		"name_key": "FAIRY PICKAXE NAME",
		"desc_key": "FAIRY PICKAXE DESC",
		"acquire_key": "FAIRY PICKAXE ACQUIRE",
	},
	FairyItemType.FAIRY_LIGHT: {
		"name_key": "FAIRY LIGHT NAME",
		"desc_key": "FAIRY LIGHT DESC",
		"acquire_key": "FAIRY LIGHT ACQUIRE",
	},
}

# ========================================
# Export 설정
# ========================================

## 아이템 종류 (인스펙터에서 드롭다운으로 선택)
@export var item_type: FairyItemType = FairyItemType.FAIRY_PICKAXE

# ========================================
# 노드 참조 (씬에서 미리 배치)
# ========================================
@onready var area_2d: Area2D = $Area2D
@onready var pickaxe_sprite: Sprite2D = $pickaxe
@onready var light_sprite: Sprite2D = $light
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
	if item_id in Globals.collected_fairy_items:
		queue_free()
		return
	
	# 초기 위치 저장 (떠다니는 효과용)
	original_y = position.y
	
	# Area2D 시그널 연결 (근접 감지용)
	if area_2d:
		area_2d.body_entered.connect(_on_body_entered)
		area_2d.body_exited.connect(_on_body_exited)
	
	# item_type에 맞는 스프라이트만 표시
	_update_sprite_visibility()
	
	# 아이템 이름 라벨 표시
	if label:
		var keys = ITEM_KEYS.get(item_type, {})
		label.text = Globals.get_text(keys.get("name_key", ""))
		label.visible = true

## /** item_type에 맞는 스프라이트만 보이게 전환한다
##  * @returns void
##  */
func _update_sprite_visibility():
	if pickaxe_sprite:
		pickaxe_sprite.visible = (item_type == FairyItemType.FAIRY_PICKAXE)
	if light_sprite:
		light_sprite.visible = (item_type == FairyItemType.FAIRY_LIGHT)

## /** 현재 활성화된 스프라이트를 반환한다
##  * @returns Sprite2D 현재 보이는 스프라이트
##  */
func _get_active_sprite() -> Sprite2D:
	match item_type:
		FairyItemType.FAIRY_PICKAXE:
			return pickaxe_sprite
		FairyItemType.FAIRY_LIGHT:
			return light_sprite
	return null

func _process(delta):
	if is_collected:
		return
	
	var active_sprite = _get_active_sprite()
	
	# 떠다니는 효과 (위아래로 천천히 움직임)
	float_time += delta * 2.0
	if active_sprite:
		active_sprite.position.y = sin(float_time) * 3.0
	
	# 반짝이는 효과 (밝기 변화)
	var glow = 0.8 + sin(float_time * 1.5) * 0.2
	if active_sprite:
		active_sprite.modulate = Color(glow, glow, glow + 0.3)
	
	# 플레이어가 영역 안에 있을 때 F키 입력 처리
	if is_character_inside and Input.is_action_just_pressed("f"):
		is_collected = true
		_collect()

# ========================================
# 근접 감지 (Area2D 시그널)
# ========================================

## /** 플레이어가 아이템 영역에 들어왔을 때 - "[F] 획득" 표시
##  * @param body Node2D 충돌한 바디
##  * @returns void
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
##  * @returns void
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
##  * 1. Globals에 수집 기록
##  * 2. enum에 맞는 효과 적용
##  * 3. 액션바에 acquire_message 표시
##  * 4. 수집 애니메이션 재생 후 제거
##  * @returns void
##  */
func _collect():
	# Globals에 수집 기록 (중복 획득 방지)
	var item_id = _get_item_id()
	if item_id not in Globals.collected_fairy_items:
		Globals.collected_fairy_items.append(item_id)
		Globals.save_settings()
	
	# 파티클 끄기 (수집됐으므로)
	if glow_particles:
		glow_particles.emitting = false
	
	# enum에 맞는 효과 적용
	_apply_effect()
	
	# 액션바에 획득 문구 표시
	var keys = ITEM_KEYS.get(item_type, {})
	var msg = Globals.get_text(keys.get("acquire_key", "FAIRY ACQUIRE DEFAULT"))
	Globals.show_action_text(msg)
	
	# 수집 애니메이션 재생
	_play_collect_animation()

# ========================================
# 효과 적용 (enum별로 분기)
# ========================================

## /** 아이템 종류에 따라 효과를 적용한다
##  * 새 아이템을 추가하면 여기에 match 분기를 추가하면 됩니다
##  * @returns void
##  */
func _apply_effect():
	match item_type:
		FairyItemType.FAIRY_PICKAXE:
			_effect_fairy_pickaxe()
		FairyItemType.FAIRY_LIGHT:
			_effect_fairy_light()

## /** 요정 곡괭이 효과
##  * 요정의 AnimatedSprite2D를 pickaxe_less → default로 변경
##  * @returns void
##  */
func _effect_fairy_pickaxe():
	# fairy 그룹에서 요정을 찾아 곡괭이 모드 활성화
	var fairies = get_tree().get_nodes_in_group("fairy")
	for fairy in fairies:
		if fairy.has_method("set_pickaxe_mode"):
			fairy.set_pickaxe_mode(true)

## /** 요정 빛 효과
##  * 요정의 PointLight2D를 활성화 (횃불의 2/3 밝기)
##  * @returns void
##  */
func _effect_fairy_light():
	# fairy 그룹에서 요정을 찾아 빛 활성화
	var fairies = get_tree().get_nodes_in_group("fairy")
	for fairy in fairies:
		if fairy.has_method("enable_fairy_light"):
			fairy.enable_fairy_light()

# ========================================
# 유틸리티
# ========================================

## /** enum 값을 문자열 ID로 변환 (저장용)
##  * @returns String 아이템 고유 ID
##  */
func _get_item_id() -> String:
	return FairyItemType.keys()[item_type].to_lower()

## /** 수집 애니메이션을 재생하고 노드를 제거한다
##  * @returns void
##  */
func _play_collect_animation():
	# 위로 올라가면서 사라지는 효과
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 30, 0.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# 크기도 약간 커지는 효과
	var active_sprite = _get_active_sprite()
	if active_sprite:
		tween.tween_property(active_sprite, "scale", Vector2(1.5, 1.5), 0.5)
	
	await tween.finished
	
	# 3초 후 액션 텍스트 숨김
	await get_tree().create_timer(3.0).timeout
	Globals.hide_action_text()
	
	queue_free()
