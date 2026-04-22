extends Node

func _ready():
	reset_all_gameobjects()
	update_scores_text()
	reset_cpu_inputs(false)
	reset_cpu_inputs(true)
	first_serve_start_time = Time.get_ticks_msec()

func _process(delta: float):
	checkdo_toggle_pause()
	if is_game_paused:
		return
	checkdo_first_serve()
	if not (winloss_reserve_p1_to_conclude):
		checkdo_winloss_condition()
	checkdo_winloss_reserve()
	if not should_handle_regular_gameplay():
		return
	handle_paddle_cpu(false, Globals.plr1_cpu_mode)
	handle_paddle_cpu(true, Globals.plr2_cpu_mode)
	if Globals.plr1_force_slow: set_input("plr1_slow", true)
	if Globals.plr2_force_slow: set_input("plr2_slow", true)
	handle_paddle_controls(false, delta)
	handle_paddle_controls(true, delta)
	handle_ball_collision_movement(delta)
	update_ball_trail()
	handle_paddle_sidebump_animation(false)
	handle_paddle_sidebump_animation(true)
	handle_paddle_knockback_anim(false)
	handle_paddle_knockback_anim(true)

# Variables and functions associated with pausing/unpausing functionality:
var is_game_paused: bool = false
var paused_start_time: int = 0
func checkdo_toggle_pause():
	if Input.is_action_just_pressed("pause_escape"):
		if is_game_paused == false:
			initiate_pause()
		else:
			initiate_unpause()
func initiate_pause():
	%LeftPaddle/%AnimChar.pause()
	%RightPaddle/%AnimChar.pause()
	%Referee.pause()
	paused_start_time = Time.get_ticks_msec()
	is_game_paused = true
	%PauseMenuContainer.visible = true
func initiate_unpause():
	var paused_duration: int = Time.get_ticks_msec() - paused_start_time
	%LeftPaddle.set_meta("sidebump_time", %LeftPaddle.get_meta("sidebump_time") + paused_duration)
	%RightPaddle.set_meta("sidebump_time", %RightPaddle.get_meta("sidebump_time") + paused_duration)
	%LeftPaddle/%MeshContainer.set_meta("knockback_time", %LeftPaddle/%MeshContainer.get_meta("knockback_time") + paused_duration)
	%RightPaddle/%MeshContainer.set_meta("knockback_time", %RightPaddle/%MeshContainer.get_meta("knockback_time") + paused_duration)
	%LeftPaddle/%AnimChar.set_meta("time_surprised", %LeftPaddle/%AnimChar.get_meta("time_surprised") + paused_duration)
	%RightPaddle/%AnimChar.set_meta("time_surprised", %RightPaddle/%AnimChar.get_meta("time_surprised") + paused_duration)
	%LeftPaddle/%AnimChar.play()
	%RightPaddle/%AnimChar.play()
	%Referee.play()
	for i in range(balltrail_times.size()):
		balltrail_times[i] += paused_duration
	first_serve_start_time += paused_duration
	winloss_reserve_start_time == paused_duration
	total_paused_time += paused_duration
	is_game_paused = false
	%PauseMenuContainer.visible = false

func set_court_size(new_court_size: Vector2 = Vector2(
	ProjectSettings.get_setting("display/window/size/viewport_width"),
	ProjectSettings.get_setting("display/window/size/viewport_height"))
):
	Globals.GAME_SIZE = new_court_size
	reset_all_gameobjects()

func reset_all_gameobjects():
	PAD_Y_TOPLIMIT = %LeftPaddle/%FrontBar.mesh.height / 2.0
	PAD_Y_BOTTOMLIMIT = Globals.GAME_SIZE.y - (%LeftPaddle/%FrontBar.mesh.height / 2.0)
	BALL_Y_TOPLIMIT = %BallShapeCast.shape.radius
	BALL_Y_BOTTOMLIMIT = Globals.GAME_SIZE.y - %BallShapeCast.shape.radius
	reset_framing()
	reset_court_decorations()
	update_scores_text()
	reset_scores_visuals()
	reset_paddles()
	reset_ball()
	reset_balltrail()
	reset_referee()
	reset_arrow_pointers()

func reset_framing():
	get_window().set_content_scale_size(Globals.GAME_SIZE)
	%CenteringParent.set_size(Globals.GAME_SIZE)
	%CenteringParent.set_position(
		(get_viewport().get_visible_rect().size / 2.0) - (Globals.GAME_SIZE / 2.0))
	%OuterVignettePanel.set_size(Globals.GAME_SIZE + Vector2(50.0, 50.0))
	var outer_vignette_stylebox: StyleBoxFlat = %OuterVignettePanel.get_theme_stylebox("panel")
	%OuterVignettePanel.set_position(Vector2(
		0.0 - ((outer_vignette_stylebox.border_width_left + outer_vignette_stylebox.border_width_right) / 2.0),
		0.0 - ((outer_vignette_stylebox.border_width_top + outer_vignette_stylebox.border_width_bottom) / 2.0)))
	%ClippingParent.set_size(Globals.GAME_SIZE)
	%ClippingParent.set_position(Vector2(0,0))
func reset_court_decorations():
	%BackgroundColorRect.custom_minimum_size = Globals.GAME_SIZE
	%CornerStripTL.position = Vector2(140, 72)
	%CornerStripTR.position = Vector2(Globals.GAME_SIZE.x - 140, 72)
	%CornerStripBL.position = Vector2(140, Globals.GAME_SIZE.y - 72)
	%CornerStripBR.position = Vector2(Globals.GAME_SIZE.x - 140, Globals.GAME_SIZE.y - 72)
	%Centerline1.position = (Globals.GAME_SIZE / 2.0) + Vector2(-105, 0)
	%Centerline2.position = (Globals.GAME_SIZE / 2.0) + Vector2(-35, 0)
	%Centerline3.position = (Globals.GAME_SIZE / 2.0) + Vector2(35, 0)
	%Centerline4.position = (Globals.GAME_SIZE / 2.0) + Vector2(105, 0)
	%Centerline1.mesh.size.y = Globals.GAME_SIZE.y
	%LeftRailOuter.position = Vector2(120, Globals.GAME_SIZE.y / 2.0)
	%RightRailOuter.position = Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0)
	%LeftRailOuter.mesh.height = Globals.GAME_SIZE.y - 25
	%LeftRailInner.mesh.height = Globals.GAME_SIZE.y - 35
	%CeilingCollisionShape.shape.size.x =  Globals.GAME_SIZE.x 
	%CeilingCollisionShape.position = Vector2(
		Globals.GAME_SIZE.x / 2.0, 
		-1.0 * (%CeilingCollisionShape.shape.size.y / 2.0))
	%FloorCollisionShape.position = Vector2(
		Globals.GAME_SIZE.x / 2.0, 
		Globals.GAME_SIZE.y + (%CeilingCollisionShape.shape.size.y / 2.0))
func reset_scores_visuals():
	%LeftScoreStreak.position = Vector2(Globals.GAME_SIZE.x / 3.25, 70.0)
	%RightScoreStreak.position = Vector2(Globals.GAME_SIZE.x-(Globals.GAME_SIZE.x/3.25), 70.0)
	%LeftScoreStreak.scale = Vector2(0.2, 0.2) 
	%RightScoreStreak.scale = %LeftScoreStreak.scale
	%LeftScoreStreak.rotation = 0.0
	%RightScoreStreak.rotation = %LeftScoreStreak.rotation
	%LeftScoreStreak.modulate.a = 0.24
	%RightScoreStreak.modulate.a = %LeftScoreStreak.modulate.a
