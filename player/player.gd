class_name Player extends Area2D
 
enum State {ACTIVE, INACTIVE, DEAD}

const MAX_SPEED = 170.0
const SLOW_EFFECT = 0.01

@export var TileSize: float = 0.0

var current_direction := Vector2.ZERO
var input_direction := Vector2.ZERO
var target_position := Vector2.ZERO
var target_direction := Vector2.ZERO
var current_state: State = State.INACTIVE
var speed: float = 0.0
var is_slow: bool = false
var is_hitstop: bool = false
var is_moveing: bool = false

@onready var polygon := $Polygon as Polygon2D
@onready var collision := $CollisionShape as CollisionShape2D
@onready var raycast_input := $RayCastInput as RayCast2D
@onready var raycast_direction := $RayCastDirection as RayCast2D

func _set_to_default_settings() -> void:
	is_moveing = false
	current_direction = Vector2.ZERO
	input_direction = Vector2.ZERO
	target_position = Vector2.ZERO
	target_direction = Vector2.ZERO
	speed = 0.0

func is_inactive() -> bool:
	return current_state == State.INACTIVE
	
func is_dead() -> bool:
	return current_state == State.DEAD
	
func is_active() -> bool:
	return current_state == State.ACTIVE

func set_up(start_position: Vector2) -> void:
	position = start_position
	
	if not is_inactive():
		current_state = State.INACTIVE
		
	polygon.look_at(position + Vector2.RIGHT)
	collision.set_deferred("disabled", false)

func stop() -> void:
	current_state = State.INACTIVE
	
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
		
	_set_to_default_settings()
	
	collision.set_deferred("disabled", true)
	
func set_to_active_state() -> void:
	current_state = State.ACTIVE

func set_to_inactive_state() -> void:
	current_state = State.INACTIVE
	
func set_to_dead_state() -> void:
	current_state = State.DEAD

func snap_to_target(target:Vector2) -> void:
	if is_moveing:
		position = target_position
		is_moveing = false

	position = target

func get_current_direction() -> Vector2:
	return current_direction

func hit_stop(duration: float) -> void:
	is_hitstop = true
	polygon.hide()
	
	# create small timer for pause effect
	await get_tree().create_timer(duration).timeout
	
	is_hitstop = false
	polygon.show()

# -- Override

func _process(delta: float) -> void:
	if is_inactive() or is_dead():
		return
		
	if not is_moveing:
		# can only move in one of four directions
		if input_direction.y == 0:
			input_direction.x = Input.get_axis("Left", "Right")
		if input_direction.x == 0:
			input_direction.y = Input.get_axis("Up", "Down")

		# move to new direction if allowed
		raycast_input.target_position = input_direction * TileSize
		raycast_input.force_raycast_update()
		if input_direction.length_squared() > 0.0:
			if not raycast_input.is_colliding():
				target_direction = input_direction
				current_direction = input_direction
				target_position = position + (target_direction * TileSize)
				is_moveing = true

		# keep moveing in same direction while not being blocked
		raycast_direction.target_position = current_direction * TileSize
		raycast_direction.force_raycast_update()
		if not raycast_direction.is_colliding():
			target_direction = current_direction
			target_position = position + (target_direction * TileSize)
			is_moveing = true
			
		if not is_moveing:
			$AnimationPlayer.stop()

	elif is_moveing:
		if input_direction.length_squared() > 0.0:
			if not $AnimationPlayer.is_playing():
				$AnimationPlayer.play("Chomp")
		
		polygon.look_at(position + target_direction)
		
		if target_direction.length_squared() > 0.0:
			speed = MAX_SPEED
			var velocity: Vector2 = speed * target_direction * delta
			
			if is_hitstop:
				velocity *= SLOW_EFFECT
				$AnimationPlayer.speed_scale = SLOW_EFFECT
			else:
				$AnimationPlayer.speed_scale = 1.0
				
			if position.distance_squared_to(target_position) < velocity.length_squared():
				velocity = target_direction * position.distance_to(target_position)
				is_moveing = false

			position += velocity
		else:
			is_moveing = false
