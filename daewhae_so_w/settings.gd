func _on_master_volume_slider_value_changed(value):
    Gamemaneger.set_master_volume(value)

func _on_music_volume_slider_value_changed(value):
    Gamemaneger.set_music_volume(value)

func _on_sfx_volume_slider_value_changed(value):
    Gamemaneger.set_sfx_volume(value) 