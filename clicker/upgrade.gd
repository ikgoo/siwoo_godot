extends Node2D

## /** 업그레이드 NPC 스크립트
##  * 하나의 NPC가 모든 업그레이드를 담당합니다.
##  * F키로 대화 → 업그레이드 메뉴 표시
##  * 구매 시 카메라 줌인 + NPC 모션 애니메이션 재생
##  *
##  * 사용법:
##  *   1. upgrade.tscn을 씬에 인스턴스 (하나만)
##  *   2. 플레이어가 다가가면 "[F] 대화하기" 표시
##  *   3. F키 → 업그레이드 메뉴 팝업
##  */

# ========================================
# 업그레이드 메뉴 씬 (동적 생성 — UI 오버레이)
# ========================================
const UPGRADE_MENU_SCENE = preload("res://upgrade_menu.tscn")

# ========================================
# Export 설정
# ========================================
@export var flip: bool = false

# ========================================
# 노드 참조 (씬에서 미리 배치)
# ========================================
@onready var area_2d: Area2D = $Area2D2
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var saying_label: Label = $saying if has_node("saying") else null

# ========================================
# 내부 변수
# ========================================
## 업그레이드 메뉴 인스턴스
var upgrade_menu: Control = null
## 플레이어가 영역 안에 있는지
var is_character_inside: bool = false
## 업그레이드 애니메이션 재생 중인지
var is_upgrade_animating: bool = false

# 자동 대사 관련
var idle_monologue_timer: float = randf_range(0.0, 8.0)
var idle_monologue_interval: float = 8.0
var idle_monologue_chance: float = 0.3

# NPC 혼잣말 번역 키 목록
var idle_monologue_keys: Array[String] = [
	"NPC IDLE 1", "NPC IDLE 2", "NPC IDLE 3", "NPC IDLE 4", "NPC IDLE 5",
]
var success_monologue_keys: Array[String] = [
	"NPC SUCCESS 1", "NPC SUCCESS 2", "NPC SUCCESS 3", "NPC SUCCESS 4",
]
var fail_monologue_keys: Array[String] = [
	"NPC FAIL 1", "NPC FAIL 2", "NPC FAIL 3",
]

func _ready():
	# 스프라이트 좌우반전
	if flip and sprite:
		sprite.flip_h = true
	
	# Area2D 시그널 연결
	if area_2d:
		area_2d.body_shape_entered.connect(_on_area_2d_body_shape_entered)
		area_2d.body_shape_exited.connect(_on_area_2d_body_shape_exited)

func _process(delta):
	# 자동 대사 타이머
	idle_monologue_timer += delta
	if idle_monologue_timer >= idle_monologue_interval:
		idle_monologue_timer = 0.0
		if randf() < idle_monologue_chance:
			_spawn_monologue_key(idle_monologue_keys)
	
	# 플레이어가 영역 안에 있고, 애니메이션 중이 아닐 때 F키로 메뉴 열기
	if is_character_inside and not is_upgrade_animating and Input.is_action_just_pressed("f"):
		# 메뉴가 이미 열려있으면 무시
		if upgrade_menu and upgrade_menu.visible:
			return
		_open_upgrade_menu()

# ========================================
# 업그레이드 메뉴
# ========================================

## /** 업그레이드 메뉴를 열어 CanvasLayer에 추가한다 */
func _open_upgrade_menu():
	# 메뉴 인스턴스가 없으면 생성
	if not upgrade_menu or not is_instance_valid(upgrade_menu):
		upgrade_menu = UPGRADE_MENU_SCENE.instantiate()
		
		# CanvasLayer에 추가 (UI 오버레이)
		var canvas_layer = get_tree().current_scene.get_node_or_null("CanvasLayer")
		if canvas_layer:
			canvas_layer.add_child(upgrade_menu)
		else:
			get_tree().current_scene.add_child(upgrade_menu)
		
		# 시그널 연결
		upgrade_menu.upgrade_purchased.connect(_on_upgrade_purchased)
		upgrade_menu.menu_closed.connect(_on_menu_closed)
	
	# 메뉴 열기
	upgrade_menu.open_menu()
	Globals.hide_action_text()

