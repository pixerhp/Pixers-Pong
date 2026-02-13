extends Node2D

func _ready():
	reset_gameobject_positions()

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
	
	%LeftPaddle.position = Vector2(120, Globals.GAME_SIZE.y / 2.0)
	%RightPaddle.position = Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0)

func _process(delta: float):
	# !!! Temporary knockback testing
	if Input.is_action_just_pressed("plr1_bump_left"):
		%LeftPaddle/%MeshContainer.set_meta("knockback_oomf", 2000.0)
		%LeftPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
	if Input.is_action_just_pressed("plr2_bump_right"):
		%RightPaddle/%MeshContainer.set_meta("knockback_oomf", 2000.0)
		%RightPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
	
	check_do_paddle_ai()
	handle_paddle_controls(false, delta)
	handle_paddle_controls(true, delta)
	handle_ball_movement_and_trail(delta)
	#handle_ball_trail()
	handle_paddle_knockback_anim(false)
	handle_paddle_knockback_anim(true)

func check_do_paddle_ai():
	#var test_event = InputEventAction.new()
	#test_event.action = "plr2_up"
	#test_event.pressed = true
	#Input.parse_input_event(test_event)
	
	match Globals.plr1_ai_mode:
		Globals.AI_MODES.NO_AI:
			pass
	
	match Globals.plr2_ai_mode:
		Globals.AI_MODES.NO_AI:
			pass

# Constants associated with paddle movement:
const PAD_MOVEACCEL: float = 14400.0
const PAD_MAXSPEED: float = 1250.0
const PAD_SLOWDOWN: float = 0.05 # Note: Values closer to 0 correlate with higher friction.
@onready var PAD_Y_TOPLIMIT: float = %LeftPaddle/%FrontBar.mesh.height / 2.0
@onready var PAD_Y_BOTTOMLIMIT: float = Globals.GAME_SIZE.y - (%LeftPaddle/%FrontBar.mesh.height / 2.0)

func handle_paddle_controls(on_right: bool, delta: float):
	# Player-specific setup:
	var paddle_noderef: Node2D = (%RightPaddle if on_right else %LeftPaddle)
	#var paddlemesh_noderef: Node2D = (%RightPaddle/%MeshContainer if on_right else %LeftPaddle/%MeshContainer)
	var paddlemesh_bars_noderef: Node2D = (%RightPaddle/%BarsContainer if on_right else %LeftPaddle/%BarsContainer)
	var padchar_noderef: AnimatedSprite2D = (%RightPaddle/%AnimChar if on_right else %LeftPaddle/%AnimChar)
	var plr_prefix: String = ("plr2_" if on_right else "plr1_")
	# General setup:
	var pad_vel: float = paddle_noderef.get_meta("velocity")
	var slow_effect: float = (0.3 if Input.is_action_pressed(plr_prefix + "slow") else 1.0)
	if slow_effect == 1.0:
		paddlemesh_bars_noderef.modulate = Color.WHITE
	else:
		paddlemesh_bars_noderef.modulate = Color.LIGHT_GRAY
	
	# Process up/down movement inputs (or lack thereof):
	if Input.is_action_pressed(plr_prefix + "up") and not Input.is_action_pressed(plr_prefix + "down"):
		padchar_noderef.animation = "plr_move_up"
		if pad_vel > 0.0: 
			pad_vel = 0.0;
		pad_vel -= PAD_MOVEACCEL * slow_effect * delta
	elif Input.is_action_pressed(plr_prefix + "down") and not Input.is_action_pressed(plr_prefix + "up"):
		padchar_noderef.animation = "plr_move_down"
		if pad_vel < 0.0: 
			pad_vel = 0.0;
		pad_vel += PAD_MOVEACCEL * slow_effect * delta
	else:
		padchar_noderef.animation = "plr_idle"
		pad_vel *= pow(PAD_SLOWDOWN, delta * 10) # (The '* 10' is so that PAD_SLOWDOWN doesn't have to be as small.)
		if abs(pad_vel) < 0.1:
			pad_vel = 0.0
	
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