func reset_paddles():
	%LeftPaddle.position = Vector2(120, Globals.GAME_SIZE.y / 2.0)
	%RightPaddle.position = Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0)
	%LeftPaddle/%AnimChar.animation = (
		("plr_" if (Globals.plr1_cpu_mode == Globals.CPU_MODES.OFF) else "bot_") + "idle")
	%RightPaddle/%AnimChar.animation = (
		("plr_" if (Globals.plr2_cpu_mode == Globals.CPU_MODES.OFF) else "bot_") + "idle")
	%LeftPaddle.set_meta("velocity", 0.0)
	%RightPaddle.set_meta("sidebump_strength", %LeftPaddle.get_meta("velocity"))
	%LeftPaddle.set_meta("sidebump_time", -99999999)
	%RightPaddle.set_meta("sidebump_time", %LeftPaddle.get_meta("sidebump_time"))
	%LeftPaddle.set_meta("sidebump_strength", 0.0)
	%RightPaddle.set_meta("sidebump_strength", %LeftPaddle.get_meta("sidebump_strength"))
	%LeftPaddle.modulate = Color.WHITE
	%RightPaddle.modulate = Color.WHITE
func reset_ball():
	%Ball.position = Globals.GAME_SIZE / 2.0
	ball_velocity = Vector2(0.0, 0.0)
	ballshapecast_current_exceptions.clear()
	%BallShapeCast.clear_exceptions()
	%Ball.modulate = Color.WHITE
func reset_balltrail():
	balltrail_positions.clear()
	balltrail_times.clear()
	%BallTrail.points = PackedVector2Array([])
func reset_referee():
	%Referee.position = Vector2(Globals.GAME_SIZE.x/2.0, Globals.GAME_SIZE.y + 144.0)
	%Referee.scale.x = 1.0
	%Referee.play("idle")
func reset_arrow_pointers():
	%PrimaryArrowPointer.visible = false
	%PrimaryArrowPointer/%QuestionSprite.visible = false
	%PrimaryArrowPointer.position = Globals.GAME_SIZE / 2.0
	%PrimaryArrowPointer/%RotationContainer.rotation_degrees = 0.0
	%SecondaryArrowPointer.visible = %PrimaryArrowPointer.visible
	%SecondaryArrowPointer/%QuestionSprite.visible = %PrimaryArrowPointer/%QuestionSprite.visible
	%SecondaryArrowPointer.position = %PrimaryArrowPointer.position
	%SecondaryArrowPointer/%RotationContainer.rotation_degrees = 180.0

const STREAK_PREFIX: String = "🗘"
func update_scores_text():
	%LeftScoreStreak/%ScoreContainer/%ScoreLabel.text = str(Globals.plr1_score)
	if Globals.plr1_streak == 0: %LeftScoreStreak/%StreakContainer/%StreakLabel.text = ""
	else: %LeftScoreStreak/%StreakContainer/%StreakLabel.text = STREAK_PREFIX + str(Globals.plr1_streak)
	%RightScoreStreak/%ScoreContainer/%ScoreLabel.text = str(Globals.plr2_score)
	if Globals.plr2_streak == 0: %RightScoreStreak/%StreakContainer/%StreakLabel.text = ""
	else: %RightScoreStreak/%StreakContainer/%StreakLabel.text = STREAK_PREFIX + str(Globals.plr2_streak)

# Animations convenience functions:
func is_in_range_i(value: int, range_min: int, range_max: int) -> bool:
	return ((range_min <= value) and (value <= range_max))
func is_in_range_f(value: float, range_min: float, range_max: float) -> bool:
	return ((range_min <= value) and (value <= range_max))
func proportion_from_range(current: float, range_start: float, range_end: float) -> float:
	return ((current - range_start) / (range_end - range_start))
func ease_out_back(ratio: float, c: float) -> float:
	return 1 + ((c + 1) * pow(ratio - 1, 3)) + (c *  pow(ratio - 1, 2))
func ease_out(ratio: float, power: float) -> float:
	return 1 - pow(1 - ratio, power);
func ease_in_out(ratio: float, power: float) -> float:
	return (
		(pow(2, power - 1) * pow(ratio, power))
		if (ratio < 0.5) else
		(1 - (pow((-2.0 * ratio) + 2, power) / 2.0)))


# Constants, variables and code related to the 'first serve' that occurs when you start playing:
var first_serve_start_time: int = Time.get_ticks_msec()
func checkdo_first_serve():
	# First serve part 1 (plays up until when the ball starts moving):
	var playthrough: float = proportion_from_range(
		Time.get_ticks_msec(), first_serve_start_time, first_serve_start_time + FIRST_SERVE_P1_DURATION)
	if is_in_range_f(playthrough, 0.0, 1.0):
		first_serve_p1_to_conclude = true
		handle_first_serve_p1_animation(playthrough)
		return
	if first_serve_p1_to_conclude:
		first_serve_p1_to_conclude = false
		handle_first_serve_p1_conclusion()
	# First serve part 2 (plays after the ball starts moving):
	playthrough = proportion_from_range(
		Time.get_ticks_msec(), 
		first_serve_start_time + FIRST_SERVE_P1_DURATION, 
		first_serve_start_time + FIRST_SERVE_P1_DURATION + FIRST_SERVE_P2_DURATION)
	if is_in_range_f(playthrough, 0.0, 1.0):
		first_serve_p2_to_conclude = true
		handle_first_serve_p2_animation(playthrough)
		return
	if first_serve_p2_to_conclude:
		first_serve_p2_to_conclude = false
		handle_first_serve_p2_conclusion()

const FIRST_SERVE_P1_DURATION: int = 5000
func handle_first_serve_p1_animation(playthrough: float):
	# Paddles slide-in animation:
	const PADS_SLIDEIN_START: float = 0.0
	const PADS_SLIDEIN_END: float = 0.15
	%LeftPaddle.position.x = -120.0 + (240.0 * 
		clampf(proportion_from_range(playthrough, PADS_SLIDEIN_START, PADS_SLIDEIN_END), 0.0, 1.0))
	%RightPaddle.position.x = Globals.GAME_SIZE.x - %LeftPaddle.position.x
	# Paddles darkening (to help indicate/imply your inability to move):
	%LeftPaddle.modulate = Color.GRAY
	%RightPaddle.modulate = Color.GRAY
	# Scores/streaks ease-in animation:
	const SCORES_EASEIN_START: float = 0.075
	const SCORES_EASEIN_END: float = 0.2
	%LeftScoreStreak.position.y = -70.0 + (140.0 * ease_out_back(clampf(
		proportion_from_range(playthrough, SCORES_EASEIN_START, SCORES_EASEIN_END), 0.0, 1.0), 1.1))
	%RightScoreStreak.position.y = %LeftScoreStreak.position.y
	# Referee slide-in animation:
	const REF_SLIDEIN_START: float = 0.1
	const REF_SLIDEIN_END: float = 0.2
	%Referee.position.y = Globals.GAME_SIZE.y + (144.0 - (288.0 * 
		clampf(proportion_from_range(playthrough, REF_SLIDEIN_START, REF_SLIDEIN_END), 0.0, 1.0)))
	# Referee countdown:
	const REF_COUNT_START: float = 0.4
	const REF_COUNT_END: float = 1.0
	const REF_COUNT_MID1: float = REF_COUNT_START + ((REF_COUNT_END - REF_COUNT_START) / 3.0)
	const REF_COUNT_MID2: float = REF_COUNT_START + ((REF_COUNT_END - REF_COUNT_START) / 1.5)
	if (playthrough < REF_COUNT_START) or (playthrough > REF_COUNT_END): 
		%Referee.play("idle")
	elif (playthrough < REF_COUNT_MID1): 
		%Referee.play("count_3")
	elif (playthrough < REF_COUNT_MID2): 
		%Referee.play("count_2")
	else:
		%Referee.play("count_1")
	# Arrow pointers fade-in and visibility:
	const ARROWS_FADEIN_START: float = REF_COUNT_START / 2.0
	const ARROWS_FADEIN_END: float = REF_COUNT_START
	%PrimaryArrowPointer.visible = playthrough > ARROWS_FADEIN_START
	%SecondaryArrowPointer.visible = %PrimaryArrowPointer.visible
	%PrimaryArrowPointer/%QuestionSprite.visible = %PrimaryArrowPointer.visible
	%SecondaryArrowPointer/%QuestionSprite.visible = %PrimaryArrowPointer/%QuestionSprite.visible
	%PrimaryArrowPointer.modulate = Color(1.0, 1.0, 1.0, 
		clampf(proportion_from_range(playthrough, ARROWS_FADEIN_START, ARROWS_FADEIN_END) / 2.0, 0.0, 0.5))
	%SecondaryArrowPointer.modulate = %PrimaryArrowPointer.modulate
	# Arrow pointers movement:
	%PrimaryArrowPointer/%RotationContainer.rotation_degrees = (
		(22.5 * sin(float(Time.get_ticks_msec()) / 324.34)))
	%SecondaryArrowPointer/%RotationContainer.rotation_degrees = 180 + (
		(22.5 * sin(float(Time.get_ticks_msec() + 32528437) / 284.83)))

