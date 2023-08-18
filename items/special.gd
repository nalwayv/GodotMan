class_name Special extends Area2D

signal eaten

func set_up(start_position: Vector2) -> void:
	position = start_position
	$AnimationPlayer.play("Shine")

#func stop_animation() -> void:
#	$AnimationPlayer.stop()

# -- Signals

func _on_area_entered(_area: Area2D) -> void:
	eaten.emit()
	$AnimationPlayer.stop()
	hide()
	queue_free()
