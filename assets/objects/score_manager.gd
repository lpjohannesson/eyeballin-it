extends Control
class_name ScoreManager

@export var label: Label
@export var high_label: Label
@export var add_label: Label
@export var add_timer: Timer
@export var animation_player: AnimationPlayer

var score := 0
var old_score := 0
var high_score := 0
var new_high_score := false

func update_score() -> void:
	# Show score
	label.text = str(score)
	
	# Check high score
	if high_score < score:
		high_score = score
		new_high_score = true
	
	high_label.text = "High: " + str(high_score)
	
	# Show difference
	var score_difference := score - old_score
	
	if score_difference <= 0:
		add_label.hide()
		return
	
	add_timer.start()
	add_label.text = "+" + str(score_difference)
	
	add_label.show() 
	animation_player.play("add")

func reset_score() -> void:
	score = 0
	old_score = 0
	new_high_score = false
	update_score()

func _on_add_timer_timeout() -> void:
	old_score = score
	animation_player.play("stop_add")
