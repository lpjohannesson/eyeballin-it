extends Node
class_name Sounds

func play_sound(sound_name: String):
	var sound: AudioStreamPlayer = get_node(sound_name)
	sound.play()
