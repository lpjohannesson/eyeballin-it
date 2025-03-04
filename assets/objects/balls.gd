extends Node2D
class_name Balls

@export var colors: PackedColorArray
@export var size_min: float
@export var size_max: float
@export var tween_duration: float

@onready var level_max := float(colors.size() - 1)

func get_ball_size(ball_level: int) -> float:
	return lerp(size_min, size_max, ball_level / level_max)

func get_player_size(ball_level: int) -> Vector2:
	return Vector2.ONE * \
		lerp(size_min / size_max, 1.0, ball_level / level_max)

func can_balls_combine(ball1: Ball, ball2: Ball) -> bool:
	# Check max size
	if ball1.ball_level >= colors.size() - 1:
		return false
	
	return ball1.ball_level == ball2.ball_level

func start_ball(ball: Ball) -> void:
	ball.circle.modulate = colors[ball.ball_level]
	ball.circle.radius = 0.0
	
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(
		ball.circle, "radius",
		get_ball_size(ball.ball_level), tween_duration)
	
	await tween.finished

func end_ball(ball: Ball, show_stars: bool) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(
		ball.circle, "radius",
		0.0, tween_duration)
	
	# Delete ball on stars finished
	if show_stars:
		ball.stars.modulate = ball.circle.modulate
		ball.stars.emitting = true
		ball.stars.finished.connect(func():
			ball.queue_free())
		
		await tween.finished
	else:
		await tween.finished
		ball.queue_free()

func combine_balls(ball1: Ball, ball2: Ball, player: Player):
	ball1.ball_level += 1
	ball2.queue_free()
	
	# Start tween
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(
		ball1.circle, "radius",
		get_ball_size(ball1.ball_level), tween_duration)
	
	tween.parallel().tween_property(
		ball1.circle, "modulate",
		colors[ball1.ball_level], tween_duration)
	
	tween.parallel().tween_property(
		player, "scale",
		get_player_size(ball1.ball_level), tween_duration)
	
	await tween.finished
