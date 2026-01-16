extends Node

## 게임 매니저 (싱글톤)
## 게임 전체의 상태를 관리하고 멀티플레이 확장을 위한 준비

# 게임 상태
enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	GAME_OVER
}

var current_state: GameState = GameState.PLAYING

# 통계
var kills: int = 0
var deaths: int = 0
var shots_fired: int = 0
var shots_hit: int = 0

func _ready():
	print("GameManager 초기화 완료")

func pause_game():
	get_tree().paused = true
	current_state = GameState.PAUSED

func resume_game():
	get_tree().paused = false
	current_state = GameState.PLAYING

func reset_stats():
	kills = 0
	deaths = 0
	shots_fired = 0
	shots_hit = 0

func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return (float(shots_hit) / float(shots_fired)) * 100.0