var first_serve_p1_to_conclude: bool = false
func handle_first_serve_p1_conclusion():
	reset_paddles()
	reset_scores_visuals()
	reset_referee()
	%Referee.position.y = Globals.GAME_SIZE.y - 144.0
	reset_arrow_pointers()
	reset_ball()
	ball_velocity = random_serve_velocity()

const FIRST_SERVE_P2_DURATION: int = 1500
func handle_first_serve_p2_animation(playthrough: float):
	const POINTING_LOWERING_SPLIT: float = 0.666666
	# Referee animation handling:
	if (playthrough > POINTING_LOWERING_SPLIT) or is_equal_approx(ball_velocity.x, 0.0):
		%Referee.scale.x = 1.0
		%Referee.play("idle")
	else:
		%Referee.play("serve_gesture")
		%Referee.scale.x = (-1.0 if (ball_velocity.x < 0.0) else 1.0)
	# Referee position handling:
	if (playthrough > POINTING_LOWERING_SPLIT):
		%Referee.position.y = (
			(Globals.GAME_SIZE.y - 144.0) +
			288.0 * proportion_from_range(playthrough, POINTING_LOWERING_SPLIT, 1.0)
		)

var first_serve_p2_to_conclude: bool = false
func handle_first_serve_p2_conclusion():
	reset_referee()

var winloss_reserve_ball_s_pos: Vector2 = Vector2()
var winloss_reserve_lpad_s_pos: Vector2 = Vector2()
var winloss_reserve_rpad_s_pos: Vector2 = Vector2()
func checkdo_winloss_condition():
	# Check whether the ball is significantly past the left/right paddle:
	const EDGE_CLEARANCE: float = 60.0
	if not (abs(%Ball.position.x - (Globals.GAME_SIZE.x / 2.0)) > ((Globals.GAME_SIZE.x / 2.0) + EDGE_CLEARANCE)):
		return
	# Change player scores/streaks:
	if (%Ball.position.x < (Globals.GAME_SIZE.x / 2.0)):
		Globals.plr2_score += 1; Globals.plr2_streak += 1; Globals.plr1_streak = 0;
	else:
		Globals.plr1_score += 1; Globals.plr1_streak += 1; Globals.plr2_streak = 0;
	update_scores_text()
	# Update other variables in preparation for the winloss animations:
	winloss_reserve_ball_s_pos = %Ball.position
	winloss_reserve_lpad_s_pos = %LeftPaddle.position
	winloss_reserve_rpad_s_pos = %RightPaddle.position
	reset_balltrail()
	winloss_reserve_start_time = Time.get_ticks_msec()


var winloss_reserve_start_time: int = -9999999
func checkdo_winloss_reserve():
	# Winloss reserve part 1 (plays up until when the ball starts moving):
	var playthrough: float = proportion_from_range(Time.get_ticks_msec(), 
		winloss_reserve_start_time, 
		winloss_reserve_start_time + WINLOSS_RESERVE_P1_DURATION)
	if is_in_range_f(playthrough, 0.0, 1.0):
		winloss_reserve_p1_to_conclude = true
		handle_winloss_reserve_p1_animation(playthrough)
		return
	if winloss_reserve_p1_to_conclude:
		winloss_reserve_p1_to_conclude = false
		handle_winloss_reserve_p1_conclusion()
	# Winloss reserve part 2 (plays after the ball starts moving):
	playthrough = proportion_from_range(Time.get_ticks_msec(), 
		winloss_reserve_start_time + WINLOSS_RESERVE_P1_DURATION, 
		winloss_reserve_start_time + WINLOSS_RESERVE_P1_DURATION + WINLOSS_RESERVE_P2_DURATION)
	if is_in_range_f(playthrough, 0.0, 1.0):
		winloss_reserve_p2_to_conclude = true
		handle_winloss_reserve_p2_animation(playthrough)
		return
	if winloss_reserve_p2_to_conclude:
		winloss_reserve_p2_to_conclude = false
		handle_winloss_reserve_p2_conclusion()

# !!! Note: plan is to make the scores opaque, scale them up and move them, 
# and rotate them back and forth slightly after a win/lose, and then transition them back to normal.
const WINLOSS_RESERVE_P1_DURATION: int = 5000
func handle_winloss_reserve_p1_animation(playthrough: float):
	# Score/streak animation:
	const SCORE_FADEIN_START: float = 0.0
	const SCORE_FADEIN_END: float = 0.2
	%LeftScoreStreak.modulate = Color(1.0, 1.0, 1.0, 0.24 +
		clampf(proportion_from_range(playthrough, SCORE_FADEIN_START, SCORE_FADEIN_END), 0.0, 1.0) * 0.5)
	%RightScoreStreak.modulate = %LeftScoreStreak.modulate
	# Referee slide-in animation:
	const REF_SLIDEIN_START: float = 0.0
	const REF_SLIDEIN_END: float = 0.15
	%Referee.position.y = Globals.GAME_SIZE.y + (144.0 - (288.0 * 
		clampf(proportion_from_range(playthrough, REF_SLIDEIN_START, REF_SLIDEIN_END), 0.0, 1.0)))
	# Referee animation:
	const REF_COUNT_START: float = 0.675
	const REF_COUNT_END: float = 1.0
	const REF_COUNT_MID1: float = REF_COUNT_START + ((REF_COUNT_END - REF_COUNT_START) / 3.0)
	const REF_COUNT_MID2: float = REF_COUNT_START + ((REF_COUNT_END - REF_COUNT_START) / 1.5)
	if (playthrough < REF_COUNT_START):
		%Referee.scale.x = (-1.0 if (Globals.plr1_streak > 0) else 1.0)
		%Referee.play("winner_gesture")
	else:
		%Referee.scale.x = 1.0
		if (playthrough < REF_COUNT_MID1): 
			%Referee.play("count_3")
		elif (playthrough < REF_COUNT_MID2): 
			%Referee.play("count_2")
		else:
			%Referee.play("count_1")
	# Paddles sliding animation:
	const PADS_SLIDE_START: float = 0.0
	const PADS_SLIDE_END: float = 0.1
	var weight: float = ease_in_out(clampf(proportion_from_range(playthrough, PADS_SLIDE_START, PADS_SLIDE_END), 0.0, 1.0), 2.0)
	%LeftPaddle.position = ((winloss_reserve_lpad_s_pos * (1.0-weight)) + 
		(Vector2(120, Globals.GAME_SIZE.y / 2.0) * weight))
	%RightPaddle.position = ((winloss_reserve_rpad_s_pos * (1.0-weight)) + 
		(Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0) * weight))
	# Paddle character animations:
	if (playthrough > REF_COUNT_START):
		%LeftPaddle.modulate = Color.GRAY
		%RightPaddle.modulate = Color.GRAY
	if ((playthrough < PADS_SLIDE_END) or (playthrough > REF_COUNT_START)):
		%LeftPaddle/%AnimChar.play("plr_idle" if (Globals.plr1_cpu_mode == Globals.CPU_MODES.OFF) else "bot_idle")
		%RightPaddle/%AnimChar.play("plr_idle" if (Globals.plr2_cpu_mode == Globals.CPU_MODES.OFF) else "bot_idle")
	else:
		%LeftPaddle/%AnimChar.play(
			("plr_win" if (Globals.plr1_cpu_mode == Globals.CPU_MODES.OFF) else "bot_win")
			if (Globals.plr1_streak > 0) else
			("plr_lose" if (Globals.plr1_cpu_mode == Globals.CPU_MODES.OFF) else "bot_lose"))
		%RightPaddle/%AnimChar.play(
			("plr_win" if (Globals.plr2_cpu_mode == Globals.CPU_MODES.OFF) else "bot_win")
			if (Globals.plr2_streak > 0) else
			("plr_lose" if (Globals.plr2_cpu_mode == Globals.CPU_MODES.OFF) else "bot_lose"))
	# Arrow pointers fade-in and visibility:
	const ARROWS_FADEIN_START: float = 0.5
	const ARROWS_FADEIN_END: float = REF_COUNT_MID1
	%PrimaryArrowPointer.visible = playthrough > ARROWS_FADEIN_START
	%SecondaryArrowPointer.visible = %PrimaryArrowPointer.visible
	%PrimaryArrowPointer/%QuestionSprite.visible = %PrimaryArrowPointer.visible
	%SecondaryArrowPointer/%QuestionSprite.visible = %PrimaryArrowPointer/%QuestionSprite.visible
	%PrimaryArrowPointer.modulate = Color(1.0, 1.0, 1.0, 
		clampf(proportion_from_range(playthrough, ARROWS_FADEIN_START, ARROWS_FADEIN_END) / 2.0, 0.0, 0.5))
	%SecondaryArrowPointer.modulate = %PrimaryArrowPointer.modulate
	# Arrow pointers movement:
	%PrimaryArrowPointer/%RotationContainer.rotation_degrees = (
		(22.5 * sin(float(Time.get_ticks_msec()) / 324.34)))
	%SecondaryArrowPointer/%RotationContainer.rotation_degrees = 180 + (
		(22.5 * sin(float(Time.get_ticks_msec() + 32528437) / 284.83)))

