class_name Ghost extends Area2D

signal hit_player(ghost_name: StringName)

enum Type {RED, PINK, BLUE, ORANGE}
enum State {ACTIVE, INACTIVE, EATEN, FRIGHTENED}

const MAX_SPEED = 130.0
const SLOW_EFFECT = 0.01

@export var GhostType: Type
@export var TileSize: float = 0.0
@export var StartTime: float = 0.0

var target_position := Vector2.ZERO
var target_direction := Vector2.ZERO
var target_movetowards := Vector2.ZERO
var direction := Vector2.ZERO
var color: Color = Color.WHITE
var speed: float = 0.0
var current_state: State = State.INACTIVE
var is_moveing: bool = false
var is_hitstop: bool = false
var is_debug: bool = false
var tween: Tween = null

@onready var body_maker := $BodyTarget as Marker2D
@onready var collision := $CollisionShape as CollisionShape2D
@onready var polygon := $BodyTarget/Polygon as Polygon2D
@onready var fright_timer := $FrightTimer as Timer
@onready var start_timer := $StartTimer as Timer
@onready var line_to_target := $LineToTarget as Line2D
@onready var raycast_direction := $RayCastDirection as RayCast2D

func _set_to_default_settings() -> void:
	current_state = State.INACTIVE
	is_moveing = false
	body_maker.position = Vector2.ZERO
	target_position = Vector2.ZERO
	target_direction = Vector2.ZERO
	target_movetowards = Vector2.ZERO
	direction = Vector2.ZERO
	speed = 0.0

func is_active() -> bool:
	return current_state == State.ACTIVE

func is_inactive() -> bool:
	return current_state == State.INACTIVE

func is_frightened() -> bool:
	return current_state == State.FRIGHTENED

func is_eaten() -> bool:
	return current_state == State.EATEN

func set_up(start_position: Vector2) -> void:
	if GhostType == Type.RED:
		color = Color(0.93, 0.43, 0.52)
		polygon.color = color
	elif GhostType == Type.PINK:
		color = Color(0.96, 0.54, 0.51)
		polygon.color = color
	elif GhostType == Type.BLUE:
		color = Color(0.45, 0.87, 0.93)
		polygon.color = color
	elif GhostType == Type.ORANGE:
		color = Color(0.93, 0.65, 0.45)
		polygon.color = color
	else:
		color = Color.WHITE
		polygon.color = color
	
	if not is_inactive():
		current_state = State.INACTIVE

	position = start_position
	collision.set_deferred("disabled", false)

func stop() -> void:
	fright_timer.stop()
	start_timer.stop()
	
	collision.set_deferred("disabled", true)

	$AnimationPlayer.stop()

	if tween != null:
		tween.kill()

	if is_frightened():
		fright_timer.stop()
		polygon.color = color
		
	elif is_eaten():
		polygon.color = color

	_set_to_default_settings()

func run_start_timer() -> void:
	start_timer.start(StartTime)

func snap_to_target(target: Vector2) -> void:
	if is_moveing:
		position = target_position
		is_moveing = false

	position = target

func set_target(target: Vector2) -> void:
	target_movetowards = target

func set_to_frightened_state() -> void:
	if is_eaten():
		return

	if is_moveing:
		position = target_position
		is_moveing = false

	current_state = State.FRIGHTENED
	fright_timer.start()
	direction *= -1.0
	$AnimationPlayer.play("Fright")

func set_to_active_state() -> void:
	if is_frightened():
		fright_timer.stop()
		$AnimationPlayer.stop()
		polygon.color = color
	elif is_eaten():
		$AnimationPlayer.stop()
		polygon.color = color

	current_state = State.ACTIVE

func set_to_inactive_state() -> void:
	current_state = State.INACTIVE

func set_to_eaten_state() -> void:
	current_state = State.EATEN

	if is_moveing:
		position = target_position
		is_moveing = false

	$AnimationPlayer.play("Eaten")

func hit_stop(duration: float) -> void:
	is_hitstop = true
	polygon.hide()
	
	# create small timer for pause effect
	await get_tree().create_timer(duration).timeout
	
	is_hitstop = false
	polygon.show()
	
func _get_random_direction() -> Vector2:
	var movable_directions := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	
	if direction == Vector2.UP:
		movable_directions[0] = Vector2.UP
		movable_directions[1] = Vector2.LEFT
		movable_directions[2] = Vector2.RIGHT
	elif direction == Vector2.DOWN:
		movable_directions[0] = Vector2.DOWN
		movable_directions[1] = Vector2.LEFT
		movable_directions[2] = Vector2.RIGHT
	elif direction == Vector2.LEFT:
		movable_directions[0] = Vector2.LEFT
		movable_directions[1] = Vector2.UP
		movable_directions[2] = Vector2.DOWN
	elif direction == Vector2.RIGHT:
		movable_directions[0] = Vector2.RIGHT
		movable_directions[1] = Vector2.UP
		movable_directions[2] = Vector2.DOWN

	var result := Vector2.ZERO
	
	while movable_directions.size() > 0:
		var rng_idx: int = randi_range(0, movable_directions.size() - 1)
		var dir: Vector2 = movable_directions[rng_idx]
		
		raycast_direction.target_position = dir * TileSize
		raycast_direction.force_raycast_update()
		
		if raycast_direction.is_colliding():
			movable_directions.remove_at(rng_idx)
		else:
			result = dir
			break

	return result

