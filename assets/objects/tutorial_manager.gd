extends Control
class_name TutorialManager

@export var game: Game
@export var ui: Control
@export var ui_player: AnimationPlayer
@export var hand: TutorialHand

var enabled := false
var position_queue := []
var direction_queue := []

func move_hand():
	var hand_position: Vector2i = position_queue.front()
	
	hand.global_position = \
		game.get_grid_button(hand_position).get_ball_position()
	
	hand.direction = direction_queue.front()
	
	if game.selected_position == hand_position:
		hand.animation_player.stop()
		hand.animation_player.play("swipe")
	else:
		hand.animation_player.play("tap")
	
	hand.animation_player.advance(0.0)

func start_tutorial() -> void:
	enabled = true
	
	show()
	ui.hide()
	
	# Add balls
	var ball_positions := [
		Vector2i(2, 3),
		Vector2i(3, 2),
		Vector2i(3, 1),
		Vector2i(2, 1),
		Vector2i(1, 1),
		Vector2i(0, 0)
	]
	
	var ball_levels := [
		0,
		0,
		1,
		2,
		2,
		2,
		2
	]
	
	for i in range(ball_positions.size()):
		await game.add_ball(ball_positions[i], ball_levels[i])
	
	# Queue movement
	position_queue = [
		Vector2i(2, 3),
		Vector2i(3, 3),
		Vector2i(3, 2),
		Vector2i(0, 0),
	]
	
	direction_queue = [
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.UP,
		Vector2i.DOWN
	]
	
	move_hand()

func end_tutorial():
	enabled = false
	
	ui.show()
	ui_player.play("fade_in")
	ui_player.advance(0.0)
	
	game.start_game()
	game.save_save_data()

func _ready() -> void:
	hide()

func _on_game_ball_selected() -> void:
	if not enabled:
		return
	
	if position_queue.is_empty():
		return
	
	move_hand()

func _on_game_player_move_started() -> void:
	if not enabled:
		return
	
	position_queue.pop_front()
	direction_queue.pop_front()
	
	hand.hide()

func _on_game_player_move_ended() -> void:
	if not enabled:
		return
	
	await game.check_lines()
	
	if position_queue.is_empty():
		end_tutorial()
		return
	
	move_hand()
	hand.show()
