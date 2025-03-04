@tool
extends Node2D
class_name Circle

@export var radius: float :
	set(value):
		radius = value
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color.WHITE, true, -1.0, true)
