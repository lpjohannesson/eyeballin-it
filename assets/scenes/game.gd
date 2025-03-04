extends Node2D
class_name Game

@export var grid_size: Vector2i
@export var move_duration: float

@export var sounds: Sounds
@export var ad_manager: AdManager
@export var grid: GridContainer
@export var balls: Balls
@export var players: Node2D
@export var score: ScoreManager
@export var game_over_display: GameOverDisplay
@export var tutorial: TutorialManager

@export var grid_button_scene: PackedScene
@export var ball_scene: PackedScene
@export var player_scene: PackedScene

const move_offsets := [
	Vector2i.LEFT,
	Vector2i.RIGHT,
	Vector2i.UP,
	Vector2i.DOWN]

const save_path := "user://save.json"

var player: Player
var selected_position := Vector2i(-1, -1)

var moving_paused := false
var is_game_over := false
var has_continued := false

signal ball_selected
signal player_move_started
signal player_move_ended

func add_score(points: int) -> void:
	if tutorial.enabled:
		return
	
	score.score += points
	score.update_score()
	
	if score.new_high_score:
		save_save_data()

func is_tile_position(tile_position: Vector2i) -> bool:
	return \
		tile_position.x >= 0 and tile_position.x < grid_size.x and \
		tile_position.y >= 0 and tile_position.y < grid_size.y

func get_grid_button(tile_position: Vector2i) -> GridButton:
	var index = tile_position.y * grid_size.x + tile_position.x
	return grid.get_child(index)

func add_ball(tile_position: Vector2i, ball_level: int) -> void:
	# Create ball
	var ball: Ball = ball_scene.instantiate()
	balls.add_child(ball)
	
	# Assign ball to button
	var button := get_grid_button(tile_position)
	button.ball = ball
	
	ball.global_position = button.get_ball_position()
	ball.ball_level = ball_level
	
	sounds.play_sound("Pop")
	
	await balls.start_ball(ball)

func remove_ball(tile_position: Vector2i, adding_score: bool) -> void:
	var button := get_grid_button(tile_position)
	var ball := button.ball
	
	if ball == null:
		return
	
	# Update score
	if adding_score:
		add_score(10 * (ball.ball_level + 1))
		sounds.play_sound("Glimmer")
	
	# End player if on tile
	if player != null and selected_position == tile_position:
		player.end_player()
		player = null
	
	button.ball = null
	
	await balls.end_ball(ball, adding_score)

func add_random_ball() -> void:
	# Find vacant positions
	var tile_positions := []
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var tile_position = Vector2i(x, y)
			
			if get_grid_button(tile_position).ball != null:
				continue
			
			tile_positions.append(tile_position)
	
	if tile_positions.is_empty():
		return
	
	await add_ball(tile_positions.pick_random(), randi() % 2)

func check_line_ball(ball: Ball, line_level):
	# Stop on no ball
	if ball == null:
		return null
	
	# Check starting or matches line
	if line_level == null or ball.ball_level == line_level:
		return ball.ball_level
	
	return null

func check_lines() -> void:
	var removed_tiles := []
	var line_level = null
	
	# Check rows
	for y in range(grid_size.y):
		line_level = null
		
		for x in range(grid_size.x):
			var ball := get_grid_button(Vector2i(x, y)).ball
			line_level = check_line_ball(ball, line_level)
			
			if line_level == null:
				break
		
		if line_level == null:
			continue
		
		for x in range(grid_size.x):
			removed_tiles.append(Vector2i(x, y))
	
	# Check columns
	for x in range(grid_size.x):
		line_level = null
		
		for y in range(grid_size.y):
			var ball := get_grid_button(Vector2i(x, y)).ball
			line_level = check_line_ball(ball, line_level)
			
			if line_level == null:
				break
		
		if line_level == null:
			continue
		
		for y in range(grid_size.y):
			removed_tiles.append(Vector2i(x, y))
	
	# Check left diagonal
	line_level = null
	
	for x in range(grid_size.x):
		var ball := get_grid_button(Vector2i(x, x)).ball
		line_level = check_line_ball(ball, line_level)
		
		if line_level == null:
			break
	
	if line_level != null:
		for x in range(grid_size.x):
			removed_tiles.append(Vector2i(x, x))
	
	# Check right diagonal
	line_level = null
	
	for x in range(grid_size.x):
		var ball := get_grid_button(Vector2i(grid_size.x - 1 - x, x)).ball
		line_level = check_line_ball(ball, line_level)
		
		if line_level == null:
			break
	
	if line_level != null:
		for x in range(grid_size.x):
			removed_tiles.append(Vector2i(grid_size.x - 1 - x, x))
	
	# Remove balls
	removed_tiles.sort_custom(func(a: Vector2i, b: Vector2i):
		return a.y * grid_size.x + a.x < b.y * grid_size.x + b.x)
	
	for tile_position in removed_tiles:
		await remove_ball(tile_position, true)

func ball_exists() -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var ball := get_grid_button(Vector2i(x, y)).ball
			
			if ball != null:
				return true
	
	return false

func advance_board() -> void:
	# Loop until a ball is on board
	while true:
		await add_random_ball()
		await check_lines()
		
		if ball_exists():
			return

