extends Button
class_name GridButton

var grid_position: Vector2i
var ball: Ball

func get_ball_position() -> Vector2:
	return global_position + size * 0.5
