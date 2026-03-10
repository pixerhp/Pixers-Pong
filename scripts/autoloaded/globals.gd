extends Node

var GAME_SIZE: Vector2 = Vector2( # Minimum 300x200?
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"),)

enum CPU_MODES {
	OFF,
	OFF_BUT_YOURE_A_ROBOT,
	COPYCAT, # Copies the other player's inputs with a one-frame delay.
	RANDOM_MASH, # Mashes random movement inputs. (It's not very effective.)
	ZIGZAGGER, # Alternately moves between the top and bottom paddle positions. 
	CHASER, # Simply "chases" the ball's y-position.
	CONVERGER,
	PATIENT_CONVERGER, # "Converges" onto where the ball will be if it continues on its current path without bounces.
	BOUNCE_PREDICTOR,
	PATIENT_BOUNCE_PREDICTOR, # !!! Accounts for up to one bounce, waits in the center if there will be multiple.
	
	#DOUBLE_PREDICTOR,?
	DEEP_PREDICTOR, # !!! like previous, but accounts for arbirarily many bounces, so no waiting in center.
	MASTER, # Good luck. # !!! like previous, but aggressively tries to aim the ball to where the other player isn't with its paddle hits.
}

var plr1_cpu_mode: int = CPU_MODES.OFF
var plr1_force_slow: bool = false
var plr2_cpu_mode: int = CPU_MODES.PATIENT_BOUNCE_PREDICTOR
var plr2_force_slow: bool = false

var plr1_score: int = 0
var plr1_streak: int = 0
var plr2_score: int = 0
var plr2_streak: int = 0

func _process(_delta):
	#if Input.is_action_pressed("pause_escape"):
		#get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
