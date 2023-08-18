class_name Pill extends Area2D

signal eaten

var is_active: bool = true

@onready var collision_shape := $CollisionShape as CollisionShape2D

func set_up(start_position: Vector2) -> void:
	position = start_position
#	$AnimationPlayer.play("Blink")

func start_animation() -> void:
	$AnimationPlayer.play("Blink")
	
func stop_animation() -> void:
	$AnimationPlayer.stop()
	
func enable() -> void:
	is_active = true
	collision_shape.set_deferred("disabled", false)
	show()

func _disable() -> void:
	is_active = false
	collision_shape.set_deferred("disabled", true)
	$AnimationPlayer.stop()
	eaten.emit()
	hide()
	
# -- Signals

func _on_area_entered(_area: Area2D) -> void:
	_disable()