var winloss_reserve_p1_to_conclude: bool = false
func handle_winloss_reserve_p1_conclusion():
	reset_referee()
	reset_paddles()
	reset_arrow_pointers()
	
	reset_ball()
	ball_velocity = random_serve_velocity()

const WINLOSS_RESERVE_P2_DURATION: int = 1000
func handle_winloss_reserve_p2_animation(playthrough: float):
	pass

var winloss_reserve_p2_to_conclude: bool = false
func handle_winloss_reserve_p2_conclusion():
	reset_scores_visuals()
	reset_referee()
	pass

# [a temporary placeholder for re-serving the ball, has no animations or variation]
func temptest_reserve_ball():
	update_scores_text()
	reset_ball()
	ball_velocity = Vector2(-400.0, 0.0)
	reset_balltrail()

# !!! add foul ball detection + animation, and foul ball reserve animations

func random_serve_velocity() -> Vector2:
	return Vector2(250.0*(((randi()%2)*2)-1), 0.0).rotated(deg_to_rad(randf_range(-22.5, 22.5)))

func should_handle_regular_gameplay() -> bool:
	return not (
		first_serve_p1_to_conclude or
		winloss_reserve_p1_to_conclude # !!! or foul ball serving animation
	)

var RANDOM_MOVEMENT_SEED_OFFSET: int = randi()
var total_paused_time: int = 0
func handle_paddle_cpu(is_plr2: bool, ai_mode):
	var paddle_noderef: Node2D = %RightPaddle if is_plr2 else %LeftPaddle
	var act_prefix: String = "plr2_" if is_plr2 else "plr1_"
	var alt_act_prefix: String = "plr1_" if is_plr2 else "plr2_"
	
	match ai_mode:
		Globals.CPU_MODES.OFF, Globals.CPU_MODES.OFF_BUT_YOURE_A_ROBOT:
			return
		
		Globals.CPU_MODES.COPYCAT:
			set_input(act_prefix + "up", Input.is_action_pressed(alt_act_prefix + "up"))
			set_input(act_prefix + "down", Input.is_action_pressed(alt_act_prefix + "down"))
			set_input(act_prefix + "slow", Input.is_action_pressed(alt_act_prefix + "slow"))
			set_input(act_prefix + "bump_left", Input.is_action_pressed(alt_act_prefix + "bump_right"))
			set_input(act_prefix + "bump_right", Input.is_action_pressed(alt_act_prefix + "bump_left"))
		
		Globals.CPU_MODES.RANDOM_MASH:
			const RANDOM_MOVEMENT_DURATION: int = 32
			var rng = RandomNumberGenerator.new()
			@warning_ignore("integer_division")
			rng.seed = ((Time.get_ticks_msec() - total_paused_time) / RANDOM_MOVEMENT_DURATION) * (314 if is_plr2 else 1)
			rng.seed += RANDOM_MOVEMENT_SEED_OFFSET
			if ((rng.randi() % 3) == 0):
				set_input(act_prefix + "up", false)
				set_input(act_prefix + "down", false)
			else:
				if ((rng.randi() % 2) == 0):
					set_input(act_prefix + "up", true)
					set_input(act_prefix + "down", false)
				else:
					set_input(act_prefix + "up", false)
					set_input(act_prefix + "down", true)
			set_input(act_prefix + "slow", ((rng.randi() % 4) == 0))
			if ((rng.randi() % 32) == 0):
				if ((rng.randi() % 2) == 0):
					set_input(act_prefix + "bump_left", true)
					set_input(act_prefix + "bump_right", false)
				else:
					set_input(act_prefix + "bump_left", false)
					set_input(act_prefix + "bump_right", true)
			else:
				set_input(act_prefix + "bump_left", false)
				set_input(act_prefix + "bump_right", false)
		
		Globals.CPU_MODES.ZIGZAGGER:
			if paddle_noderef.get_meta("velocity") == 0.0:
				if paddle_noderef.position.y < Globals.GAME_SIZE.y / 2.0:
					set_input(act_prefix + "up", false)
					set_input(act_prefix + "down", true)
				else:
					set_input(act_prefix + "up", true)
					set_input(act_prefix + "down", false)
		
		Globals.CPU_MODES.CHASER:
			var vert_diff: float = %Ball.position.y - paddle_noderef.position.y
			if (
				(Input.is_action_pressed(act_prefix + "up") and (vert_diff > 0.0)) or 
				(Input.is_action_pressed(act_prefix + "down") and (vert_diff < 0.0)) or 
				(abs(vert_diff) < (0.25 * PAD_Y_TOPLIMIT))
			):
				set_input(act_prefix + "up", false)
				set_input(act_prefix + "down", false)
			elif (vert_diff < (-0.5 * PAD_Y_TOPLIMIT)):
				set_input(act_prefix + "up", (paddle_noderef.position.y > PAD_Y_TOPLIMIT))
				set_input(act_prefix + "down", false)
			elif (vert_diff > (0.5 * PAD_Y_TOPLIMIT)):
				set_input(act_prefix + "up", false)
				set_input(act_prefix + "down", (paddle_noderef.position.y < PAD_Y_BOTTOMLIMIT))
		
		Globals.CPU_MODES.CONVERGER:
			var predicted_ball_y: float = %Ball.position.y + ((ball_velocity.y / ball_velocity.x) * (
				(%RightPaddle.position.x if (ball_velocity.x > 0.0) else %LeftPaddle.position.x) - %Ball.position.x))
			set_input(act_prefix + "up", paddle_noderef.position.y > predicted_ball_y + (PAD_Y_TOPLIMIT * 0.5))
			set_input(act_prefix + "down", paddle_noderef.position.y < predicted_ball_y - (PAD_Y_TOPLIMIT * 0.5))
		
		Globals.CPU_MODES.PATIENT_CONVERGER:
			var predicted_ball_y: float = %Ball.position.y + ((ball_velocity.y / ball_velocity.x) * (
				(%RightPaddle.position.x if (ball_velocity.x > 0.0) else %LeftPaddle.position.x) - %Ball.position.x))
			if ( # Wait in the center if the ball is travelling to the other player or is predicted OOB:
				((ball_velocity.x < 0.0) if is_plr2 else (ball_velocity.x > 0.0)) or 
				(predicted_ball_y < BALL_Y_TOPLIMIT) or (predicted_ball_y > BALL_Y_BOTTOMLIMIT)
			):
				set_input(act_prefix + "up", paddle_noderef.position.y > ((Globals.GAME_SIZE.y / 2.0) + (PAD_Y_TOPLIMIT * 0.5)))
				set_input(act_prefix + "down", paddle_noderef.position.y < ((Globals.GAME_SIZE.y / 2.0) - (PAD_Y_TOPLIMIT * 0.5)))
			else: # Else move to the predicted ball location:
				set_input(act_prefix + "up", paddle_noderef.position.y > predicted_ball_y + (PAD_Y_TOPLIMIT * 0.5))
				set_input(act_prefix + "down", paddle_noderef.position.y < predicted_ball_y - (PAD_Y_TOPLIMIT * 0.5))
		
		Globals.CPU_MODES.BOUNCE_PREDICTOR:
			var predicted_ball_y: float = %Ball.position.y + ((ball_velocity.y / ball_velocity.x) * (
				(%RightPaddle.position.x if (ball_velocity.x > 0.0) else %LeftPaddle.position.x) - %Ball.position.x))
			if predicted_ball_y < BALL_Y_TOPLIMIT:
				predicted_ball_y = BALL_Y_TOPLIMIT + (BALL_Y_TOPLIMIT - predicted_ball_y)
			elif predicted_ball_y > BALL_Y_BOTTOMLIMIT:
				predicted_ball_y = BALL_Y_BOTTOMLIMIT - (predicted_ball_y - BALL_Y_BOTTOMLIMIT)
			if ((ball_velocity.x < 0.0) if is_plr2 else (ball_velocity.x > 0.0)):
				set_input(act_prefix + "up", false)
				set_input(act_prefix + "down", false)
			else:
				set_input(act_prefix + "up", paddle_noderef.position.y > predicted_ball_y + (PAD_Y_TOPLIMIT * 0.5))
				set_input(act_prefix + "down", paddle_noderef.position.y < predicted_ball_y - (PAD_Y_TOPLIMIT * 0.5))
		
		Globals.CPU_MODES.DOUBLE_PREDICTOR:
			var predicted_ball_y: float = %Ball.position.y + ((ball_velocity.y / ball_velocity.x) * (
				(%RightPaddle.position.x if (ball_velocity.x > 0.0) else %LeftPaddle.position.x) - %Ball.position.x))
			const BOUNCE_LIMIT: int = 2
			for i in range(BOUNCE_LIMIT):
				if predicted_ball_y < BALL_Y_TOPLIMIT:
					predicted_ball_y = BALL_Y_TOPLIMIT + (BALL_Y_TOPLIMIT - predicted_ball_y)
				elif predicted_ball_y > BALL_Y_BOTTOMLIMIT:
					predicted_ball_y = BALL_Y_BOTTOMLIMIT - (predicted_ball_y - BALL_Y_BOTTOMLIMIT)
				else:
					break
				if i >= (BOUNCE_LIMIT - 1):
					set_input(act_prefix + "up", paddle_noderef.position.y > ((Globals.GAME_SIZE.y / 2.0) + (PAD_Y_TOPLIMIT * 0.5)))
					set_input(act_prefix + "down", paddle_noderef.position.y < ((Globals.GAME_SIZE.y / 2.0) - (PAD_Y_TOPLIMIT * 0.5)))
					return
			if ((ball_velocity.x < 0.0) if is_plr2 else (ball_velocity.x > 0.0)):
				set_input(act_prefix + "up", false)
				set_input(act_prefix + "down", false)
			else:
				set_input(act_prefix + "up", paddle_noderef.position.y > predicted_ball_y + (PAD_Y_TOPLIMIT * 0.5))
				set_input(act_prefix + "down", paddle_noderef.position.y < predicted_ball_y - (PAD_Y_TOPLIMIT * 0.5))
		
		Globals.CPU_MODES.DEEP_PREDICTOR:
			var predicted_ball_y: float = %Ball.position.y + ((ball_velocity.y / ball_velocity.x) * (
				(%RightPaddle.position.x if (ball_velocity.x > 0.0) else %LeftPaddle.position.x) - %Ball.position.x))
			const BOUNCE_LIMIT: int = 8
			for i in range(BOUNCE_LIMIT):
				if predicted_ball_y < BALL_Y_TOPLIMIT:
					predicted_ball_y = BALL_Y_TOPLIMIT + (BALL_Y_TOPLIMIT - predicted_ball_y)
				elif predicted_ball_y > BALL_Y_BOTTOMLIMIT:
					predicted_ball_y = BALL_Y_BOTTOMLIMIT - (predicted_ball_y - BALL_Y_BOTTOMLIMIT)
				else:
					break
				if i >= (BOUNCE_LIMIT - 1):
					set_input(act_prefix + "up", paddle_noderef.position.y > ((Globals.GAME_SIZE.y / 2.0) + (PAD_Y_TOPLIMIT * 0.5)))
					set_input(act_prefix + "down", paddle_noderef.position.y < ((Globals.GAME_SIZE.y / 2.0) - (PAD_Y_TOPLIMIT * 0.5)))
					return
			if ((ball_velocity.x < 0.0) if is_plr2 else (ball_velocity.x > 0.0)):
				set_input(act_prefix + "up", false)
				set_input(act_prefix + "down", false)
			else:
				set_input(act_prefix + "up", paddle_noderef.position.y > predicted_ball_y + (PAD_Y_TOPLIMIT * 0.5))
				set_input(act_prefix + "down", paddle_noderef.position.y < predicted_ball_y - (PAD_Y_TOPLIMIT * 0.5))
		
		Globals.CPU_MODES.MASTER:
			var PAD_HIT_TOL: float = 8.0 + BALL_Y_TOPLIMIT
			
			# Dive backwards to the ball if it's behind the paddle:
			if ((%Ball.position.x > (%RightPaddle.position.x + PAD_HIT_TOL)) if is_plr2 else (%Ball.position.x < (%LeftPaddle.position.x - PAD_HIT_TOL))):
				set_input(act_prefix + "up", (paddle_noderef.position.y > %Ball.position.y))
				set_input(act_prefix + "down", (paddle_noderef.position.y < %Ball.position.y))
				set_input(act_prefix + "slow", false)
				set_input(act_prefix + ("bump_right" if is_plr2 else "bump_left"), true)
				return
			else:
				set_input(act_prefix + ("bump_right" if is_plr2 else "bump_left"), false)
			
			var WALL_HIT_TOL: float = clamp(-2.5 * log(0.004 * abs(ball_velocity.y)), 0, 25) # (Based on weak empirically determined data.)
			var ball_x_distance_to_hit: float = (
				(
					((%RightPaddle.position.x - PAD_HIT_TOL) - %Ball.position.x
					) if (ball_velocity.x > 0.0) else (
						(%Ball.position.x - (%LeftPaddle.position.x + PAD_HIT_TOL)) + ((%RightPaddle.position.x - PAD_HIT_TOL) - (%LeftPaddle.position.x + PAD_HIT_TOL)))
				) if is_plr2 else (
					(%Ball.position.x - (%LeftPaddle.position.x + PAD_HIT_TOL)
					) if (ball_velocity.x < 0.0) else (
						((%RightPaddle.position.x - PAD_HIT_TOL) - %Ball.position.x) + ((%RightPaddle.position.x - PAD_HIT_TOL) - (%LeftPaddle.position.x + PAD_HIT_TOL)))
				)
			)
			var predicted_ball_y: float = %Ball.position.y + (
				(ball_velocity.y / (abs(ball_velocity.x) * (1.0 if is_plr2 else 1.0))) * ball_x_distance_to_hit
			)
			const BOUNCE_LIMIT: int = 64
			for i in range(BOUNCE_LIMIT):
				if predicted_ball_y < (BALL_Y_TOPLIMIT + WALL_HIT_TOL):
					predicted_ball_y = (BALL_Y_TOPLIMIT + WALL_HIT_TOL) + ((BALL_Y_TOPLIMIT + WALL_HIT_TOL) - predicted_ball_y)
				elif predicted_ball_y > (BALL_Y_BOTTOMLIMIT - WALL_HIT_TOL):
					predicted_ball_y = (BALL_Y_BOTTOMLIMIT - WALL_HIT_TOL) - (predicted_ball_y - (BALL_Y_BOTTOMLIMIT - WALL_HIT_TOL))
				else:
					break
			
			var targ_y: float = predicted_ball_y
			set_input(act_prefix + ("bump_left" if is_plr2 else "bump_right"), false)
			
			# Random trajectory angling movement:
			if ((ball_velocity.x > 0.0) if (is_plr2) else (ball_velocity.x < 0.0)):
				const DECISION_DURATION: int = 628
				var rng = RandomNumberGenerator.new()
				@warning_ignore("integer_division")
				rng.seed = ((Time.get_ticks_msec() - total_paused_time) / DECISION_DURATION) * (222 if is_plr2 else 1)
				rng.seed += RANDOM_MOVEMENT_SEED_OFFSET
				match (rng.randi() % 5):
					1: targ_y += (PAD_Y_TOPLIMIT * -0.9)
					2: targ_y += (PAD_Y_TOPLIMIT * -0.6)
					3: pass
					4: targ_y += (PAD_Y_TOPLIMIT * 0.6)
					5: targ_y += (PAD_Y_TOPLIMIT * 0.9)
				if (
					(abs(ball_x_distance_to_hit / ball_velocity.x) < 0.1) and 
					(abs(ball_velocity.x) < (1750.0 * 0.43922 * ((%RightPaddle.position.x - %LeftPaddle.position.x) / (PAD_Y_BOTTOMLIMIT - PAD_Y_TOPLIMIT))))
				):
					set_input(act_prefix + ("bump_left" if is_plr2 else "bump_right"), true)
			
			set_input(act_prefix + "up", 
				(paddle_noderef.position.y > targ_y) and 
				(not (abs(paddle_noderef.position.y - targ_y) < (PAD_Y_TOPLIMIT * 0.05))) and 
				(not paddle_noderef.position.y <= PAD_Y_TOPLIMIT))
			set_input(act_prefix + "down", 
				(paddle_noderef.position.y < targ_y) and 
				(not (abs(paddle_noderef.position.y - targ_y) < (PAD_Y_TOPLIMIT * 0.05))) and 
				(not paddle_noderef.position.y >= PAD_Y_BOTTOMLIMIT))
			set_input(act_prefix + "slow", abs(paddle_noderef.position.y - targ_y) < (PAD_Y_TOPLIMIT * 0.25))

