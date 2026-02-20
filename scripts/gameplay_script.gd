extends Node2D

func _ready():
	reset_gameobject_positions()
	reset_ai_inputs(false)
	reset_ai_inputs(true)

func reset_gameobject_positions():
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
	%CeilingCollisionShape.position = Vector2(Globals.GAME_SIZE.x / 2.0, - (%CeilingCollisionShape.shape.size.y / 2.0))
	%FloorCollisionShape.position = Vector2(Globals.GAME_SIZE.x / 2.0, Globals.GAME_SIZE.y + (%CeilingCollisionShape.shape.size.y / 2.0))
	
	#%LeftScoreStreak.position = 
	
	%LeftPaddle.position = Vector2(120, Globals.GAME_SIZE.y / 2.0)
	%RightPaddle.position = Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0)

# !!! (currently placeholder)
func reserve_ball():
	
	%Ball.position = Globals.GAME_SIZE / 2.0
	%Ball.set_meta("velocity", Vector2(-400, 0))
	
	balltrail_positions.clear()
	balltrail_times.clear()
	%BallTrail.points = []
	
	ballshapecast_current_exceptions.clear()
	%BallShapeCast.clear_exceptions()
	

func _process(delta: float):
	handle_paddle_ai(false, Globals.plr1_ai_mode)
	handle_paddle_ai(true, Globals.plr2_ai_mode)
	handle_paddle_controls(false, delta)
	handle_paddle_controls(true, delta)
	handle_ball_collision_movement(delta)
	update_ball_trail()
	handle_paddle_sidebump_animation(false)
	handle_paddle_sidebump_animation(true)
	handle_paddle_knockback_anim(false)
	handle_paddle_knockback_anim(true)

func handle_paddle_ai(is_plr_2: bool, ai_mode):
	var paddle_noderef: Node2D = %RightPaddle if is_plr_2 else %LeftPaddle
	var act_prefix: String = "plr2_" if is_plr_2 else "plr1_"
	var alt_act_prefix: String = "plr1_" if is_plr_2 else "plr2_"
	#input_event.action = "plr2_up"
	#input_event.pressed = true
	#Input.parse_input_event(input_event)
	
	match ai_mode:
		Globals.AI_MODES.NO_AI:
			return
		Globals.AI_MODES.COPYCAT:
			set_input(act_prefix + "up", Input.is_action_pressed(alt_act_prefix + "up"))
			set_input(act_prefix + "down", Input.is_action_pressed(alt_act_prefix + "down"))
			set_input(act_prefix + "slow", Input.is_action_pressed(alt_act_prefix + "slow"))
			set_input(act_prefix + "bump_left", Input.is_action_pressed(alt_act_prefix + "bump_right"))
			set_input(act_prefix + "bump_right", Input.is_action_pressed(alt_act_prefix + "bump_left"))
		Globals.AI_MODES.RANDOM_MASH:
			set_input(act_prefix + "up", ((randi() % 2) == 0))
			set_input(act_prefix + "down", ((randi() % 2) == 0))
			set_input(act_prefix + "slow", ((randi() % 2) == 0))
		Globals.AI_MODES.ZIGZAGGER_SLOW:
			handle_paddle_ai(is_plr_2, Globals.AI_MODES.ZIGZAGGER)
			set_input(act_prefix + "slow", true)
		Globals.AI_MODES.ZIGZAGGER:
			if paddle_noderef.get_meta("velocity") == 0.0:
				if paddle_noderef.position.y < Globals.GAME_SIZE.y / 2.0:
					set_input(act_prefix + "down", true)
					set_input(act_prefix + "up", false)
				else:
					set_input(act_prefix + "up", true)
					set_input(act_prefix + "down", false)

func reset_ai_inputs(is_plr_2: bool):
	if is_plr_2:
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

