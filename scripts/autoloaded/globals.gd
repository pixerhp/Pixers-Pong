extends Node

var GAME_SIZE: Vector2 = Vector2( # Minimum 300x200?
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"),)

enum AI_MODES {
	NO_AI, 
	COPYCAT,
	RANDOM_INPUTS,
	ZIGZAGGER_SLOW,
	ZIGZAGGER,
	CHASER_SLOW, 
	CHASER, # Simply chases the ball's position, ignoring its velocity or anything to do with bounces.
	CONVERGER_SLOW,
	CONVERGER, # Tries to move to where the ball will be if it reaches the paddle x on it's current trajectory.
	PATIENT_CONVERGER_SLOW,
	PATIENT_CONVERGER, # like previous but waits in the center if the ball's current trajectory goes beyond the floor/ceiling
	PREDICTOR_SLOW,
	PREDICTOR, # Accounts for up to one bounce, waits in the center if there will be multiple.
	DEEP_PREDICTOR_SLOW,
	DEEP_PREDICTOR, # like previous, but accounts for arbirarily many bounces, so no waiting in center.
	MASTER_SLOW,
	MASTER, # like previous, but aggressively tries to aim the ball to where the other player isn't with its paddle hits.
}

var plr1_ai_mode: int = AI_MODES.NO_AI
var plr2_ai_mode: int = AI_MODES.ZIGZAGGER_SLOW

func _process(_delta):
	if Input.is_action_pressed("pause_escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
