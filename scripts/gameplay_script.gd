extends Node2D



func _ready():
	reset_gameobject_positions()

func reset_gameobject_positions():
	
	%BackgroundColorRect.custom_minimum_size = Globals.GAME_SIZE
	
	%Centerline1.position = Globals.GAME_SIZE / 2.0
	%Centerline1.mesh.size.y = Globals.GAME_SIZE.y
	%Centerline2.mesh.size.y = Globals.GAME_SIZE.y
	%Centerline3.mesh.size.y = Globals.GAME_SIZE.y
	%Centerline4.mesh.size.y = Globals.GAME_SIZE.y
	
	%LeftRailOuter.position = Vector2(120, Globals.GAME_SIZE.y / 2.0)
	%RightRailOuter.position = Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0)
	%LeftRailOuter.mesh.height = Globals.GAME_SIZE.y - 25
	%LeftRailInner.mesh.height = Globals.GAME_SIZE.y - 35
	
	%LeftPaddle.position = Vector2(120, Globals.GAME_SIZE.y / 2.0)
	%RightPaddle.position = Vector2(Globals.GAME_SIZE.x - 120, Globals.GAME_SIZE.y / 2.0)

# Constants associated with paddle movement:
const PAD_MOVEACCEL: float = 14400.0
const PAD_MAXSPEED: float = 1250.0
const PAD_SLOWDOWN: float = 0.05 # Note: Values closer to 0 correlate with higher friction.
@onready var PAD_Y_TOPLIMIT: float = %LeftPaddle/%FrontBar.mesh.height / 2.0
@onready var PAD_Y_BOTTOMLIMIT: float = Globals.GAME_SIZE.y - (%LeftPaddle/%FrontBar.mesh.height / 2.0)


const BALLMESH_DIAMETER: float = 14
@onready var BALL_UP_LIMIT: float = BALLMESH_DIAMETER / 2.0
@onready var BALL_DOWN_LIMIT: float = Globals.GAME_SIZE.y - (BALLMESH_DIAMETER / 2.0)

var ball_speedup_amount: float = 50

var ball_velocity: Vector2 = Vector2(-4 * 120, 0 * 120)
const BALL_MAX_SPEED: float = 2500

var ball_trail_ms_duration: float = 250
var ball_trail_positions: PackedVector2Array = []
var ball_trail_times: PackedInt64Array = []

func _process(delta: float):
	
	# Temporary knockback testing
	if Input.is_action_just_pressed("plr1_bump_left"):
		%LeftPaddle/%MeshContainer.set_meta("knockback_oomf", 2000.0)
		%LeftPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
	if Input.is_action_just_pressed("plr2_bump_right"):
		%RightPaddle/%MeshContainer.set_meta("knockback_oomf", 2000.0)
		%RightPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
	
	check_do_player_ai()
	handle_paddle_movement(true, delta)
	handle_paddle_movement(false, delta)
	handle_ball_movement(delta)
	handle_ball_trail()
	handle_paddle_knockback_animation(true)
	handle_paddle_knockback_animation(false)

func check_do_player_ai():
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

func handle_paddle_movement(is_plr1: bool, delta: float):
	# Player-specific setup:
	var paddle_noderef: Node2D = (%LeftPaddle if is_plr1 else %RightPaddle)
	#var paddlemesh_noderef: Node2D = (%LeftPaddle/%MeshContainer if is_plr1 else %RightPaddle/%MeshContainer)
	var paddlemesh_bars_noderef: MeshInstance2D = (%LeftPaddle/%FrontBar if is_plr1 else %RightPaddle/%FrontBar)
	var padchar_noderef: AnimatedSprite2D = (%LeftPaddle/%AnimChar if is_plr1 else %RightPaddle/%AnimChar)
	var plr_prefix: String = ("plr1_" if is_plr1 else "plr2_")
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
		pad_vel *= pow(PAD_SLOWDOWN, delta * 10)
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

