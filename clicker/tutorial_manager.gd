extends Node
class_name TutorialManager

## /** 튜토리얼 전체 진행을 관리하는 매니저
##  * 팝업, 대화, 카메라 연출, 단계별 진행을 제어합니다.
##  */

# ========================================
# 튜토리얼 단계 enum
# ========================================
enum TutorialStep {
	NONE,            # 튜토리얼 비활성
	POPUP,           # 팝업 표시
	INTRO,           # 요정 소개
	SHOW_ROCK,       # 돌 위치 카메라
	MINE_ROCK,       # F키로 20개 채굴
	SHOW_UPGRADE,    # 업그레이드 NPC 카메라
	DO_UPGRADE,      # 업그레이드 1번
	SHOW_CAVE,       # Layer4 동굴 카메라
	BREAK_WALL,      # 좌클릭으로 벽 부수기
	PLACE_TORCH,     # 2키로 횃불 설치
	GO_BACK,         # 돈 부족하면 돌 캐러 가기
	PLACE_PLATFORM,  # 3키로 플랫폼 쌓기
	COMPLETE         # 튜토리얼 완료
}

# ========================================
# 현재 상태
# ========================================
var current_step: TutorialStep = TutorialStep.NONE
var is_tutorial_active: bool = false

# ========================================
# 진행도 추적
# ========================================
var mined_rock_count: int = 0
var upgrade_count: int = 0
var torch_placed: bool = false
var platform_count: int = 0
var initial_money: int = 0

# ========================================
# 참조
# ========================================
var tutorial_data: TutorialThings
var dialogue_box: DialogueBox
var player: CharacterBody2D
var camera: Camera2D
var popup_panel: Panel

# 노드 참조 (씬에서 찾을 것들)
var first_rock: Node2D
var money_up_npc: Node2D
var cave_entrance: Vector2  # Layer4 동굴 입구 위치

# Fairy 씬
var fairy_scene: PackedScene = preload("res://fairy.tscn")
var fairy_instance: Fairy = null

# ========================================
# 시그널
# ========================================
signal tutorial_started()
signal tutorial_completed()

func _ready():
	print("🎯 [튜토리얼] TutorialManager _ready 호출됨")
	
	# 튜토리얼 이미 완료했으면 시작 안 함
	if Globals.is_tutorial_completed:
		print("⏭️ [튜토리얼] 이미 완료됨 - 스킵")
		return
	
	# 팝업 표시 설정이 꺼져있으면 시작 안 함
	if not Globals.show_tutorial_popup:
		print("⏭️ [튜토리얼] 팝업 표시 설정 꺼짐 - 스킵")
		return
	
	print("✅ [튜토리얼] 조건 통과 - 튜토리얼 시작 준비")
	
	# 튜토리얼 데이터 로드
	tutorial_data = TutorialThings.new()
	print("✅ [튜토리얼] 데이터 로드 완료")
	
	# 다음 프레임에 초기화 (모든 노드가 준비된 후)
	call_deferred("initialize_tutorial")

## /** 튜토리얼 초기화
##  * @returns void
##  */
func initialize_tutorial():
	print("🔧 [튜토리얼] 초기화 시작")
	
	# 플레이어 참조
	player = Globals.player
	if not player:
		print("❌ [튜토리얼] 플레이어를 찾을 수 없음!")
		return
	print("✅ [튜토리얼] 플레이어 찾음:", player.name)
	
	# 카메라 참조
	var cameras = get_tree().get_nodes_in_group("camera")
	if not cameras.is_empty():
		camera = cameras[0]
		print("✅ [튜토리얼] 카메라 찾음:", camera.name)
	
	# 대화창 생성
	create_dialogue_box()
	
	# 팝업 표시
	print("📋 [튜토리얼] 팝업 표시 시작")
	show_popup()

## /** 대화창 UI 생성
##  * @returns void
##  */
func create_dialogue_box():
	var dialogue_scene = load("res://dialogue_box.tscn")
	if dialogue_scene:
		dialogue_box = dialogue_scene.instantiate()
		get_tree().current_scene.get_node("CanvasLayer").add_child(dialogue_box)
		dialogue_box.dialogue_all_complete.connect(_on_dialogue_complete)

