extends Node

const PLAY_AREA_DIMENSIONS: Vector2 = Vector2(1260, 648)

enum AI_MODES {OFF = 0, LVL1 = 1, LVL2 = 2, LVL3 = 3}
var plr1_ai_mode: int = AI_MODES.OFF
var plr2_ai_mode: int = AI_MODES.OFF

func _process(_delta):
	if Input.is_action_pressed("pause_escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