func handle_paddle_knockback_anim(on_right: bool):
	const OOMF_LURCH_RATIO: float = 0.0035
	const KNOCKBACK_ANIM_DURATION: int = 120
	
	var pad_mesh_container_ref: Node2D = (%RightPaddle/%MeshContainer if on_right else %LeftPaddle/%MeshContainer)
	
	var oomf: float = pad_mesh_container_ref.get_meta("knockback_oomf")
	var time_since: int = Time.get_ticks_msec() - pad_mesh_container_ref.get_meta("knockback_time")
	if time_since > KNOCKBACK_ANIM_DURATION:
		pad_mesh_container_ref.position.x = 0.0
		return
	
	pad_mesh_container_ref.position.x = (-1.0 * oomf * OOMF_LURCH_RATIO *
		clampf(get_parabola_animation_weight(time_since, KNOCKBACK_ANIM_DURATION), 0.0, 1.0))

func get_parabola_animation_weight(time_since: int, anim_time_length: int) -> float:
	return 1.0 - pow(((2.0 * ((float(time_since) / float(anim_time_length)))) - 1.0), 2.0)


# Constants associated with the ball's movement:
@onready var BALL_Y_TOPLIMIT: float = %BallShapeCast.shape.radius
@onready var BALL_Y_BOTTOMLIMIT: float = Globals.GAME_SIZE.y - %BallShapeCast.shape.radius
const BALL_PADHIT_SPEEDUP: float = 50
const BALL_MAX_SPEED: float = 2500
const BALL_MAX_BOUNCE_LOOPS: int = 100
# Constants and variables associated with the ball's trail:
const BALLTRAIL_DURATION: float = 250
var balltrail_positions: PackedVector2Array = []
var balltrail_times: PackedInt64Array = []

func handle_ball_movement_and_trail(delta: float):
	var ball_curr_position: Vector2 = Vector2()
	var ball_new_position: Vector2 = %Ball.position
	var ball_velocity: Vector2 = %Ball.get_meta("velocity")
	if ball_velocity == Vector2(0,0):
		return
	var move_fraction_remaining: float = 1.0
	var safe_fraction: float = 0.0
	var unsafe_fraction: float = 0.0
	
	var left_paddle_collider: Area2D = %LeftPaddle/AreaCollider
	var right_paddle_collider: Area2D = %RightPaddle/AreaCollider
	
	for loop: int in range(BALL_MAX_BOUNCE_LOOPS):
		ball_curr_position = ball_new_position
		
		# Shapecast from where the ball is to the full length of where it wants to go:
		%BallShapeCast.position = ball_curr_position
		ball_new_position = ball_curr_position + (move_fraction_remaining * ball_velocity * delta)
		%BallShapeCast.target_position = ball_new_position - ball_curr_position
		%BallShapeCast.force_shapecast_update()
		# Get how far the ball can go before colliding:
		safe_fraction = %BallShapeCast.get_closest_collision_safe_fraction()
		unsafe_fraction = %BallShapeCast.get_closest_collision_unsafe_fraction()
		# Move the ball to just before its first collision, and make its new position be just after:
		ball_new_position = ball_curr_position + (unsafe_fraction * move_fraction_remaining * ball_velocity * delta)
		ball_curr_position = ball_curr_position + (move_fraction_remaining * safe_fraction * ball_velocity * delta)
		# Subtract from the movement fraction remaining, and add to the ball trail:
		move_fraction_remaining -= move_fraction_remaining * safe_fraction
		balltrail_positions.append(ball_curr_position)
		balltrail_times.append(Time.get_ticks_msec())
		
		# If the ball couldn't go all the way it wanted to:
		if not (ball_new_position == ball_curr_position):
			# Shapecast the small distance between where it is and a step further into collision:
			%BallShapeCast.position = ball_curr_position
			%BallShapeCast.target_position = ball_new_position - ball_curr_position
			%BallShapeCast.force_shapecast_update()
			# Change the ball's velocity based on its collisions:
			for coll_index: int in range(%BallShapeCast.get_collision_count()):
				match %BallShapeCast.get_collider(coll_index):
					left_paddle_collider:
						ball_velocity.x = abs(ball_velocity.x)
					right_paddle_collider:
						ball_velocity.x = -1.0 * abs(ball_velocity.x)
		
		if (move_fraction_remaining <= 0.0):
			break
	
	# !!! temporary teleport to center if ball goes too far to the left/right:
	if abs(ball_curr_position.x - (Globals.GAME_SIZE.x / 2.0)) > ((Globals.GAME_SIZE.x / 2.0) + 20):
		ball_curr_position = Globals.GAME_SIZE / 2.0
	
	%Ball.position = ball_curr_position
	%Ball.set_meta("velocity", ball_velocity)

