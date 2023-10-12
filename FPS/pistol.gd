extends ARMED


func _ready():
	animation_player = $AnimationPlayer
	animation_player.connect("animation_finished", on_animation_finished) 
#7:30 / 34:05     https://www.youtube.com/watch?v=EZ6IsMzgy9E&list=PLbwvgKpOTwZyrBDpdJzTVJzXskbjh7g5C&index=4



func _on_timer_timeout():
	ok_naw()
