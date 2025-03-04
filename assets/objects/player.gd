extends Node2D
class_name Player

@export var pupil_offset: Vector2
@export var pupil_duration: float
@export var blink_time_min: float
@export var blink_time_max: float

@export var animation_player: AnimationPlayer
@export var pupils: Node2D
@export var blink_timer: Timer

func move_pupils(direction: Vector2) -> void:
	var tween := create_tween()
	tween.tween_property(
		pupils, "position", direction * pupil_offset, pupil_duration)

func start_player() -> void:
	animation_player.play("open_eyes")

func end_player() -> void:
	blink_timer.stop()
	
	animation_player.play("close_eyes")
	await animation_player.animation_finished
	queue_free()

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name != "open_eyes":
		return
	
	blink_timer.wait_time = randf_range(blink_time_min, blink_time_max)
	blink_timer.start()

func _on_blink_timer_timeout() -> void:
	animation_player.play("close_eyes")
	animation_player.queue("open_eyes")