func handle_paddle_controls(is_plr_2: bool, delta: float):
	# Player-specific setup:
	var paddle_noderef: Node2D = (%RightPaddle if is_plr_2 else %LeftPaddle)
	#var paddlemesh_noderef: Node2D = (%RightPaddle/%MeshContainer if is_plr_2 else %LeftPaddle/%MeshContainer)
	var paddlemesh_bars_noderef: Node2D = (%RightPaddle/%BarsContainer if is_plr_2 else %LeftPaddle/%BarsContainer)
	var padchar_noderef: AnimatedSprite2D = (%RightPaddle/%AnimChar if is_plr_2 else %LeftPaddle/%AnimChar)
	var padchar_anim_prefix: String = "plr_" if ((Globals.plr2_ai_mode if is_plr_2 else Globals.plr1_ai_mode) == Globals.AI_MODES.NO_AI) else "bot_"
	var plr_prefix: String = ("plr2_" if is_plr_2 else "plr1_")
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
			paddle_noderef.set_meta("sidebump_strength", SIDEBUMP_STRENGTH_AMOUNT * (-1.0 if is_plr_2 else 1.0))
		elif Input.is_action_pressed(plr_prefix + "bump_left"):
			paddle_noderef.set_meta("sidebump_time", Time.get_ticks_msec())
			paddle_noderef.set_meta("sidebump_strength", -1.0 * SIDEBUMP_STRENGTH_AMOUNT * (-1.0 if is_plr_2 else 1.0))
	
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
	((SURP_EXPR_VARIATION / (1.0 + (%Ball.get_meta("velocity").length() / SURP_EXPR_FALLOFF))) + SURP_EXPR_BASE)):
		padchar_noderef.animation = padchar_anim_prefix + "surprised"


const SIDEBUMP_DURATION: int = 400
const SIDEBUMP_STRENGTH_AMOUNT: float = 25.0

func handle_paddle_sidebump_animation(is_plr_2: bool):
	var paddle_noderef: Node2D = (%RightPaddle if is_plr_2 else %LeftPaddle)
	
	var time_since: int = Time.get_ticks_msec() - paddle_noderef.get_meta("sidebump_time")
	if time_since > SIDEBUMP_DURATION:
		paddle_noderef.position.x = (Globals.GAME_SIZE.x - 120) if is_plr_2 else 120.0
		return
	var bump_strength: float = paddle_noderef.get_meta("sidebump_strength")
	
	var parabola_weight: float = get_parabola_animation_weight(time_since, SIDEBUMP_DURATION)
	paddle_noderef.position.x = 120 + (parabola_weight * bump_strength)
	if is_plr_2: paddle_noderef.position.x = Globals.GAME_SIZE.x - paddle_noderef.position.x

func handle_paddle_knockback_anim(is_plr_2: bool):
	const OOMF_LURCH_RATIO: float = 0.0035
	const KNOCKBACK_ANIM_DURATION: int = 120
	const MIN_OOMF_CUTOFF: float = 700.0
	
	var pad_mesh_container_ref: Node2D = (%RightPaddle/%MeshContainer if is_plr_2 else %LeftPaddle/%MeshContainer)
	
	var oomf: float = pad_mesh_container_ref.get_meta("knockback_oomf")
	if abs(oomf) < MIN_OOMF_CUTOFF:
		return
	var time_since: int = Time.get_ticks_msec() - pad_mesh_container_ref.get_meta("knockback_time")
	if time_since > KNOCKBACK_ANIM_DURATION:
		pad_mesh_container_ref.position.x = 0.0
		return
	
	pad_mesh_container_ref.position.x = (-1.0 * oomf * OOMF_LURCH_RATIO *
		clampf(get_parabola_animation_weight(time_since, KNOCKBACK_ANIM_DURATION), 0.0, 1.0))

func get_parabola_animation_weight(time_since: int, anim_time_length: int) -> float:
	return 1.0 - pow(((2.0 * (float(time_since) / float(anim_time_length))) - 1.0), 2.0)

func get_parabola_animation_weight_derivative(time_since: int, anim_time_length: int) -> float:
	return (-8.0 * ((float(time_since) / float(anim_time_length)) - 0.5)) / (float(anim_time_length) / 1000.0)

# Constants associated with the ball's movement:
@onready var BALL_Y_TOPLIMIT: float = %BallShapeCast.shape.radius
@onready var BALL_Y_BOTTOMLIMIT: float = Globals.GAME_SIZE.y - %BallShapeCast.shape.radius
const BALL_PADHIT_SPEEDUP: float = 35
const BALL_MAX_SPEED: float = 4000
const BALL_MAX_BOUNCE_LOOPS: int = 100

