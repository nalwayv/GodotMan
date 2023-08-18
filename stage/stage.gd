extends Node

enum ActiveState {CHASE, SCATTER}

const MAX_PELLETS = 240
const MAX_PILLS = 4
const PELLET_VALUE = 10
const PILL_VALUE = 20
const GHOST_VALUE = 50
const SPECIAL_VALUE = 100
const HIT_STOP_VALUE = 0.5
const ONE_UP = 2500
const PillScene = preload("res://items/pill.tscn")
const PelletScene = preload("res://items/pellet.tscn")
const SpecialScene = preload("res://items/special.tscn")

@export var TileSize: float = 0.0

var tile_offset := Vector2i(10, 10)
var active_state := ActiveState.CHASE
var pellets_eaten: int = 0
var pills_eaten: int = 0
var score: int = 0
var has_special: bool = false
var is_active: bool = false

@onready var map := $Map as Map
@onready var player := $Player as Player
@onready var red := $Red as Ghost
@onready var pink := $Pink as Ghost
@onready var blue := $Blue as Ghost
@onready var orange := $Orange as Ghost
@onready var ui := $Ui as Ui
@onready var pill_container := $Pills as Node
@onready var pellet_container := $Pellets as Node
@onready var chase_timer := $ChaseTimer as Timer
@onready var scatter_timer := $ScatterTimer as Timer
@onready var special_timer := $SpecialTimer as Timer
@onready var cell_target := $CellTarget as Marker2D
@onready var special_target := $SpecialTarget as Marker2D
@onready var player_start_target := $PlayerStartTarget as Marker2D
@onready var red_start_target := $RedStartTarget as Marker2D
@onready var red_scatter_target := $RedScatterTarget as Marker2D
@onready var pink_start_target := $PinkStartTarget as Marker2D
@onready var pink_scatter_target := $PinkScatterTarget as Marker2D
@onready var blue_start_target := $BlueStartTarget as Marker2D
@onready var blue_scatter_target := $BlueScatterTarget as Marker2D
@onready var orange_start_target := $OrangeStartTarget as Marker2D
@onready var orange_scatter_target := $OrangeScatterTarget as Marker2D
@onready var right_target := $RightTriggerTarget as Marker2D
@onready var left_target := $LeftTriggerTarget as Marker2D

func _update_red_target() -> void:
	if red.is_active():
		if active_state == ActiveState.CHASE:
			red.set_target(player.position)
		else:
			red.set_target(red_scatter_target.position)
	elif red.is_eaten():
		red.set_target(cell_target.position)

func _update_pink_target() -> void:
	if pink.is_active():
		if active_state == ActiveState.CHASE:
			var distance: float = TileSize * 4.0
			var player_direction: Vector2 = player.get_current_direction()
			var target := Vector2.ZERO
			
			if player_direction == Vector2.UP or player_direction == Vector2.ZERO:
				target = (Vector2.ONE * -1.0) * distance
			else:
				target = player_direction * distance
			
			pink.set_target(player.position + target)
		else:
			pink.set_target(pink_scatter_target.position)
	elif pink.is_eaten():
		pink.set_target(cell_target.position)

func _update_blue_target() -> void:
	if blue.is_active() and red.is_active():
		if active_state == ActiveState.CHASE:
			var distance: float = TileSize * 2.0
			var player_direction: Vector2 = player.get_current_direction()
			var target := Vector2.ZERO
			
			if player_direction == Vector2.UP or player_direction == Vector2.ZERO:
				target = (Vector2.ONE * -1.0) * distance
			else:
				target = player_direction * distance
			
			blue.set_target(red.position + ((player.position + target) - red.position)  * 2.0)
		else:
			blue.set_target(blue_scatter_target.position)
	elif blue.is_eaten():
		blue.set_target(cell_target.position)

func _update_orange_target() -> void:
	if orange.is_active():
		if active_state == ActiveState.CHASE:
			var distance: float = TileSize * 8.0
			if orange.position.distance_squared_to(player.position) < distance * distance:
				orange.set_target(orange_scatter_target.position)
			else:
				orange.set_target(player.position)
		else:
			orange.set_target(orange_scatter_target.position)
	elif orange.is_eaten():
		orange.set_target(cell_target.position)