func reset_cpu_inputs(is_plr2: bool):
	if is_plr2:
		set_input("plr2_up", false)
		set_input("plr2_down", false)
		set_input("plr2_slow", false)
		set_input("plr2_bump_left", false)
		set_input("plr2_bump_right", false)
	else:
		set_input("plr1_up", false)
		set_input("plr1_down", false)
		set_input("plr1_slow", false)
		set_input("plr1_bump_left", false)
		set_input("plr1_bump_right", false)

func set_input(action_name: String, state: bool):
	var input_event = InputEventAction.new()
	input_event.action = action_name
	input_event.pressed = state
	Input.parse_input_event(input_event)

# Constants associated with paddle movement:
const PAD_MOVEACCEL: float = 14400.0
const PAD_MAXSPEED: float = 1250.0
const PAD_SLOWDOWN: float = 0.05 # Note: Values closer to 0 correlate with higher friction.
@onready var PAD_Y_TOPLIMIT: float = %LeftPaddle/%FrontBar.mesh.height / 2.0
@onready var PAD_Y_BOTTOMLIMIT: float = Globals.GAME_SIZE.y - (%LeftPaddle/%FrontBar.mesh.height / 2.0)
const SURP_EXPR_VARIATION: float = 750.0
const SURP_EXPR_BASE: float = 250.0
const SURP_EXPR_FALLOFF: float = 750.0

