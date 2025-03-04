extends Node2D

@export var player: Player

func _ready() -> void:
	get_window().size = Vector2i(512, 512)
	player.pupils.position = Vector2.RIGHT * player.pupil_offset
	
	await RenderingServer.frame_post_draw
	
	var image := get_viewport().get_texture().get_image()
	image.save_png("icon.png")
