extends Node2D
class_name TutorialHand

@export var sprite: Sprite2D
@export var animation_player: AnimationPlayer
@export var direction: Vector2
@export var swipe_scale: Vector2
@export var swipe_time: float

var swipe_tween: Tween

func tween_swipe() -> void:
	if swipe_tween:
		swipe_tween.kill()
	
	swipe_tween = create_tween()\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	
	swipe_tween.tween_property(
		sprite, "position", direction * swipe_scale, swipe_time)

func _on_animation_player_animation_started(_anim_name: StringName) -> void:
	if swipe_tween:
		swipe_tween.kill()
		swipe_tween = null
