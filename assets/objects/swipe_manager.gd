extends Node
class_name SwipeManager

@export var min_swipe_length: float

var tap_position: Vector2

signal swiped(direction: Vector2)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			tap_position = event.position
		else:
			var difference: Vector2 = event.position - tap_position
			
			if difference.length() <= min_swipe_length:
				return
			
			var direction: Vector2
			
			if abs(difference.x) < abs(difference.y):
				direction = Vector2(0, sign(difference.y))
			else:
				direction = Vector2(sign(difference.x), 0)
			
			swiped.emit(direction)
