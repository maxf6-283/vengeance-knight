extends CharacterBody2D

@export var max_speed = 200
@export var acceleration = 1500
@export var jump_velocity = 400
@export var wall_jump_velocity_x = 300
@export var wall_jump_velocity_y = 350

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var max_fall_speed = 2000
@export var max_wall_fall_speed = 100

enum WallDirection {
	LEFT,
	RIGHT,
	NONE
}

var last_wall_direction = WallDirection.NONE

func _physics_process(delta):
	var fall_speed = max_fall_speed
	
	if is_on_wall():
		fall_speed = max_wall_fall_speed
	
	if not is_on_floor():
		velocity.y = move_toward(velocity.y, fall_speed, gravity * delta)
		

	var direction = Input.get_axis("walk_left", "walk_right")
	velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)

	if Input.is_action_just_pressed("jump"):
		$JumpBufferTimer.start() 

	if not $JumpBufferTimer.is_stopped() and not $CoyoteFrameTimer.is_stopped():
		if last_wall_direction == WallDirection.LEFT:
			velocity.x = wall_jump_velocity_x
			velocity.y = -wall_jump_velocity_y
		elif last_wall_direction == WallDirection.RIGHT:
			velocity.x = -wall_jump_velocity_x
			velocity.y = -wall_jump_velocity_y
		else:
			velocity.y = -jump_velocity
		$CoyoteFrameTimer.stop()
		$JumpBufferTimer.stop()

	move_and_slide()
	
	if is_on_floor() or is_on_wall():
		$CoyoteFrameTimer.start()

	if is_on_floor():
		last_wall_direction = WallDirection.NONE
	elif is_on_wall():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().x < 0:
				last_wall_direction = WallDirection.RIGHT
				break
			elif collision.get_normal().x > 0:
				last_wall_direction = WallDirection.LEFT
				break
		


func _on_coyote_frame_timer_timeout() -> void:
	last_wall_direction = WallDirection.NONE