func _reset_stage() -> void:
	chase_timer.stop()
	scatter_timer.stop()
	special_timer.stop()
	
	player.stop()
	red.stop()
	pink.stop()
	blue.stop()
	orange.stop()
	
	for i in pill_container.get_child_count():
		var p := pill_container.get_child(i) as Pill
		p.stop_animation()
	
	var special = get_node_or_null("special")
	if special != null:
		has_special = false
		special.queue_free()
	
	await get_tree().create_timer(1.5).timeout
	
	player.set_up(player_start_target.position)
	red.set_up(red_start_target.position)
	pink.set_up(pink_start_target.position)
	blue.set_up(blue_start_target.position)
	orange.set_up(orange_start_target.position)
	
	active_state = ActiveState.CHASE
	
	await get_tree().create_timer(1.5).timeout

	ui.start_timer()
	
func _reset_game() -> void:
	chase_timer.stop()
	scatter_timer.stop()
	special_timer.stop()

	player.stop()
	red.stop()
	pink.stop()
	blue.stop()
	orange.stop()
	
	for i in pill_container.get_child_count():
		var p := pill_container.get_child(i) as Pill
		p.stop_animation()
		
	var special = get_node_or_null("special")
	if special != null:
		has_special = false
		special.queue_free()

	await get_tree().create_timer(1.5).timeout

	player.set_up(player_start_target.position)
	red.set_up(red_start_target.position)
	pink.set_up(pink_start_target.position)
	blue.set_up(blue_start_target.position)
	orange.set_up(orange_start_target.position)
	
	ui.reset()
	
	for i in pellet_container.get_child_count():
		var p := pellet_container.get_child(i) as Pellet
		p.enable()

	for i in pill_container.get_child_count():
		var p := pill_container.get_child(i) as Pill
		p.enable()
	
	pellets_eaten = 0
	score = 0
	active_state = ActiveState.CHASE

	await get_tree().create_timer(2.5).timeout

	ui.start_timer()

func _update_score_value(value: int) -> void:
	score += value
	ui.update_score(score)
	if (score % ONE_UP) == 0:
		ui.add_health_token()

func hit_stop_eat_ghost() -> void:
	if player.is_active():
		player.hit_stop(HIT_STOP_VALUE)

	if red.is_frightened():
		red.hit_stop(HIT_STOP_VALUE)
		
	if pink.is_frightened():
		pink.hit_stop(HIT_STOP_VALUE)
		
	if blue.is_frightened():
		blue.hit_stop(HIT_STOP_VALUE)
		
	if orange.is_frightened():
		orange.hit_stop(HIT_STOP_VALUE)

# -- Signals

func _on_pill_eaten() -> void:
	red.set_to_frightened_state()
	pink.set_to_frightened_state()
	blue.set_to_frightened_state()
	orange.set_to_frightened_state()
	
	pills_eaten += 1
	_update_score_value(PILL_VALUE)
	
	if pellets_eaten == MAX_PELLETS and pills_eaten == MAX_PILLS:
		ui.set_message("Winner")
		_reset_game()

func _on_pellet_eaten() -> void:
	pellets_eaten += 1
	_update_score_value(PELLET_VALUE)
	
	if pellets_eaten == MAX_PELLETS and pills_eaten == MAX_PILLS:
		ui.set_message("Winner")
		_reset_game()

func _on_special_eaten() -> void:
	has_special = false
	_update_score_value(SPECIAL_VALUE)
	special_timer.start()

func _on_scatter_timer_timeout() -> void:
	chase_timer.start()
	active_state = ActiveState.CHASE

func _on_chase_timer_timeout() -> void:
	scatter_timer.start()
	active_state = ActiveState.SCATTER

func _on_right_trigger_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		player.snap_to_target(left_target.position)
		return

	if area.name == "Red":
		red.snap_to_target(left_target.position)
		return

	if area.name == "Pink":
		pink.snap_to_target(left_target.position)
		return
		
	if area.name == "Blue":
		blue.snap_to_target(left_target.position)
		return
		
	if area.name == "Orange":
		orange.snap_to_target(left_target.position)
		return