## /** 튜토리얼 시작 팝업 표시
##  * @returns void
##  */
func show_popup():
	# 팝업 패널 생성
	popup_panel = Panel.new()
	popup_panel.set_anchors_preset(Control.PRESET_CENTER)
	popup_panel.position = Vector2(-200, -100)
	popup_panel.size = Vector2(400, 200)
	popup_panel.z_index = 1000
	
	# 일시정지 중에도 작동하도록 설정 (중요!)
	popup_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 배경 스타일
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	popup_panel.add_theme_stylebox_override("panel", style)
	
	# VBox 컨테이너
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	popup_panel.add_child(vbox)
	
	# 제목
	var title_label = Label.new()
	title_label.text = tutorial_data.popup_title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
	vbox.add_child(title_label)
	
	# 설명
	var desc_label = Label.new()
	desc_label.text = tutorial_data.popup_question
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.custom_minimum_size = Vector2(380, 0)
	vbox.add_child(desc_label)
	
	# 버튼 컨테이너
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)
	
	# 예 버튼
	var yes_button = Button.new()
	yes_button.text = tutorial_data.popup_yes
	yes_button.custom_minimum_size = Vector2(120, 40)
	yes_button.process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 클릭 가능
	yes_button.pressed.connect(_on_popup_yes)
	hbox.add_child(yes_button)
	print("✅ 예 버튼 생성 및 시그널 연결 완료")
	
	# 아니오 버튼
	var no_button = Button.new()
	no_button.text = tutorial_data.popup_no
	no_button.custom_minimum_size = Vector2(120, 40)
	no_button.process_mode = Node.PROCESS_MODE_ALWAYS  # 일시정지 중에도 클릭 가능
	no_button.pressed.connect(_on_popup_no)
	hbox.add_child(no_button)
	print("✅ 아니오 버튼 생성 및 시그널 연결 완료")
	
	# 씬에 추가
	get_tree().current_scene.get_node("CanvasLayer").add_child(popup_panel)
	
	# 게임 일시정지
	get_tree().paused = true

## /** 팝업 "예" 버튼 클릭
##  * @returns void
##  */
func _on_popup_yes():
	print("🟢 [튜토리얼] 예 버튼 클릭됨!")
	popup_panel.queue_free()
	get_tree().paused = false
	start_tutorial()

## /** 팝업 "아니오" 버튼 클릭
##  * @returns void
##  */
func _on_popup_no():
	print("🔴 [튜토리얼] 아니오 버튼 클릭됨!")
	popup_panel.queue_free()
	get_tree().paused = false
	# 튜토리얼 완료 처리 (다시 안 뜨게)
	Globals.is_tutorial_completed = true
	Globals.save_settings()

## /** 튜토리얼 시작
##  * @returns void
##  */
func start_tutorial():
	print("🎬 [튜토리얼] 튜토리얼 시작!")
	is_tutorial_active = true
	Globals.is_tutorial_active = true
	current_step = TutorialStep.INTRO
	tutorial_started.emit()
	
	# 초기 돈 기록
	initial_money = Globals.money
	
	# 인트로 대화 시작
	if dialogue_box:
		print("💬 [튜토리얼] 대화창 시작 - 인트로 대화")
		dialogue_box.start_dialogue(tutorial_data.intro_dialogues, tutorial_data.typing_speed)
	else:
		print("❌ [튜토리얼] 대화창이 없음!")

## /** 대화 완료 콜백
##  * @returns void
##  */
func _on_dialogue_complete():
	print("📢 [튜토리얼] 대화 완료 콜백 호출됨 - 현재 단계: ", current_step)
	# 현재 단계에 따라 다음 행동
	match current_step:
		TutorialStep.INTRO:
			print("  → INTRO 완료, SHOW_ROCK으로")
			advance_to_show_rock()
		TutorialStep.SHOW_ROCK:
			print("  → SHOW_ROCK 완료, MINE_ROCK으로")
			advance_to_mine_rock()
		TutorialStep.MINE_ROCK:
			print("  → MINE_ROCK - 채굴 중 (대기)")
			pass  # 채굴 중에는 대기
		TutorialStep.SHOW_UPGRADE:
			print("  → SHOW_UPGRADE 완료, DO_UPGRADE로")
			advance_to_do_upgrade()
		TutorialStep.DO_UPGRADE:
			print("  → DO_UPGRADE - 업그레이드 대기")
			pass  # 업그레이드 대기
		TutorialStep.SHOW_CAVE:
			print("  → SHOW_CAVE 완료, BREAK_WALL로")
			advance_to_break_wall()
		TutorialStep.BREAK_WALL:
			print("  → BREAK_WALL - 벽 부수기 대기")
			pass  # 벽 부수기 대기
		TutorialStep.PLACE_TORCH:
			print("  → PLACE_TORCH - 횃불 설치 대기")
			pass  # 횃불 설치 대기
		TutorialStep.GO_BACK:
			print("  → GO_BACK 완료, PLACE_PLATFORM으로")
			advance_to_place_platform()
		TutorialStep.PLACE_PLATFORM:
			print("  → PLACE_PLATFORM - 플랫폼 쌓기 대기")
			pass  # 플랫폼 쌓기 대기
		TutorialStep.COMPLETE:
			print("  → COMPLETE, 튜토리얼 종료")
			finish_tutorial()

