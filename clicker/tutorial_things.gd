extends Resource
class_name TutorialThings

## /** 튜토리얼 대사 및 설정 데이터를 담는 리소스 클래스
##  * 모든 튜토리얼 대사와 각 단계별 설정값을 관리합니다.
##  */

# ========================================
# 팝업 관련 대사 (번역 키)
# ========================================
var popup_title: String:
	get: return Globals.get_text("TUTORIAL POPUP TITLE")
var popup_question: String:
	get: return Globals.get_text("TUTORIAL POPUP QUESTION")
var popup_yes: String:
	get: return Globals.get_text("TUTORIAL POPUP YES")
var popup_no: String:
	get: return Globals.get_text("TUTORIAL POPUP NO")

# ========================================
# 인트로 대사 (요정 소개)
# ========================================
var intro_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL INTRO 1"),
		Globals.get_text("TUTORIAL INTRO 2"),
		Globals.get_text("TUTORIAL INTRO 3"),
		Globals.get_text("TUTORIAL INTRO 4"),
	]

# ========================================
# 돌 채굴 튜토리얼
# ========================================
var show_rock_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL SHOW ROCK 1"),
		Globals.get_text("TUTORIAL SHOW ROCK 2"),
		Globals.get_text("TUTORIAL SHOW ROCK 3"),
	]

var mine_rock_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL MINE ROCK 1"),
		Globals.get_text("TUTORIAL MINE ROCK 2"),
		Globals.get_text("TUTORIAL MINE ROCK 3"),
	]

var mine_rock_progress: String:
	get: return Globals.get_text("TUTORIAL MINE PROGRESS")
var mine_rock_complete: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL MINE COMPLETE 1"),
		Globals.get_text("TUTORIAL MINE COMPLETE 2"),
	]

# ========================================
# 업그레이드 튜토리얼
# ========================================
var show_upgrade_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL SHOW UPGRADE 1"),
		Globals.get_text("TUTORIAL SHOW UPGRADE 2"),
		Globals.get_text("TUTORIAL SHOW UPGRADE 3"),
	]

var do_upgrade_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL DO UPGRADE 1"),
		Globals.get_text("TUTORIAL DO UPGRADE 2"),
		Globals.get_text("TUTORIAL DO UPGRADE 3"),
	]

var upgrade_complete: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL UPGRADE COMPLETE 1"),
		Globals.get_text("TUTORIAL UPGRADE COMPLETE 2"),
	]

# ========================================
# 동굴 탐험 튜토리얼
# ========================================
var show_cave_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL SHOW CAVE 1"),
		Globals.get_text("TUTORIAL SHOW CAVE 2"),
		Globals.get_text("TUTORIAL SHOW CAVE 3"),
	]

var break_wall_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL BREAK WALL 1"),
		Globals.get_text("TUTORIAL BREAK WALL 2"),
		Globals.get_text("TUTORIAL BREAK WALL 3"),
	]

var break_wall_progress: String:
	get: return Globals.get_text("TUTORIAL BREAK PROGRESS")

# ========================================
# 횃불 설치 튜토리얼
# ========================================
var place_torch_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL TORCH 1"),
		Globals.get_text("TUTORIAL TORCH 2"),
		Globals.get_text("TUTORIAL TORCH 3"),
		Globals.get_text("TUTORIAL TORCH 4"),
	]

var torch_placed: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL TORCH PLACED 1"),
		Globals.get_text("TUTORIAL TORCH PLACED 2"),
		Globals.get_text("TUTORIAL TORCH PLACED 3"),
	]

# ========================================
# 돈 부족 안내
# ========================================
var need_money_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL NEED MONEY 1"),
		Globals.get_text("TUTORIAL NEED MONEY 2"),
		Globals.get_text("TUTORIAL NEED MONEY 3"),
	]

# ========================================
# 플랫폼 설치 튜토리얼
# ========================================
var place_platform_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL PLATFORM 1"),
		Globals.get_text("TUTORIAL PLATFORM 2"),
		Globals.get_text("TUTORIAL PLATFORM 3"),
		Globals.get_text("TUTORIAL PLATFORM 4"),
	]

var platform_progress: String:
	get: return Globals.get_text("TUTORIAL PLATFORM PROGRESS")

# ========================================
# 완료 대사
# ========================================
var tutorial_complete_dialogues: Array[String]:
	get: return [
		Globals.get_text("TUTORIAL COMPLETE 1"),
		Globals.get_text("TUTORIAL COMPLETE 2"),
		Globals.get_text("TUTORIAL COMPLETE 3"),
		Globals.get_text("TUTORIAL COMPLETE 4"),
	]

# ========================================
# 설정값
# ========================================
# 각 단계별 목표량
var mine_rock_target: int = 10  # 채굴해야 할 돌 개수
var platform_height_target: int = 3  # 쌓아야 할 플랫폼 높이

# 카메라 이동 시간
var camera_move_duration: float = 1.5
var camera_wait_duration: float = 1.0

# 대사 타이핑 속도
var typing_speed: float = 0.05  # 글자당 초
