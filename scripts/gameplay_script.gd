extends Node2D

var PADDLE_MOVEACCEL: float = 120.0
var PADDLE_MAXSPEED: float = 12.0
var PADDLE_SLOWFACTOR: float = 0.05 # (lower numbers = higher friction)
@onready var PADDLE_UP_LIMIT: float = (
	%LeftPaddleMesh.mesh.height / 2.0)
@onready var PADDLE_DOWN_LIMIT: float = (
	get_viewport().get_visible_rect().size.y - (%LeftPaddleMesh.mesh.height / 2.0))

var left_paddle_velocity: float = 0.0
var right_paddle_velocity: float = 0.0

func _process(delta: float):
	handle_left_paddle_movement(delta)
	handle_right_paddle_movement(delta)
	

func handle_left_paddle_movement(delta: float):
	if Input.is_action_pressed("plr1_up") and not Input.is_action_pressed("plr1_down"):
		if left_paddle_velocity > 0.0: 
			left_paddle_velocity = 0.0
		left_paddle_velocity -= PADDLE_MOVEACCEL * delta
	elif Input.is_action_pressed("plr1_down") and not Input.is_action_pressed("plr1_up"):
		if left_paddle_velocity < 0.0: 
			left_paddle_velocity = 0.0
		left_paddle_velocity += PADDLE_MOVEACCEL * delta
	else:
		left_paddle_velocity *= pow(PADDLE_SLOWFACTOR, delta * 10)
		if abs(left_paddle_velocity) < 0.1:
			left_paddle_velocity = 0.0
	left_paddle_velocity = clampf(left_paddle_velocity, -1 * PADDLE_MAXSPEED, PADDLE_MAXSPEED)
	
	%LeftPaddle.position.y = clamp(%LeftPaddle.position.y + left_paddle_velocity, PADDLE_UP_LIMIT, PADDLE_DOWN_LIMIT)
	if (%LeftPaddle.position.y == PADDLE_UP_LIMIT) and (left_paddle_velocity < 0.0):
		left_paddle_velocity = 0.0
	if (%LeftPaddle.position.y == PADDLE_DOWN_LIMIT) and (left_paddle_velocity > 0.0):
		left_paddle_velocity = 0.0

func handle_right_paddle_movement(delta: float):
	if Input.is_action_pressed("plr2_up") and not Input.is_action_pressed("plr2_down"):
		if right_paddle_velocity > 0.0: 
			right_paddle_velocity = 0.0
		right_paddle_velocity -= PADDLE_MOVEACCEL * delta
	elif Input.is_action_pressed("plr2_down") and not Input.is_action_pressed("plr2_up"):
		if right_paddle_velocity < 0.0: 
			right_paddle_velocity = 0.0
		right_paddle_velocity += PADDLE_MOVEACCEL * delta
	else:
		right_paddle_velocity *= pow(PADDLE_SLOWFACTOR, delta * 10)
		if abs(right_paddle_velocity) < 0.1:
			right_paddle_velocity = 0.0
	right_paddle_velocity = clampf(right_paddle_velocity, -1 * PADDLE_MAXSPEED, PADDLE_MAXSPEED)
	
	%RightPaddle.position.y = clamp(%RightPaddle.position.y + right_paddle_velocity, PADDLE_UP_LIMIT, PADDLE_DOWN_LIMIT)
	if (%RightPaddle.position.y == PADDLE_UP_LIMIT) and (right_paddle_velocity < 0.0):
		right_paddle_velocity = 0.0
	if (%RightPaddle.position.y == PADDLE_DOWN_LIMIT) and (right_paddle_velocity > 0.0):
		right_paddle_velocity = 0.0