func move_exists() -> bool:
	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var tile_position := Vector2i(x, y)
			var ball := get_grid_button(tile_position).ball
			
			if ball == null:
				continue
			
			for offset in move_offsets:
				var next_tile_position: Vector2i = tile_position + offset
				
				if not is_tile_position(next_tile_position):
					continue
				
				var next_ball := get_grid_button(next_tile_position).ball
				
				if next_ball == null:
					return true
				
				if balls.can_balls_combine(ball, next_ball):
					return true
	
	return false

func move_player(direction: Vector2i) -> void:
	if moving_paused:
		return
	
	if player == null:
		return
	
	player.move_pupils(direction)
	
	if tutorial.enabled:
		if tutorial.position_queue.is_empty():
			return
		
		if selected_position != tutorial.position_queue.front():
			return
		
		if direction != tutorial.direction_queue.front():
			return
	
	# Check next position exists
	var next_tile_position := selected_position + direction
	
	if not is_tile_position(next_tile_position):
		return
	
	# Check next cell is vacant or can combine
	var button := get_grid_button(selected_position)
	var next_button := get_grid_button(next_tile_position)
	
	var ball := button.ball
	var next_ball := next_button.ball
	
	var combining := false
	
	if next_ball != null:
		combining = balls.can_balls_combine(ball, next_ball)
		
		if not combining:
			return
	
	# Move ball between buttons
	button.ball = null
	next_button.ball = ball
	
	selected_position = next_tile_position
	add_score(5)
	
	player_move_started.emit()
	
	# Tween to next position
	var next_position := next_button.get_ball_position()
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(
		player, "global_position", next_position, move_duration)
	tween.parallel().tween_property(
		ball, "global_position", next_position, move_duration)
	
	sounds.play_sound("Whoosh")
	
	moving_paused = true
	await tween.finished
	
	# Combine balls
	if combining:
		add_score(5 * (ball.ball_level + 1))
		
		sounds.play_sound("Grow")
		
		await balls.combine_balls(ball, next_ball, player)
	
	player_move_ended.emit()
	
	# Skip board advance on tutorial
	if tutorial.enabled:
		moving_paused = false
		return
	
	await advance_board()
	
	if move_exists():
		moving_paused = false
	else:
		game_over()

func grid_button_clicked(button: GridButton) -> void:
	if moving_paused:
		return
	
	if button.ball == null:
		return
	
	if player != null:
		# Skip if already on position
		if selected_position == button.grid_position:
			return
		
		# End old player
		player.end_player()
	
	# Start new player
	player = player_scene.instantiate()
	players.add_child(player)
	
	selected_position = button.grid_position
	
	player.position = button.get_ball_position()
	player.scale = balls.get_player_size(button.ball.ball_level)
	
	player.start_player()
	
	sounds.play_sound("Blink")
	
	ball_selected.emit()

func reset_game() -> void:
	if is_game_over:
		is_game_over = false
		game_over_display.end_game_over()

func start_game() -> void:
	moving_paused = true
	has_continued = false
	
	ad_manager.show_banner()
	
	reset_game()
	score.reset_score()
	
	# Delete existing board
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			await remove_ball(Vector2i(x, y), false)
	
	# Start new board
	for _i in range(3):
		await advance_board()
	
	moving_paused = false

func continue_game():
	moving_paused = true
	has_continued = true
	
	reset_game()
	
	# Delete balls surrounding player
	for y in range(3):
		for x in range(3):
			var tile_position := selected_position + Vector2i(x - 1, y - 1)
			
			if not is_tile_position(tile_position):
				continue
			
			await remove_ball(tile_position, true)
	
	# Create random ball if none exist
	if not ball_exists():
		await add_random_ball()
	
	moving_paused = false

func game_over() -> void:
	is_game_over = true
	
	game_over_display.continue_button.visible = not has_continued
	game_over_display.game_over()
	
	sounds.play_sound("Lose")

func load_save_data():
	var save_file := FileAccess.open(save_path, FileAccess.READ)
	
	if not save_file:
		tutorial.call_deferred("start_tutorial")
		return
	
	var save_data: Dictionary = JSON.parse_string(save_file.get_as_text())
	
	score.high_score = save_data["high_score"]
	score.update_score()
	
	call_deferred("start_game")

func save_save_data():
	if tutorial.enabled:
		return
	
	var save_data := { "high_score": score.high_score }
	
	var save_file := FileAccess.open(save_path, FileAccess.WRITE)
	save_file.store_string(JSON.stringify(save_data))

func _ready() -> void:
	load_save_data()
	
	game_over_display.hide()
	
	# Create grid buttons
	grid.columns = grid_size.x
	
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var button: GridButton = grid_button_scene.instantiate()
			grid.add_child(button)
			
			button.grid_position = Vector2i(x, y)
			button.pressed.connect(func(): grid_button_clicked(button))

func _on_swipe_manager_swiped(direction: Vector2) -> void:
	move_player(direction)

func _on_game_over_display_continue_pressed() -> void:
	if has_continued:
		return
	
	await ad_manager.show_rewarded()
	
	# Restart game over screen on no reward
	if not ad_manager.reward_earned:
		game_over_display.enabled = true
		return
	
	continue_game()

func _on_restart_button_pressed() -> void:
	sounds.play_sound("Click")
	
	if is_game_over:
		# Pause game over if not already
		if not game_over_display.enabled:
			return
		
		game_over_display.enabled = false
	else:
		# Pause movement if not already
		if moving_paused:
			return
		
		moving_paused = true
	
	await ad_manager.show_interstitial()
	start_game()