func _get_target_direction() -> Vector2:
	var movable_directions := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
	
	if direction == Vector2.UP:
		movable_directions[0] = Vector2.UP
		movable_directions[1] = Vector2.LEFT
		movable_directions[2] = Vector2.RIGHT
	elif direction == Vector2.DOWN:
		movable_directions[0] = Vector2.DOWN
		movable_directions[1] = Vector2.LEFT
		movable_directions[2] = Vector2.RIGHT
	elif direction == Vector2.LEFT:
		movable_directions[0] = Vector2.LEFT
		movable_directions[1] = Vector2.UP
		movable_directions[2] = Vector2.DOWN
	elif direction == Vector2.RIGHT:
		movable_directions[0] = Vector2.RIGHT
		movable_directions[1] = Vector2.UP
		movable_directions[2] = Vector2.DOWN

	var result := Vector2.ZERO
	var smallest: float = 1.79769e308
	
	for dir in movable_directions:
		var distance: Vector2 = dir * TileSize
		
		raycast_direction.target_position = distance
		raycast_direction.force_raycast_update()
		
		if not raycast_direction.is_colliding():
			var distance_to = (position + distance).distance_squared_to(target_movetowards)
			if distance_to < smallest:
				smallest = distance_to
				result = dir
				
	return result

func _activate() -> void:
	if is_inactive():
		current_state = State.ACTIVE
	
	if GhostType == Type.RED:
		direction = Vector2.RIGHT
	elif GhostType == Type.PINK:
		direction = Vector2.LEFT
	elif GhostType == Type.BLUE:
		direction = Vector2.LEFT
	elif GhostType == Type.ORANGE:
		direction = Vector2.RIGHT
	
	raycast_direction.target_position = direction * TileSize
	raycast_direction.set_deferred("enabled", true)

# -- Signals

func _on_start_timer_timeout() -> void:
	if GhostType == Type.RED:
		current_state = State.ACTIVE
		direction = Vector2.RIGHT
		return
	
	if GhostType == Type.PINK:
		tween = create_tween()
		tween.tween_property(self, "position", Vector2.RIGHT * 1.5 * TileSize, 0.3).as_relative();
		tween.tween_property(self, "position", Vector2.UP * 3.0 * TileSize, 0.5).as_relative();
		tween.finished.connect(_activate)
		return

	if GhostType == Type.BLUE:
		tween = create_tween()
		tween.tween_property(self, "position", Vector2.UP * 3.0 * TileSize, 0.5).as_relative();
		tween.tween_property(self, "position", Vector2.LEFT * 0.5 * TileSize, 0.1).as_relative();
		tween.finished.connect(_activate)
		return
	
	if GhostType == Type.ORANGE:
		tween = create_tween()
		tween.tween_property(self, "position", Vector2.LEFT * 1.5 * TileSize, 0.3).as_relative();
		tween.tween_property(self, "position", Vector2.UP * 3.0 * TileSize, 0.5).as_relative();
		tween.finished.connect(_activate)
		return

func _on_fright_timer_timeout() -> void:
	if not is_eaten():
		set_to_active_state()
		
func _on_area_entered(_area: Area2D) -> void:
	hit_player.emit(name)

# -- Override

func _process(delta: float) -> void:
	if is_inactive():
		return
	
	if is_debug and is_active():
		line_to_target.set_point_position(1, to_local(target_movetowards))
	else:
		line_to_target.set_point_position(1, Vector2.ZERO)
		
	if not is_moveing:
		var dir := Vector2.ZERO
		if current_state == State.FRIGHTENED:
			dir = _get_random_direction()
		else:
			dir = _get_target_direction()
		
		target_direction = dir
		direction = dir
		target_position = position + (target_direction * TileSize)
		is_moveing = true
		
	elif is_moveing:
		if target_direction.length_squared() > 0:
			speed = MAX_SPEED
			var velocity: Vector2 = target_direction * speed * delta
			
			if is_hitstop:
				velocity *= SLOW_EFFECT
				$AnimationPlayer.speed_scale = SLOW_EFFECT
			else:
				$AnimationPlayer.speed_scale = 1.0
				
			if position.distance_squared_to(target_position) < velocity.length_squared():
				velocity = target_direction * position.distance_to(target_position)
				is_moveing = false

			position += velocity
			
			# move body slightly
			body_maker.position = target_direction * -4
		else:
			is_moveing = false