func handle_paddle_controls(is_plr2: bool, delta: float):
	# Player-specific setup:
	var paddle_noderef: Node2D = (%RightPaddle if is_plr2 else %LeftPaddle)
	#var paddlemesh_noderef: Node2D = (%RightPaddle/%MeshContainer if is_plr2 else %LeftPaddle/%MeshContainer)
	var paddlemesh_bars_noderef: Node2D = (%RightPaddle/%BarsContainer if is_plr2 else %LeftPaddle/%BarsContainer)
	var padchar_noderef: AnimatedSprite2D = (%RightPaddle/%AnimChar if is_plr2 else %LeftPaddle/%AnimChar)
	var padchar_anim_prefix: String = "plr_" if ((Globals.plr2_cpu_mode if is_plr2 else Globals.plr1_cpu_mode) == Globals.CPU_MODES.OFF) else "bot_"
	var plr_prefix: String = ("plr2_" if is_plr2 else "plr1_")
	# General setup:
	var pad_vel: float = paddle_noderef.get_meta("velocity")
	var slow_effect: float = (0.3 if Input.is_action_pressed(plr_prefix + "slow") else 1.0)
	if slow_effect == 1.0:
		paddlemesh_bars_noderef.modulate = Color.WHITE
	else:
		paddlemesh_bars_noderef.modulate = Color.LIGHT_GRAY
	
	# Handle sidebump inputs:
	if (Time.get_ticks_msec() - paddle_noderef.get_meta("sidebump_time")) > SIDEBUMP_DURATION:
		if Input.is_action_pressed(plr_prefix + "bump_right"):
			paddle_noderef.set_meta("sidebump_time", Time.get_ticks_msec())
			paddle_noderef.set_meta("sidebump_strength", SIDEBUMP_STRENGTH_AMOUNT * (-1.0 if is_plr2 else 1.0))
		elif Input.is_action_pressed(plr_prefix + "bump_left"):
			paddle_noderef.set_meta("sidebump_time", Time.get_ticks_msec())
			paddle_noderef.set_meta("sidebump_strength", -1.0 * SIDEBUMP_STRENGTH_AMOUNT * (-1.0 if is_plr2 else 1.0))
	
	# Other movement controls are disabled if the player is in a bump left/right state:
	if (Time.get_ticks_msec() - paddle_noderef.get_meta("sidebump_time")) < SIDEBUMP_DURATION:
		pad_vel *= pow(PAD_SLOWDOWN, delta)
		if abs(pad_vel) < 0.1:
			padchar_noderef.animation = padchar_anim_prefix + "idle"
		elif pad_vel < 0.0:
			padchar_noderef.animation = padchar_anim_prefix + "move_up"
		else:
			padchar_noderef.animation = padchar_anim_prefix + "move_down"
	else:
		# Process up/down movement inputs (or lack thereof):
		if Input.is_action_pressed(plr_prefix + "up") and not Input.is_action_pressed(plr_prefix + "down"):
			if pad_vel > 0.0: 
				pad_vel = 0.0;
			pad_vel -= PAD_MOVEACCEL * slow_effect * delta
			padchar_noderef.animation = padchar_anim_prefix + "move_up"
		elif Input.is_action_pressed(plr_prefix + "down") and not Input.is_action_pressed(plr_prefix + "up"):
			if pad_vel < 0.0: 
				pad_vel = 0.0;
			pad_vel += PAD_MOVEACCEL * slow_effect * delta
			padchar_noderef.animation = padchar_anim_prefix + "move_down"
		else:
			pad_vel *= pow(PAD_SLOWDOWN, delta * 10) # (The '* 10' is so that PAD_SLOWDOWN doesn't have to be as small.)
			if abs(pad_vel) < 0.1:
				pad_vel = 0.0
			padchar_noderef.animation = padchar_anim_prefix + "idle"
	
	# Limit paddle velocity:
	pad_vel = clampf(pad_vel, -1 * slow_effect * PAD_MAXSPEED, slow_effect * PAD_MAXSPEED,)
	
	# Move paddle by velocity, limit position, and break velocity when hitting walls:
	paddle_noderef.position.y = clamp(
		paddle_noderef.position.y + (pad_vel * delta), PAD_Y_TOPLIMIT, PAD_Y_BOTTOMLIMIT,)
	if (paddle_noderef.position.y <= PAD_Y_TOPLIMIT) and (pad_vel < 0.0):
		pad_vel = 0.0
	if (paddle_noderef.position.y >= PAD_Y_BOTTOMLIMIT) and (pad_vel > 0.0):
		pad_vel = 0.0
	
	# Update metadata for next cycle:
	paddle_noderef.set_meta("velocity", pad_vel)
	
	# Situationally override whatever expression the paddle character has with being surprised. 
	if (float(Time.get_ticks_msec() - padchar_noderef.get_meta("time_surprised")) < 
	((SURP_EXPR_VARIATION / (1.0 + (ball_velocity.x / SURP_EXPR_FALLOFF))) + SURP_EXPR_BASE)):
		padchar_noderef.animation = padchar_anim_prefix + "surprised"


