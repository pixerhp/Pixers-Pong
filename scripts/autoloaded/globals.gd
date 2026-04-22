extends Node

var GAME_SIZE: Vector2 = Vector2( # Minimum 300x200?
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"),)

var ball_max_speed: float = 4500
var ball_padhit_speedup: float = 35
var prevent_ball_backhits: bool = true

var plr1_cpu_mode: int = CPU_MODES.OFF
var plr1_force_slow: bool = false
var plr2_cpu_mode: int = CPU_MODES.ZIGZAGGER
var plr2_force_slow: bool = false

var plr1_score: int = 0
var plr1_streak: int = 0
var plr2_score: int = 0
var plr2_streak: int = 0

enum CPU_MODES {
	OFF,
	OFF_BUT_YOURE_A_ROBOT, # Beep boop.
	COPYCAT, # Copies the other player's inputs with a one-frame delay.
	RANDOM_MASH, # Mashes random movement inputs. (It's not very effective.)
	ZIGZAGGER, # Alternately moves between the top and bottom paddle positions. 
	CHASER, # Simply "chases" the ball's y-position.
	CONVERGER, # "Converges" onto where the ball will go if it continues on its current path.
	PATIENT_CONVERGER, # Like converger, but situationally waits in the middle.
	BOUNCE_PREDICTOR, # Similar to converger, but can account for one bounce.
	DOUBLE_PREDICTOR, # Similar to bounce predictor, but accounts for up to two bounces.
	DEEP_PREDICTOR, # Predicts where the ball will go after an arbitrary number of bounces.
	MASTER, # Predicts their opponent's paddle hit, and strategically tries to defeat them. Good luck.
}

func _process(_delta):
	#if Input.is_action_pressed("pause_escape"):
		#get_tree().quit()
	if Input.is_action_just_pressed("fullscreen_toggle"):
		if not DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
