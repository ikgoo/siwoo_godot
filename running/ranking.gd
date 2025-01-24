extends Control
@onready var _1 = $"1"
@onready var _2 = $"2"
@onready var _3 = $"3"
@onready var _4 = $"4"
@onready var _5 = $"5"
@onready var _6 = $"6"
@onready var _7 = $"7"
@onready var _8 = $"8"
@onready var audio_stream_player = $AudioStreamPlayer


# Called when the node enters the scene tree for the first time.
func _ready():
	FirebaseData.data_loaded.connect(_on_data_loaded)



func _process(delta):
	FirebaseData.load_data("jet_flying","high_score")

func _on_out_button_down():
	get_tree().change_scene_to_file("res://start_ui.tscn")
	

func _on_data_loaded(rank_data):
	if len(FirebaseData.current_rankings) != 0:
		_1.text = str("1. " + FirebaseData.current_rankings[0]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[0]["score"]) + "p")
		_2.text = str("2. " + FirebaseData.current_rankings[1]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[1]["score"]) + "p")
		_3.text = str("3. " + FirebaseData.current_rankings[2]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[2]["score"]) + "p")
		_4.text = str("4. " + FirebaseData.current_rankings[3]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[3]["score"]) + "p")
		_5.text = str("5. " + FirebaseData.current_rankings[4]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[4]["score"]) + "p")
		_6.text = str("6. " + FirebaseData.current_rankings[5]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[5]["score"]) + "p")
		_7.text = str("7. " + FirebaseData.current_rankings[6]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[6]["score"]) + "p")
		_8.text = str("8. " + FirebaseData.current_rankings[7]["name"].replace("\n", "") + " : " + str(FirebaseData.current_rankings[7]["score"]) + "p")


func _on_audio_stream_player_finished():
	audio_stream_player.play()