const SIDEBUMP_DURATION: int = 400
const SIDEBUMP_STRENGTH_AMOUNT: float = 25.0
func handle_paddle_sidebump_animation(is_plr2: bool):
	var paddle_noderef: Node2D = (%RightPaddle if is_plr2 else %LeftPaddle)
	var time_since: int = Time.get_ticks_msec() - paddle_noderef.get_meta("sidebump_time")
	if time_since > SIDEBUMP_DURATION:
		paddle_noderef.position.x = (Globals.GAME_SIZE.x - 120) if is_plr2 else 120.0
		return
	var bump_strength: float = paddle_noderef.get_meta("sidebump_strength")
	var parabola_weight: float = parabola_arc_weight(time_since, SIDEBUMP_DURATION)
	paddle_noderef.position.x = 120 + (parabola_weight * bump_strength)
	if is_plr2: paddle_noderef.position.x = Globals.GAME_SIZE.x - paddle_noderef.position.x

func handle_paddle_knockback_anim(is_plr2: bool):
	const OOMF_LURCH_RATIO: float = 0.0035
	const KNOCKBACK_ANIM_DURATION: int = 120
	const MIN_OOMF_CUTOFF: float = 700.0
	var pad_mesh_container_ref: Node2D = (
		%RightPaddle/%MeshContainer if is_plr2 else %LeftPaddle/%MeshContainer)
	var oomf: float = pad_mesh_container_ref.get_meta("knockback_oomf")
	if abs(oomf) < MIN_OOMF_CUTOFF:
		return
	var time_since: int = Time.get_ticks_msec() - pad_mesh_container_ref.get_meta("knockback_time")
	if time_since > KNOCKBACK_ANIM_DURATION:
		pad_mesh_container_ref.position.x = 0.0
		return
	pad_mesh_container_ref.position.x = (oomf * OOMF_LURCH_RATIO * (1.0 if is_plr2 else -1.0) *
		clampf(parabola_arc_weight(time_since, KNOCKBACK_ANIM_DURATION), 0.0, 1.0))

# Used for parabolic movement arcs, such as paddle knockback and side-bumps:
func parabola_arc_weight(time_since: int, anim_time_length: int) -> float:
	return 1.0 - pow(((2.0 * (float(time_since) / float(anim_time_length))) - 1.0), 2.0)
# Used for calculating velocity imparted onto the ball during a paddle side-bump:
func parabola_arc_derivative(time_since: int, anim_time_length: int) -> float:
	return (-8.0 * ((float(time_since) / float(anim_time_length)) - 0.5)) / (float(anim_time_length) / 1000.0)