func handle_ball_movement(delta: float):
	%Ball.position += ball_velocity * delta
	if %Ball.position.y < BALL_UP_LIMIT:
		%Ball.position.y = BALL_UP_LIMIT + (BALL_UP_LIMIT - %Ball.position.y)
		ball_velocity.y = maxf(ball_velocity.y, ball_velocity.y * -1.0)
	elif %Ball.position.y > BALL_DOWN_LIMIT:
		%Ball.position.y = BALL_DOWN_LIMIT - (%Ball.position.y - BALL_DOWN_LIMIT)
		ball_velocity.y = minf(ball_velocity.y, ball_velocity.y * -1.0)
	
	if ((%Ball.position.x < (-1.0 * BALL_UP_LIMIT)) or 
	(%Ball.position.x > (Globals.GAME_SIZE.x + BALL_UP_LIMIT))):
		%Ball.position = Globals.GAME_SIZE / 2.0

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
	%BallTrail.points = ball_trail_positions

func handle_paddle_knockback_animation(is_plr1: bool):
	# < 450 is no time, 2000+ is max at ~400ms?
	const MIN_OOMF: float = 0
	const MAX_OOMF: float = BALL_MAX_SPEED
	#const MIN_ANIM_LENGTH: int = 0
	#const MAX_ANIM_LENGTH: int = 200 #100
	const OOMF_LURCH_RATIO: float = 0.0025 #0.005
	
	var mesh_noderef: Node2D = (%LeftPaddle/%MeshContainer if is_plr1 else %RightPaddle/%MeshContainer)
	
	var oomf: float = min(mesh_noderef.get_meta("knockback_oomf"), MAX_OOMF)
	var start_time: int = mesh_noderef.get_meta("knockback_time")
	var time_since: int = Time.get_ticks_msec() - start_time
	#if (oomf < MIN_OOMF) or (time_since > MAX_ANIM_LENGTH):
	if (oomf < MIN_OOMF) or (time_since > 100):
		mesh_noderef.position.x = 0.0
		return
	
	#var anim_duration: int = int(((oomf - MIN_OOMF) / (MAX_OOMF - MIN_OOMF)) * float(MAX_ANIM_LENGTH))
	var anim_duration: int = 100
	#if (time_since > anim_duration) or (anim_duration < MIN_ANIM_LENGTH):
	if (time_since > anim_duration) or (anim_duration < 100):
		mesh_noderef.position.x = 0.0
		return
	var anim_progress_percent: float = (float(time_since) / float(anim_duration))
	
	var anim_weight: float = 1 - pow(((2 * anim_progress_percent) - 1), 2)
	#var anim_weight: float = pow(anim_progress_percent * (4 - (4 * anim_progress_percent)), 0.5)
	#var anim_weight: float = 3.07920197588 * pow(1 - anim_progress_percent, 1.5) * pow(anim_progress_percent, 0.5)
	
	mesh_noderef.position.x = anim_weight * oomf * OOMF_LURCH_RATIO * -1.0


func _on_left_paddle_collider_area_entered(_area):
	if ball_velocity.x < 0.0:
		%LeftPaddle/%MeshContainer.set_meta("knockback_oomf", abs(ball_velocity.x))
		%LeftPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
		var pad_hit_offset: float = pow((%Ball.position.y - %LeftPaddle.position.y) / (((%LeftPaddle/%FrontBar.mesh.height + 5) / 2.0)), 5)
		var angle: Vector2 = Vector2.RIGHT.rotated(PI * pad_hit_offset * 0.25)
		ball_velocity = ball_velocity.bounce(angle)
		ball_velocity *= ((ball_velocity.length() + ball_speedup_amount) / ball_velocity.length())
		if ball_velocity.length() > BALL_MAX_SPEED:
			ball_velocity = ball_velocity.normalized() * BALL_MAX_SPEED

func _on_right_paddle_collider_area_entered(_area):
	if ball_velocity.x > 0.0:
		%RightPaddle/%MeshContainer.set_meta("knockback_oomf", abs(ball_velocity.x))
		%RightPaddle/%MeshContainer.set_meta("knockback_time", Time.get_ticks_msec())
		var pad_hit_offset: float = pow((%RightPaddle.position.y - %Ball.position.y) / (((%RightPaddle/%FrontBar.mesh.height + 5) / 2.0)), 5)
		var angle: Vector2 = Vector2.LEFT.rotated(PI * pad_hit_offset * 0.25)
		ball_velocity = ball_velocity.bounce(angle)
		ball_velocity *= ((ball_velocity.length() + ball_speedup_amount) / ball_velocity.length())
		if ball_velocity.length() > BALL_MAX_SPEED:
			ball_velocity = ball_velocity.normalized() * BALL_MAX_SPEED

#func process_ball_paddle_hit(is_plr1: bool):
	
