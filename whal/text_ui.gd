extends CanvasLayer
#내가 만든 대화창 (dialogue manager 기본 ballon 대신 쓰는거)

#대화 리소스랑 시작 지점
@export var dialogue_resource: DialogueResource
@export var start_from_title: String = ""

#다음 줄로 넘기는 키 / 타이핑 스킵하는 키
var next_action: StringName = &"ui_accept"
var skip_action: StringName = &"ui_cancel"

#변수
var temporary_game_states: Array = []
var is_waiting_for_input: bool = false
var will_hide_balloon: bool = false
#뮤테이션 돌아가는 동안 잠깐 숨기는 타이머
var mutation_cooldown: Timer = Timer.new()

#얘들
@onready var balloon = $Balloon
@onready var panel = $Balloon/Panel
@onready var character_label = $Balloon/CharacterLabel
@onready var dialogue_label = $Balloon/DialogueLabel
@onready var responses_menu = $Balloon/ResponsesMenu
@onready var line_2d = $Balloon/Line2D

#지금 보여주는 대화 한 줄
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			#대화 끝나면 창 없애기
			Gamemaneger.talking = false
			queue_free()
	get:
		return dialogue_line

func _ready() -> void:
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

#대화중엔 다른데로 입력 안넘김
func _unhandled_input(_event: InputEvent) -> void:
	get_viewport().set_input_as_handled()

#대화 시작
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	Gamemaneger.talking = true
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()

#대화 한 줄 화면에 뿌리기
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	#말하는 사람 이름 (이름 없으면 숨김)
	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	balloon.show()
	will_hide_balloon = false

	#한글자씩 타이핑
	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	#선택지가 있으면 버튼 보여주기
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	#시간 지나면 자동으로 넘어가는 줄
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	#아니면 입력 기다리기
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()

#다음 줄로
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)

#클릭하거나 키 눌렀을때
func _on_balloon_gui_input(event: InputEvent) -> void:
	#타이핑 중이면 먼저 전부 다 보여주기
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)

#선택지 골랐을때
func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()

func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)