## /** 업그레이드 구매 완료 시 호출
##  * 카메라 줌인 + 1초 대기 + NPC 모션 애니메이션 재생
##  * @param type_id int 구매한 업그레이드 타입 ID
##  */
func _on_upgrade_purchased(type_id: int):
	_spawn_monologue_key(success_monologue_keys)
	play_upgrade_animation()

## /** 메뉴가 닫혔을 때 호출 (구매 없이 닫기) */
func _on_menu_closed():
	if is_character_inside and not is_upgrade_animating:
		Globals.show_action_text(Globals.get_text("NPC TALK"))

# ========================================
# 업그레이드 애니메이션 (카메라 줌 + NPC 모션)
# ========================================

## /** 업그레이드 구매 후 연출
##  * 1. 카메라를 NPC에 고정 + 줌인
##  * 2. NPC "motion" 애니메이션 바로 재생
##  * 3. 줌아웃 + 카메라 고정 해제
##  */
func play_upgrade_animation():
	if is_upgrade_animating:
		return
	is_upgrade_animating = true
	
	# 카메라 찾기 (camera 그룹)
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("lock_to_target") and camera.has_method("zoom_in"):
		# 1. 카메라를 NPC 위치로 고정 + 줌인
		camera.lock_to_target(global_position)
		camera.zoom_in(Vector2(5.0, 5.0), 0.5)
		
		# 줌 완료 대기
		if camera.has_method("wait_until_zoom_reached"):
			await camera.wait_until_zoom_reached(0.1, 1.0)
		else:
			await get_tree().create_timer(0.5).timeout
		
		# 2. NPC 모션 애니메이션 바로 재생 (루프 애니메이션이므로 길이만큼 대기)
		if animation_player:
			animation_player.play("motion")
			var anim_length = animation_player.current_animation_length
			await get_tree().create_timer(anim_length).timeout
			animation_player.play("idle")
		
		# 3. 줌아웃 + 고정 해제
		if camera.has_method("zoom_out"):
			camera.zoom_out(0.5)
			if camera.has_method("wait_until_zoom_reached"):
				await camera.wait_until_zoom_reached(0.1, 1.0)
			else:
				await get_tree().create_timer(0.5).timeout
		
		if camera.has_method("unlock_from_target"):
			camera.unlock_from_target()
	else:
		# 카메라가 없으면 애니메이션만 재생
		if animation_player:
			animation_player.play("motion")
			var anim_length = animation_player.current_animation_length
			await get_tree().create_timer(anim_length).timeout
			animation_player.play("idle")
	
	is_upgrade_animating = false
	
	# 메뉴가 닫혀있으면 액션 텍스트 다시 표시
	if is_character_inside and (not upgrade_menu or not upgrade_menu.visible):
		Globals.show_action_text(Globals.get_text("NPC TALK"))

# ========================================
# NPC 혼잣말 (saying 노드)
# ========================================

## /** 번역 키 목록에서 랜덤 혼잣말을 saying 라벨에 표시한다
##  * @param key_list Array[String] 번역 키 목록
##  */
func _spawn_monologue_key(key_list: Array[String]):
	if key_list.is_empty() or not saying_label:
		return
	
	var key = key_list[randi() % key_list.size()]
	saying_label.text = Globals.get_text(key)
	saying_label.visible = true
	
	# 2초 후 숨김
	await get_tree().create_timer(2.0).timeout
	if saying_label:
		saying_label.visible = false

# ========================================
# 근접 감지 (Area2D 시그널)
# ========================================

## /** 플레이어가 NPC 영역에 들어왔을 때 */
func _on_area_2d_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if body is CharacterBody2D:
		is_character_inside = true
		if not is_upgrade_animating:
			Globals.show_action_text(Globals.get_text("NPC TALK"))

## /** 플레이어가 NPC 영역에서 나갔을 때 */
func _on_area_2d_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	if body is CharacterBody2D:
		is_character_inside = false
		Globals.hide_action_text()
