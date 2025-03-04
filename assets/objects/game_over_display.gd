extends Control
class_name GameOverDisplay

@export var animation_player: AnimationPlayer
@export var score: ScoreManager
@export var new_high_score_label: Label
@export var continue_button: Button
@export var sounds: Sounds

var enabled := false

signal continue_pressed

func game_over() -> void:
	enabled = false
	
	show()
	animation_player.play("game_over")
	animation_player.advance(0.0)
	
	new_high_score_label.visible = score.new_high_score
	
	await animation_player.animation_finished
	enabled = true

func end_game_over() -> void:
	enabled = false
	animation_player.play("end")
	
	await animation_player.animation_finished
	hide()

func _on_continue_button_pressed() -> void:
	sounds.play_sound("Click")
	
	if not enabled:
		return
	
	enabled = false
	continue_pressed.emit()