## /** 돌 보여주기 단계로 진행
##  * @returns void
##  */
func advance_to_show_rock():
	current_step = TutorialStep.SHOW_ROCK
	
	# 첫 번째 rock 찾기
	var rocks = get_tree().get_nodes_in_group("rocks")
	if not rocks.is_empty():
		first_rock = rocks[0]
		
		# 카메라를 돌로 이동
		if camera and camera.has_method("lock_to_target"):
			camera.lock_to_target(first_rock.global_position)
		
		# 대화 시작
		await get_tree().create_timer(tutorial_data.camera_move_duration).timeout
		if dialogue_box:
			dialogue_box.start_dialogue(tutorial_data.show_rock_dialogues, tutorial_data.typing_speed)

## /** 돌 캐기 단계로 진행
##  * @returns void
##  */
func advance_to_mine_rock():
	current_step = TutorialStep.MINE_ROCK
	mined_rock_count = 0
	
	# 카메라 고정 해제
	if camera and camera.has_method("unlock_from_target"):
		camera.unlock_from_target()
	
	# 대화 시작
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.mine_rock_dialogues, tutorial_data.typing_speed)
	
	# Globals 시그널 구독 (돈 변경 감지)
	if not Globals.money_changed.is_connected(_on_money_changed_during_mining):
		Globals.money_changed.connect(_on_money_changed_during_mining)

## /** 채굴 중 돈 변경 감지
##  * @returns void
##  */
func _on_money_changed_during_mining(new_amount: int, delta: int):
	if current_step != TutorialStep.MINE_ROCK:
		return
	
	if delta > 0:
		mined_rock_count += delta
		print("⛏️ [튜토리얼] 채굴 진행: %d / %d" % [mined_rock_count, tutorial_data.mine_rock_target])
		
		# 진행도 표시
		Globals.show_action_text(tutorial_data.mine_rock_progress % mined_rock_count)
		
		# 20개 달성
		if mined_rock_count >= tutorial_data.mine_rock_target:
			print("✅ [튜토리얼] 20개 달성! 완료 대화 시작")
			Globals.money_changed.disconnect(_on_money_changed_during_mining)
			Globals.hide_action_text()
			
			# 단계를 미리 변경 (MINE_ROCK_COMPLETE 임시 상태)
			current_step = TutorialStep.SHOW_UPGRADE  # 미리 변경해서 _on_dialogue_complete가 작동하도록
			
			# 완료 대화
			if dialogue_box:
				dialogue_box.start_dialogue(tutorial_data.mine_rock_complete, tutorial_data.typing_speed)
				# 대화 끝나면 _on_dialogue_complete가 자동으로 호출됨
			else:
				print("❌ [튜토리얼] 대화창 없음 - 바로 다음 단계로")
				advance_to_show_upgrade()

## /** 업그레이드 NPC 보여주기
##  * @returns void
##  */
func advance_to_show_upgrade():
	print("🎯 [튜토리얼] SHOW_UPGRADE 단계 시작")
	current_step = TutorialStep.SHOW_UPGRADE
	
	# money_up 타입의 upgrade NPC 찾기
	var all_nodes = get_tree().get_nodes_in_group("upgrade")
	print("  🔍 upgrade 그룹 노드 수: ", all_nodes.size())
	for node in all_nodes:
		if node.has("type"):
			print("    - ", node.name, " type: ", node.type)
			if node.type == 0:  # money_up = 0
				money_up_npc = node
				print("    ✅ money_up NPC 발견!")
				break
	
	if money_up_npc:
		print("  📹 카메라를 NPC로 이동: ", money_up_npc.global_position)
		# 카메라를 NPC로 이동
		if camera and camera.has_method("lock_to_target"):
			camera.lock_to_target(money_up_npc.global_position)
		
		# 대화 시작
		print("  ⏳ 카메라 이동 대기 중...")
		await get_tree().create_timer(tutorial_data.camera_move_duration).timeout
		print("  💬 업그레이드 안내 대화 시작")
		if dialogue_box:
			dialogue_box.start_dialogue(tutorial_data.show_upgrade_dialogues, tutorial_data.typing_speed)
	else:
		print("  ❌ money_up NPC를 찾을 수 없음!")

## /** 업그레이드 실행 단계
##  * @returns void
##  */
func advance_to_do_upgrade():
	current_step = TutorialStep.DO_UPGRADE
	upgrade_count = 0
	
	# 카메라 고정 해제
	if camera and camera.has_method("unlock_from_target"):
		camera.unlock_from_target()
	
	# 대화 시작
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.do_upgrade_dialogues, tutorial_data.typing_speed)
	
	# 다이아몬드 획득량 레벨 변경 감지
	var initial_level = Globals.diamond_value_level
	while Globals.diamond_value_level == initial_level:
		await get_tree().process_frame
	
	# 업그레이드 완료
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.upgrade_complete, tutorial_data.typing_speed)
		await dialogue_box.dialogue_all_complete
	
	# 다음 단계
	advance_to_show_cave()

