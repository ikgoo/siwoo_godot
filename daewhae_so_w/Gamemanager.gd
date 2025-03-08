extends Node

var stars: Array[Node2D] = []
var stardust: int = 0
var speed_level: int = 1
var collect_level: int = 1
const SPEED_INCREASE = 50  # 레벨당 속도 증가량
const BASE_COLLECT_AMOUNT = 5  # 기본 수집량

func add_star(star: Node2D):
	stars.append(star)

func remove_star(star: Node2D):
	stars.erase(star)

func get_available_stars() -> Array[Node2D]:
	return stars

func get_current_speed() -> float:
	return 300.0 + (speed_level - 1) * SPEED_INCREASE

func get_collect_amount() -> int:
	return BASE_COLLECT_AMOUNT * collect_level 