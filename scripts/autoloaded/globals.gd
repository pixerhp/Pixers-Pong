extends Node

var GAME_SIZE: Vector2 = Vector2( # Minimum 300x200?
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"),)

enum AI_MODES {
	NO_AI,
	COPYCAT, # Copies the other player's inputs.
	RANDOM_MASH, # Mashes random movement inputs every frame. (It's not very effective.)
	ZIGZAGGER_SLOW,
	ZIGZAGGER, # Alternately moves between the top-most and bottom-most paddle positions. 
	
	CHASER_SLOW, 
	CHASER, # Simply "chases" the ball's current y-position.
	CONVERGER_SLOW,
	CONVERGER, # !!! Tries to move to where the ball will be if it reaches the paddle x on it's current trajectory.
	PATIENT_CONVERGER_SLOW,
	PATIENT_CONVERGER, # !!! like previous but waits in the center if the ball's current trajectory goes beyond the floor/ceiling
	PREDICTOR_SLOW,
	PREDICTOR, # !!! Accounts for up to one bounce, waits in the center if there will be multiple.
	DEEP_PREDICTOR_SLOW,
	DEEP_PREDICTOR, # !!! like previous, but accounts for arbirarily many bounces, so no waiting in center.
	MASTER_SLOW,
	MASTER, # Good luck. # !!! like previous, but aggressively tries to aim the ball to where the other player isn't with its paddle hits.
}

var plr1_ai_mode: int = AI_MODES.NO_AI
var plr2_ai_mode: int = AI_MODES.COPYCAT

func _process(_delta):
	if Input.is_action_pressed("pause_escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
