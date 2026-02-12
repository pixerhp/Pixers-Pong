extends Node

var GAME_SIZE: Vector2 = Vector2( # Minimum 300x200?
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"),)

enum AI_MODES {
	NO_AI, 
	RANDOM,
	COPYCAT,
	ZIGZAG,
	SLOW_CHASE, 
	CHASE,
	SLOW_PREDICTOR,
	PREDICTOR,
	MASTER,
}

var plr1_ai_mode: int = AI_MODES.NO_AI
var plr2_ai_mode: int = AI_MODES.NO_AI

func _process(_delta):
	if Input.is_action_pressed("pause_escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
