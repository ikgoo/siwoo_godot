extends Area2D

#다음 맵 (인스펙터에서 씬 파일 고르기)
@export_file("*.tscn") var next_map : String

#플레이어가 f 눌렀을때 (character.gd 의 action_finder 가 불러줌)
func action() -> void:
	Gamemaneger.go_to_map(next_map)