func handle_ball_movement(delta: float):
	var ball_velocity: Vector2 = %Ball.get_meta("velocity")
	
	%Ball.position += ball_velocity * delta
	if %Ball.position.y < BALL_Y_TOPLIMIT:
		%Ball.position.y = BALL_Y_TOPLIMIT + (BALL_Y_TOPLIMIT - %Ball.position.y)
		ball_velocity.y = maxf(ball_velocity.y, ball_velocity.y * -1.0)
	elif %Ball.position.y > BALL_Y_BOTTOMLIMIT:
		%Ball.position.y = BALL_Y_BOTTOMLIMIT - (%Ball.position.y - BALL_Y_BOTTOMLIMIT)
		ball_velocity.y = minf(ball_velocity.y, ball_velocity.y * -1.0)
	
	if ((%Ball.position.x < (-1.0 * BALL_Y_TOPLIMIT)) or 
	(%Ball.position.x > (Globals.GAME_SIZE.x + BALL_Y_TOPLIMIT))):
		%Ball.position = Globals.GAME_SIZE / 2.0
	
	%Ball.set_meta("velocity", ball_velocity)

func handle_ball_trail():
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
	
	# Add new trail data:
	balltrail_positions.append(%Ball.position)
	balltrail_times.append(Time.get_ticks_msec())
	
	# Update trail Line2D node's internal array.
	%BallTrail.points = balltrail_positions


func _on_left_paddle_collider_area_entered(_area):
	pass
	#if ball_velocity.x < 0.0:
		#%LeftPaddle/%MeshContainer.set_meta("knockback_oomf", abs(ball_velocity.x))
		#%LeftPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
		#var pad_hit_offset: float = pow((%Ball.position.y - %LeftPaddle.position.y) / (((%LeftPaddle/%FrontBar.mesh.height + 5) / 2.0)), 5)
		#var angle: Vector2 = Vector2.RIGHT.rotated(PI * pad_hit_offset * 0.25)
		#ball_velocity = ball_velocity.bounce(angle)
		#ball_velocity *= ((ball_velocity.length() + BALL_PADHIT_SPEEDUP) / ball_velocity.length())
		#if ball_velocity.length() > BALL_MAX_SPEED:
			#ball_velocity = ball_velocity.normalized() * BALL_MAX_SPEED

func _on_right_paddle_collider_area_entered(_area):
	pass
	#if ball_velocity.x > 0.0:
		#%RightPaddle/%MeshContainer.set_meta("knockback_oomf", abs(ball_velocity.x))
		#%RightPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
		#var pad_hit_offset: float = pow((%RightPaddle.position.y - %Ball.position.y) / (((%RightPaddle/%FrontBar.mesh.height + 5) / 2.0)), 5)
		#var angle: Vector2 = Vector2.LEFT.rotated(PI * pad_hit_offset * 0.25)
		#ball_velocity = ball_velocity.bounce(angle)
		#ball_velocity *= ((ball_velocity.length() + BALL_PADHIT_SPEEDUP) / ball_velocity.length())
		#if ball_velocity.length() > BALL_MAX_SPEED:
			#ball_velocity = ball_velocity.normalized() * BALL_MAX_SPEED

#func process_ball_paddle_hit(is_plr1: bool):
	