## /** 동굴 보여주기
##  * @returns void
##  */
func advance_to_show_cave():
	current_step = TutorialStep.SHOW_CAVE
	
	# 동굴 입구 위치 (고정 좌표)
	cave_entrance = Vector2(-112, 48)
	
	# 카메라를 동굴로 이동
	if camera and camera.has_method("lock_to_target"):
		camera.lock_to_target(cave_entrance)
	
	# 대화 시작
	await get_tree().create_timer(tutorial_data.camera_move_duration).timeout
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.show_cave_dialogues, tutorial_data.typing_speed)
		await dialogue_box.dialogue_all_complete
	
	# 다음 단계
	advance_to_break_wall()

## /** 벽 부수기 단계
##  * @returns void
##  */
func advance_to_break_wall():
	current_step = TutorialStep.BREAK_WALL
	
	# 카메라 고정 해제
	if camera and camera.has_method("unlock_from_target"):
		camera.unlock_from_target()
	
	# 대화 시작
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.break_wall_dialogues, tutorial_data.typing_speed)
	
	# 벽이 부서질 때까지 대기 (간단히 일정 시간 후 다음 단계)
	await get_tree().create_timer(10.0).timeout
	
	# 다음 단계
	advance_to_place_torch()

## /** 횃불 설치 단계
##  * @returns void
##  */
func advance_to_place_torch():
	current_step = TutorialStep.PLACE_TORCH
	torch_placed = false
	
	# 대화 시작
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.place_torch_dialogues, tutorial_data.typing_speed)
	
	# 횃불이 설치될 때까지 대기 (torches 그룹 모니터링)
	var initial_torch_count = get_tree().get_nodes_in_group("torches").size()
	while get_tree().get_nodes_in_group("torches").size() <= initial_torch_count:
		await get_tree().create_timer(0.5).timeout
	
	torch_placed = true
	
	# 완료 대화
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.torch_placed, tutorial_data.typing_speed)
		await dialogue_box.dialogue_all_complete
	
	# 다음 단계
	advance_to_go_back()

## /** 돌아가기 안내 단계
##  * @returns void
##  */
func advance_to_go_back():
	current_step = TutorialStep.GO_BACK
	
	# 대화 시작
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.need_money_dialogues, tutorial_data.typing_speed)
		await dialogue_box.dialogue_all_complete
	
	# 플랫폼 설치 단계로
	advance_to_place_platform()

## /** 플랫폼 설치 단계
##  * @returns void
##  */
func advance_to_place_platform():
	current_step = TutorialStep.PLACE_PLATFORM
	platform_count = 0
	
	# 대화 시작
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.place_platform_dialogues, tutorial_data.typing_speed)
	
	# 플레이어가 일정 높이 이상 올라갈 때까지 대기
	var start_y = player.global_position.y
	while (start_y - player.global_position.y) < (tutorial_data.platform_height_target * 16):
		await get_tree().create_timer(0.5).timeout
		Globals.show_action_text(tutorial_data.platform_progress)
	
	Globals.hide_action_text()
	
	# 튜토리얼 완료
	advance_to_complete()

## /** 튜토리얼 완료 단계
##  * @returns void
##  */
func advance_to_complete():
	current_step = TutorialStep.COMPLETE
	
	# 완료 대화
	if dialogue_box:
		dialogue_box.start_dialogue(tutorial_data.tutorial_complete_dialogues, tutorial_data.typing_speed)
		await dialogue_box.dialogue_all_complete
	
	# 튜토리얼 종료 처리
	finish_tutorial()

## /** 튜토리얼 종료
##  * @returns void
##  */
func finish_tutorial():
	is_tutorial_active = false
	Globals.is_tutorial_active = false
	Globals.is_tutorial_completed = true
	Globals.save_settings()
	
	# 요정 스폰
	spawn_fairy()
	
	tutorial_completed.emit()
	
	print("✅ 튜토리얼 완료!")

## /** 요정 스폰
##  * @returns void
##  */
func spawn_fairy():
	if fairy_scene:
		fairy_instance = fairy_scene.instantiate()
		fairy_instance.player = player
		get_tree().current_scene.add_child(fairy_instance)
		
		# 플레이어 뒤쪽에 배치
		fairy_instance.global_position = player.global_position + Vector2(-30, 0)
		
		print("✅ 요정 스폰 완료!")

