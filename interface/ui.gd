class_name Ui extends Control

signal game_over
signal start_game

const MAX_HEALTH_TOKENS = 5
const START_HEALTH_TOKENS = 3

var health_tokens: int = 0

@onready var score_label := $Header/HBox/Score/Center/Value as Label
@onready var tokens_container := $Footer/HBox/Tokens/HBox as HBoxContainer
@onready var message_label := $Main/Center/Message as Label

## create a simple color rect to represent a health token
func _new_health_token() -> ColorRect:
	var cc = ColorRect.new()
	
	# blue color
	cc.color = Color(0.235, 0.553, 0.78)
	cc.custom_minimum_size = Vector2(20, 20)
	
	return cc

func start_timer() -> void:
	$MessageTimer.start()
	
	message_label.text = "Ready!"
	message_label.show()
	
	await $MessageTimer.timeout
	
	start_game.emit()

func set_message(text: String) -> void:
	message_label.show()
	message_label.text = text

func set_up() -> void:
	score_label.text = "0"
	message_label.text = ""
	health_tokens = START_HEALTH_TOKENS

	for i in range(health_tokens):
		var token = _new_health_token()
		tokens_container.add_child(token)

func reset() -> void:
	score_label.text = "0"
	message_label.text = ""

	var l = tokens_container.get_child_count()
	if l > 0:
		for i in range(l):
			tokens_container.get_child(i).queue_free()
	
	health_tokens = START_HEALTH_TOKENS
	for i in range(health_tokens):
		var token = _new_health_token()
		tokens_container.add_child(token)

func update_score(value: int) -> void:
	score_label.text = "%d" % value

func add_health_token() -> void:
	if health_tokens < MAX_HEALTH_TOKENS:
		health_tokens += 1
		var new_token := _new_health_token()
		tokens_container.add_child(new_token)

func remove_health_token() -> void:
	health_tokens -= 1
	var count = tokens_container.get_child_count()
	
	if health_tokens == 0:
		tokens_container.get_child(count - 1).queue_free()
		game_over.emit()
		return 

	tokens_container.get_child(count - 1).queue_free()

# -- Signals

func _on_message_timer_timeout() -> void:
	message_label.hide()
