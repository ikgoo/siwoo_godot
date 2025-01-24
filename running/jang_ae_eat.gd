extends Node3D

@onready var charater = $"../Jet"
# Called when the node enters the scene tree for the first time.
func _ready():
	if Gamemanager.here == "earth":
		scale = scale / 4


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if position.z - 10 > charater.position.z:
		queue_free()


func _on_area_3d_area_entered(area):
	charater.audio_stream_player_3d.playing = true
	Gamemanager.jumsu += 1000
