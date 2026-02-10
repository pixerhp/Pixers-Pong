extends Node2D

const BALLMESH_DIAMETER: float = 14

var PADDLE_MOVEACCEL: float = 14400.0
var PADDLE_MAXSPEED: float = 1440.0
var PADDLE_SLOWFACTOR: float = 0.05 # (lower numbers = higher friction)
@onready var PADDLE_UP_LIMIT: float = (
	%LeftPaddleMesh.mesh.height / 2.0)
@onready var PADDLE_DOWN_LIMIT: float = (
	Globals.PLAY_AREA_DIMENSIONS.y - (%LeftPaddleMesh.mesh.height / 2.0))
@onready var BALL_UP_LIMIT: float = (
	BALLMESH_DIAMETER / 2.0)
@onready var BALL_DOWN_LIMIT: float = (
	Globals.PLAY_AREA_DIMENSIONS.y - (BALLMESH_DIAMETER / 2.0))

var ball_speedup_amount: float = 50

var ball_velocity: Vector2 = Vector2(-2 * 120, 0.5 * 120)

var ball_trail_ms_duration: float = 250
var ball_trail_positions: PackedVector2Array = []
var ball_trail_times: PackedInt64Array = []

func _process(delta: float):
	check_do_player_ai()
	handle_paddle_movement(true, delta)
	handle_paddle_movement(false, delta)
	handle_ball_movement(delta)
	handle_ball_trail()

func check_do_player_ai():
	#var test_event = InputEventAction.new()
	#test_event.action = "plr2_up"
	#test_event.pressed = true
	#Input.parse_input_event(test_event)
	
	match Globals.plr1_ai_mode:
		Globals.AI_MODES.OFF:
			pass
		Globals.AI_MODES.LVL1:
			pass
		Globals.AI_MODES.LVL2:
			pass
		Globals.AI_MODES.LVL3:
			pass
	
	match Globals.plr2_ai_mode:
		Globals.AI_MODES.OFF:
			pass
		Globals.AI_MODES.LVL1:
			pass
		Globals.AI_MODES.LVL2:
			pass
		Globals.AI_MODES.LVL3:
			pass

func handle_paddle_movement(is_plr1: bool, delta: float):
	# Player-specific setup:
	var paddle_noderef: Node2D = (%LeftPaddle if is_plr1 else %RightPaddle)
	var padchar_noderef: AnimatedSprite2D = (%LeftPaddleChar if is_plr1 else %RightPaddleChar)
	var plr_prefix: String = ("plr1_" if is_plr1 else "plr2_")
	# General setup:
	var slow_effect: float = (0.25 if Input.is_action_pressed(plr_prefix + "slow") else 1.0)
	var pad_vel: float = paddle_noderef.get_meta("velocity")
	
	# Process up/down movement inputs (or lack thereof):
	if Input.is_action_pressed(plr_prefix + "up") and not Input.is_action_pressed(plr_prefix + "down"):
		padchar_noderef.animation = "plr_move_up"
		if pad_vel > 0.0: 
			pad_vel = 0.0;
		pad_vel -= PADDLE_MOVEACCEL * slow_effect * delta
	elif Input.is_action_pressed(plr_prefix + "down") and not Input.is_action_pressed(plr_prefix + "up"):
		padchar_noderef.animation = "plr_move_down"
		if pad_vel < 0.0: 
			pad_vel = 0.0;
		pad_vel += PADDLE_MOVEACCEL * slow_effect * delta
	else:
		padchar_noderef.animation = "plr_idle"
		pad_vel *= pow(PADDLE_SLOWFACTOR, delta * 10)
		if abs(pad_vel) < 0.1:
			pad_vel = 0.0
	
	# Limit paddle velocity:
	pad_vel = clampf(pad_vel, -1 * slow_effect * PADDLE_MAXSPEED, slow_effect * PADDLE_MAXSPEED,)
	
	# Move paddle by velocity and limit position:
	paddle_noderef.position.y = clamp(
		paddle_noderef.position.y + (pad_vel * delta), PADDLE_UP_LIMIT, PADDLE_DOWN_LIMIT,)
	if (paddle_noderef.position.y == PADDLE_UP_LIMIT) and (pad_vel < 0.0):
		pad_vel = 0.0
	if (paddle_noderef.position.y == PADDLE_DOWN_LIMIT) and (pad_vel > 0.0):
		pad_vel = 0.0
	
	# Update metadata for next cycle:
	paddle_noderef.set_meta("velocity", pad_vel)

func handle_ball_movement(delta: float):
	%Ball.position += ball_velocity * delta
	if %Ball.position.y < BALL_UP_LIMIT:
		%Ball.position.y = BALL_UP_LIMIT + (BALL_UP_LIMIT - %Ball.position.y)
		ball_velocity.y = maxf(ball_velocity.y, ball_velocity.y * -1.0)
	elif %Ball.position.y > BALL_DOWN_LIMIT:
		%Ball.position.y = BALL_DOWN_LIMIT - (%Ball.position.y - BALL_DOWN_LIMIT)
		ball_velocity.y = minf(ball_velocity.y, ball_velocity.y * -1.0)
	
	if ((%Ball.position.x < (-1.0 * BALL_UP_LIMIT)) or 
	(%Ball.position.x > (Globals.PLAY_AREA_DIMENSIONS.x + BALL_UP_LIMIT))):
		%Ball.position = Globals.PLAY_AREA_DIMENSIONS / 2.0

func handle_ball_trail():
	# Remove outdated trail data:
	var deletion_up_bound: int = -1
	for i in range(ball_trail_times.size()):
		if (Time.get_ticks_msec() - ball_trail_times[i]) > ball_trail_ms_duration:
			deletion_up_bound = i
		else:
			break
	if deletion_up_bound > -1:
		ball_trail_positions = ball_trail_positions.slice(deletion_up_bound + 1)
		ball_trail_times = ball_trail_times.slice(deletion_up_bound + 1)
	
	# Add new trail data:
	ball_trail_positions.append(%Ball.position)
	ball_trail_times.append(Time.get_ticks_msec())
	
	# Update trail Line2D node's internal array.
	%BallTrailLine.points = ball_trail_positions



func _on_left_paddle_collider_area_entered(_area):
	if ball_velocity.x < 0.0:
		var pad_hit_offset: float = pow((%Ball.position.y - %LeftPaddle.position.y) / (((%LeftPaddleMesh.mesh.height + 5) / 2.0)), 5)
		var angle: Vector2 = Vector2.RIGHT.rotated(PI * pad_hit_offset * 0.25)
		ball_velocity = ball_velocity.bounce(angle)
		ball_velocity *= ((ball_velocity.length() + ball_speedup_amount) / ball_velocity.length())

func _on_right_paddle_collider_area_entered(_area):
	if ball_velocity.x > 0.0:
		var pad_hit_offset: float = pow((%RightPaddle.position.y - %Ball.position.y) / (((%RightPaddleMesh.mesh.height + 5) / 2.0)), 5)
		var angle: Vector2 = Vector2.LEFT.rotated(PI * pad_hit_offset * 0.25)
		ball_velocity = ball_velocity.bounce(angle)
		ball_velocity *= ((ball_velocity.length() + ball_speedup_amount) / ball_velocity.length())