func _on_left_trigger_area_entered(area: Area2D) -> void:
	if area.name == "Player":
		player.snap_to_target(right_target.position)
		return
		
	if area.name == "Red":
		red.snap_to_target(right_target.position)
		return
	
	if area.name == "Pink":
		pink.snap_to_target(right_target.position)
		return
		
	if area.name == "Blue":
		blue.snap_to_target(right_target.position)
		return
	
	if area.name == "Orange":
		orange.snap_to_target(right_target.position)
		return

func _on_ghost_hit_player(ghost_name: StringName) -> void:
	if ghost_name == "Red":
		if red.is_active():
			ui.remove_health_token()
			_reset_stage()
		elif red.is_frightened():
			hit_stop_eat_ghost()
			red.set_to_eaten_state()
			_update_score_value(GHOST_VALUE)
		return
			
	if ghost_name == "Pink":
		if pink.is_active():
			ui.remove_health_token()
			_reset_stage()			
		elif pink.is_frightened():
			hit_stop_eat_ghost()
			pink.set_to_eaten_state()
			_update_score_value(GHOST_VALUE)
		return
		
	if ghost_name == "Blue":
		if blue.is_active():
			ui.remove_health_token()
			_reset_stage()			
		elif blue.is_frightened():
			hit_stop_eat_ghost()
			blue.set_to_eaten_state()
			_update_score_value(GHOST_VALUE)
		return
			
	if ghost_name == "Orange":
		if orange.is_active():
			ui.remove_health_token()
			_reset_stage()
		elif orange.is_frightened():
			hit_stop_eat_ghost()
			orange.set_to_eaten_state()
			_update_score_value(GHOST_VALUE)
		return

func _on_cell_trigger_area_entered(area: Area2D) -> void:
	if area.name == "Red":
		if red.is_eaten():
			red.set_to_active_state()
		return
		
	if area.name == "Pink":
		if pink.is_eaten():
			pink.set_to_active_state()
		return
		
	if area.name == "Blue":
		if blue.is_eaten():
			blue.set_to_active_state()
		return
		
	if area.name == "Orange":
		if orange.is_eaten():
			orange.set_to_active_state()
		return

func _on_special_timer_timeout() -> void:
	if has_special:
		# restart timer
		special_timer.start()
	else:
		has_special = true
		
		var new_special = SpecialScene.instantiate() as Special
		new_special.set_up(special_target.position)
		new_special.eaten.connect(_on_special_eaten)
		add_child(new_special)

		special_timer.start()

func _on_ui_game_over() -> void:
	ui.set_message("GameOver")
	_reset_game()

func _on_ui_start_game() -> void:
	player.set_to_active_state()
	red.run_start_timer()
	pink.run_start_timer()
	blue.run_start_timer()
	orange.run_start_timer()
	
	is_active = true
	
	chase_timer.start()
	special_timer.start()
	
	for i in pill_container.get_child_count():
		var p := pill_container.get_child(i) as Pill
		p.start_animation()

# -- Override

func _ready() -> void:
	for coord in map.get_pill_cells():
		var new_pill = PillScene.instantiate() as Pill
		new_pill.set_up(map.coords_to_world(coord, tile_offset))
		new_pill.eaten.connect(_on_pill_eaten)
		pill_container.add_child(new_pill)
	
	for coord in map.get_pellet_cells():
		var new_pellet = PelletScene.instantiate() as Pellet
		new_pellet.set_up(map.coords_to_world(coord, tile_offset))
		new_pellet.eaten.connect(_on_pellet_eaten)
		pellet_container.add_child(new_pellet)

	player.set_up(player_start_target.position)
	red.set_up(red_start_target.position)
	pink.set_up(pink_start_target.position)
	blue.set_up(blue_start_target.position)
	orange.set_up(orange_start_target.position)
	
	ui.set_up()
	ui.start_timer()

func _process(_delta: float) -> void:
	if not is_active:
		return
		
	_update_red_target()
	_update_pink_target()
	_update_blue_target()
	_update_orange_target()