func handle_ball_collision_movement(delta: float):
	var ball_curr_position: Vector2 = %Ball.position
	var ball_new_position: Vector2 = Vector2()
	var ball_velocity: Vector2 = %Ball.get_meta("velocity")
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
		
		# Handle ball collisions:
		if (ball_new_position == ball_curr_position):
			if ball_velocity.x < 0.0:
				rem_add_ballshapecast_coll_exceptions(%LeftPaddle/AreaCollider)
			elif ball_velocity.x > 0.0:
				rem_add_ballshapecast_coll_exceptions(%RightPaddle/AreaCollider)
		else:
			var collider: Object
			for coll_index: int in range(%BallShapeCast.get_collision_count()):
				collider = %BallShapeCast.get_collider(coll_index)
				if collider == %LeftPaddle/AreaCollider:
					rem_add_ballshapecast_coll_exceptions(
						%RightPaddle/AreaCollider, %LeftPaddle/AreaCollider)
					ball_velocity = calc_paddlehit_bounce(ball_curr_position, ball_velocity, false)
				elif collider == %RightPaddle/AreaCollider:
					rem_add_ballshapecast_coll_exceptions(
						%LeftPaddle/AreaCollider, %RightPaddle/AreaCollider)
					ball_velocity = calc_paddlehit_bounce(ball_curr_position, ball_velocity, true)
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
	
	# Re-serve the ball if it goes out-of-bounds, else update its data.
	if abs(ball_curr_position.x - (Globals.GAME_SIZE.x / 2.0)) > ((Globals.GAME_SIZE.x / 2.0) + 20):
		reserve_ball()
	else:
		%Ball.position = ball_curr_position
		%Ball.set_meta("velocity", ball_velocity)

var ballshapecast_current_exceptions: Array[Area2D] = []
func rem_add_ballshapecast_coll_exceptions(to_remove: Area2D, to_add: Area2D = null):
	ballshapecast_current_exceptions.erase(to_remove)
	if not to_add == null:
		ballshapecast_current_exceptions.append(to_add)
	%BallShapeCast.clear_exceptions()
	for i in range(ballshapecast_current_exceptions.size()):
		%BallShapeCast.add_exception(ballshapecast_current_exceptions[i])

func calc_paddlehit_bounce(ball_hit_pos: Vector2, ball_velocity: Vector2, is_plr_2: bool) -> Vector2:
	var paddle_noderef: Node2D = (%RightPaddle if is_plr_2 else %LeftPaddle)
	var padmeshcont_noderef: Node2D = (%RightPaddle/%MeshContainer if is_plr_2 else %LeftPaddle/%MeshContainer)
	var padchar_noderef: AnimatedSprite2D = (%RightPaddle/%AnimChar if is_plr_2 else %LeftPaddle/%AnimChar)
	# Hit region ranges from -1.0 (hit the very top of the paddle) to 1.0 (hit the very bottom):
	var paddle_hit_region: float = ((paddle_noderef.position.y - ball_hit_pos.y) if is_plr_2 else (ball_hit_pos.y - paddle_noderef.position.y)) / (PAD_Y_TOPLIMIT + BALL_Y_TOPLIMIT)
	paddle_hit_region = pow(paddle_hit_region, 5) # (Intensify angle near edges.)
	var bounce_angle: Vector2 = (Vector2.LEFT if is_plr_2 else Vector2.RIGHT).rotated(PI * 0.2625 * paddle_hit_region)
	ball_velocity = ball_velocity.bounce(bounce_angle)
	
	ball_velocity *= ((ball_velocity.length() + BALL_PADHIT_SPEEDUP) / ball_velocity.length()) # (Speedup)
	if ball_velocity.length() > BALL_MAX_SPEED:
		ball_velocity = ball_velocity.normalized() * BALL_MAX_SPEED
	
	var paddle_sidebump_time_since: int = Time.get_ticks_msec() - paddle_noderef.get_meta("sidebump_time")
	if paddle_sidebump_time_since < SIDEBUMP_DURATION:
		var paddle_sidebump_strength: float = paddle_noderef.get_meta("sidebump_strength")
		var horizontal_boost: float = get_parabola_animation_weight_derivative(paddle_sidebump_time_since, SIDEBUMP_DURATION) * paddle_sidebump_strength
		horizontal_boost *= (-1.0 if is_plr_2 else 1.0)
		ball_velocity.x += horizontal_boost # This is intentionally added *after* the speed limit check is done.
	
	# Do paddle knockback animation, paddle character surprised expression: 
	padmeshcont_noderef.set_meta("knockback_oomf", ball_velocity.x)
	padmeshcont_noderef.set_meta("knockback_time", Time.get_ticks_msec())
	if (ball_hit_pos.x - paddle_noderef.position.x) * (1.0 if is_plr_2 else -1.0) > 2.0:
		padchar_noderef.set_meta("time_surprised", Time.get_ticks_msec())
	
	return ball_velocity

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