# Constants and variables associated with the ball's movement:
@onready var BALL_Y_TOPLIMIT: float = %BallShapeCast.shape.radius
@onready var BALL_Y_BOTTOMLIMIT: float = Globals.GAME_SIZE.y - %BallShapeCast.shape.radius
const BALL_MAX_BOUNCE_LOOPS: int = 100
var ball_velocity: Vector2 = Vector2(0.0, 0.0)
func handle_ball_collision_movement(delta: float):
	var ball_curr_position: Vector2 = %Ball.position
	var ball_new_position: Vector2 = Vector2()
	if ball_velocity == Vector2(0,0): return # (No need to handle movement when there's no movement.)
	var move_fraction_remaining: float = 1.0
	var safe_fraction: float = 0.0
	var shapecast_stepback_margin: float = 40.0
	var shapecast_stepback: Vector2 = Vector2()
	
	for loop: int in range(BALL_MAX_BOUNCE_LOOPS):
		# Shapecast from a margin before the ball to where the ball may move too:
		ball_new_position = ball_curr_position + (move_fraction_remaining * ball_velocity * delta)
		shapecast_stepback = (ball_new_position - ball_curr_position).normalized() * shapecast_stepback_margin
		%BallShapeCast.position = ball_curr_position - shapecast_stepback
		%BallShapeCast.target_position = (ball_new_position - ball_curr_position) + shapecast_stepback
		%BallShapeCast.force_shapecast_update()
		
		# Move the ball (either all the way or up until its first collision):
		safe_fraction = %BallShapeCast.get_closest_collision_safe_fraction()
		ball_curr_position += (move_fraction_remaining * safe_fraction * ball_velocity * delta)
		# Subtract the previous step from the remaining movement available, and update the ball trail:
		move_fraction_remaining -= move_fraction_remaining * safe_fraction
		balltrail_positions.append(ball_curr_position)
		balltrail_times.append(Time.get_ticks_msec())
		
		# Remove paddle collision exceptions for the paddle farthest from the ball.
		if ball_curr_position.x < (Globals.GAME_SIZE.x / 2.0):
			rem_add_ballshapecast_coll_exceptions(%RightPaddle/PadCollider)
			rem_add_ballshapecast_coll_exceptions(%RightPaddle/CharCollider)
		else:
			rem_add_ballshapecast_coll_exceptions(%LeftPaddle/PadCollider)
			rem_add_ballshapecast_coll_exceptions(%LeftPaddle/CharCollider)
		
		# Handle ball collisions:
		if not (ball_new_position == ball_curr_position):
			var collider: Object
			for coll_index: int in range(%BallShapeCast.get_collision_count()):
				collider = %BallShapeCast.get_collider(coll_index)
				if collider == %LeftPaddle/PadCollider: # (This would be a match statement, but it errors that the noderefs aren't const.)
					rem_add_ballshapecast_coll_exceptions(
						%RightPaddle/PadCollider, %LeftPaddle/PadCollider)
					ball_velocity = calc_paddlehit_bounce(ball_curr_position, false)
				elif collider == %LeftPaddle/CharCollider:
					ballshapecast_current_exceptions.append(%LeftPaddle/CharCollider)
					%BallShapeCast.add_exception(%LeftPaddle/CharCollider)
					rem_add_ballshapecast_coll_exceptions(
						%RightPaddle/PadCollider, %LeftPaddle/PadCollider)
					ball_velocity = calc_charthrow(ball_velocity, false)
				elif collider == %RightPaddle/PadCollider:
					rem_add_ballshapecast_coll_exceptions(
						%LeftPaddle/PadCollider, %RightPaddle/PadCollider)
					ball_velocity = calc_paddlehit_bounce(ball_curr_position, true)
				elif collider == %RightPaddle/CharCollider:
					ballshapecast_current_exceptions.append(%RightPaddle/CharCollider)
					%BallShapeCast.add_exception(%RightPaddle/CharCollider)
					rem_add_ballshapecast_coll_exceptions(
						%LeftPaddle/PadCollider, %RightPaddle/PadCollider)
					ball_velocity = calc_charthrow(ball_velocity, true)
				elif collider == %CeilingCollider:
					rem_add_ballshapecast_coll_exceptions(
						%FloorCollider, %CeilingCollider)
					ball_velocity.y = abs(ball_velocity.y)
				elif collider == %FloorCollider:
					rem_add_ballshapecast_coll_exceptions(
						%CeilingCollider, %FloorCollider)
					ball_velocity.y = -1.0 * abs(ball_velocity.y)
		
		# If the ball is done moving:
		if (move_fraction_remaining <= 0.0):
			break
		else:
			ball_curr_position = ball_new_position
	
	# Renable the floor/ceiling collisions once the ball is done moving,
	# as they may get hit mutliple times in a row due to angled paddle hits.
	rem_add_ballshapecast_coll_exceptions(%CeilingCollider)
	rem_add_ballshapecast_coll_exceptions(%FloorCollider)
	
	# Ensure that the ball can never end up beyond a wall, in case of innacurate collision:
	if ball_curr_position.y < BALL_Y_TOPLIMIT:
		ball_curr_position.y = BALL_Y_TOPLIMIT + (BALL_Y_TOPLIMIT - ball_curr_position.y)
		ball_velocity.y = abs(ball_velocity.y)
	if ball_curr_position.y > BALL_Y_BOTTOMLIMIT:
		ball_curr_position.y = BALL_Y_BOTTOMLIMIT - (ball_curr_position.y - BALL_Y_BOTTOMLIMIT)
		ball_velocity.y = -1.0 * abs(ball_velocity.y)
	
	# Ball speed reddening effect:
	#%Ball.modulate = Color.from_hsv(
		#0.014, (ball_velocity.length() / Globals.ball_max_speed) * 0.25, 1.004, 1.0)
	
	%Ball.position = ball_curr_position

var ballshapecast_current_exceptions: Array[Area2D] = []
func rem_add_ballshapecast_coll_exceptions(to_remove: Area2D, to_add: Area2D = null):
	ballshapecast_current_exceptions.erase(to_remove)
	if not to_add == null:
		ballshapecast_current_exceptions.append(to_add)
	%BallShapeCast.clear_exceptions()
	for i in range(ballshapecast_current_exceptions.size()):
		%BallShapeCast.add_exception(ballshapecast_current_exceptions[i])

func calc_paddlehit_bounce(ball_hit_pos: Vector2, is_plr2: bool) -> Vector2:
	var paddle_noderef: Node2D = (%RightPaddle if is_plr2 else %LeftPaddle)
	var padmeshcont_noderef: Node2D = (%RightPaddle/%MeshContainer if is_plr2 else %LeftPaddle/%MeshContainer)
	var padchar_noderef: AnimatedSprite2D = (%RightPaddle/%AnimChar if is_plr2 else %LeftPaddle/%AnimChar)
	# Hit region ranges from -1.0 (hit the very top of the paddle) to 1.0 (hit the very bottom):
	var paddle_hit_region: float = (
		((paddle_noderef.position.y - ball_hit_pos.y) if is_plr2 
		else (ball_hit_pos.y - paddle_noderef.position.y)) / (PAD_Y_TOPLIMIT + BALL_Y_TOPLIMIT))
	paddle_hit_region = clampf(paddle_hit_region, -1.0, 1.0)
	paddle_hit_region = pow(paddle_hit_region, 5) # (Intensify angle near edges.)
	var bounce_angle: Vector2 = (Vector2.LEFT if is_plr2 else Vector2.RIGHT).rotated(PI * 0.2625 * paddle_hit_region)
	ball_velocity = ball_velocity.bounce(bounce_angle)
	
	ball_velocity *= ((ball_velocity.length() + Globals.ball_padhit_speedup) / ball_velocity.length()) # (Speedup)
	if ball_velocity.length() > Globals.ball_max_speed:
		ball_velocity = ball_velocity.normalized() * Globals.ball_max_speed
	
	var paddle_sidebump_time_since: int = Time.get_ticks_msec() - paddle_noderef.get_meta("sidebump_time")
	if paddle_sidebump_time_since < SIDEBUMP_DURATION:
		var paddle_sidebump_strength: float = paddle_noderef.get_meta("sidebump_strength")
		var horizontal_boost: float = parabola_arc_derivative(paddle_sidebump_time_since, SIDEBUMP_DURATION) * paddle_sidebump_strength
		horizontal_boost *= (-1.0 if is_plr2 else 1.0)
		ball_velocity.x += horizontal_boost # This is intentionally added *after* the speed limit check is done.
	
	# Do paddle knockback animation, paddle character surprised expression: 
	padmeshcont_noderef.set_meta("knockback_oomf", ball_velocity.x)
	padmeshcont_noderef.set_meta("knockback_time", Time.get_ticks_msec())
	if (ball_hit_pos.x - paddle_noderef.position.x) * (1.0 if is_plr2 else -1.0) > 2.0:
		padchar_noderef.set_meta("time_surprised", Time.get_ticks_msec())
	
	if Globals.prevent_ball_backhits:
		ball_velocity.x = abs(ball_velocity.x) * (-1.0 if is_plr2 else 1.0)
	
	return ball_velocity

func calc_charthrow(init_vel: Vector2, is_plr2: bool) -> Vector2:
	(%RightPaddle/%AnimChar if is_plr2 else %LeftPaddle/%AnimChar).set_meta("time_surprised", Time.get_ticks_msec())
	return Vector2(init_vel.length() * 0.5 * (-1.0 if is_plr2 else 1.0), 0.0).rotated(
		atan(init_vel.y/init_vel.x) * 0.25 * (-1.0 if (init_vel.x < 0.0) else 1.0) * (-1.0 if is_plr2 else 1.0))

# Constants and variables associated with the ball's trail:
const BALLTRAIL_DURATION: float = 250 # (Time in ms.)
var balltrail_positions: PackedVector2Array = []
var balltrail_times: PackedInt64Array = []

func update_ball_trail():
	# Remove outdated trail data:
	var deletion_up_bound: int = -1
	for i in range(balltrail_times.size()):
		if (Time.get_ticks_msec() - balltrail_times[i]) > BALLTRAIL_DURATION:
			deletion_up_bound = i
		else:
			break
	if deletion_up_bound > -1:
		balltrail_positions = balltrail_positions.slice(deletion_up_bound + 1)
		balltrail_times = balltrail_times.slice(deletion_up_bound + 1)
	
	# Update ball-trail node's internal array.
	%BallTrail.points = balltrail_positions


func _on_resume_button_pressed():
	initiate_unpause()

func _on_quit_to_desk_button_pressed():
	get_tree().quit()
