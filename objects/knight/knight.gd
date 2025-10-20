extends CharacterBody2D

@export var max_speed = 200
@export var acceleration = 1500
@export var jump_velocity = 400
@export var wall_jump_velocity_x = 300
@export var wall_jump_velocity_y = 350

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed = 2000
@export var max_wall_fall_speed = 100

@export var roll_start_speed = 600
@export var roll_end_speed = 350
@export var roll_time = 0.15 #s

var respawn_location: Vector2 = Vector2(0, 0)

enum FacingDirection {
	LEFT = -1,
	RIGHT = 1,
	NONE = 0
}

@export var facing = FacingDirection.RIGHT:
	set(new_val):
		facing = new_val
		if facing:
			$KnightSprite.scale.x = abs($KnightSprite.scale.x) * facing

var rolling = false
var roll_speed = 0.0

var last_wall_direction = FacingDirection.NONE

var on_ladder = false

func start_roll(direction: int):
	rolling = true
	velocity.y = 0
	$RollHitBox.disabled = false
	$HitBox.disabled = true
	$HurtBox/RollHurtbox.disabled = false
	$HurtBox/BaseHurtbox.disabled = true
	var roll_tween = create_tween()
	roll_tween.tween_property(self, "roll_speed", direction * roll_end_speed, roll_time) \
			.from(direction * roll_start_speed).set_trans(Tween.TRANS_QUAD)
	roll_tween.tween_callback(end_roll)
	roll_tween.play()

func end_roll():
	if rolling:
		rolling = false
		$RollCooldownTimer.start()
		$RollHitBox.disabled = true
		$HitBox.disabled = false
		$HurtBox/RollHurtbox.disabled = true
		$HurtBox/BaseHurtbox.disabled = false

func _ready():
	respawn_location = position
	$KnightSprite.play("idle")

func _input(event: InputEvent) -> void:
	if not $KnightSprite.animation == "roll" and (Input.is_action_pressed("walk_left") or Input.is_action_pressed("walk_right")):
		$KnightSprite.play("run")
	elif not $KnightSprite.animation == "roll" and (event.is_action_released("walk_left") or event.is_action_released("walk_right")):
		$KnightSprite.play("idle")

func _physics_process(delta):
	var fall_speed = max_fall_speed
	
	if is_on_wall() and not Input.is_action_pressed("move_down"):
		fall_speed = max_wall_fall_speed
	
	if on_ladder:
		if Input.is_action_pressed("move_down"):
			velocity.y = move_toward(velocity.y, max_speed, acceleration * delta)
		elif velocity.y > 0.0:
			velocity.y = move_toward(velocity.y, 0.0, acceleration * delta)
		else:
			velocity.y = move_toward(velocity.y, 0.0, gravity * delta)
	elif not is_on_floor():
		velocity.y = move_toward(velocity.y, fall_speed, gravity * delta)

	if not rolling:
		var direction = Input.get_axis("walk_left", "walk_right")
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
		if direction > 0:
			facing = FacingDirection.RIGHT
		elif direction < 0:
			facing = FacingDirection.LEFT
	else:
		velocity.x = roll_speed

	if Input.is_action_just_pressed("jump"):
		$JumpBufferTimer.start() 

	if not $JumpBufferTimer.is_stopped() and not $CoyoteFrameTimer.is_stopped():
		if last_wall_direction == FacingDirection.NONE:
			velocity.y = -jump_velocity
		else:
			velocity.x = - last_wall_direction * wall_jump_velocity_x
			velocity.y = -wall_jump_velocity_y

		$CoyoteFrameTimer.stop()
		$JumpBufferTimer.stop()
		end_roll()

	if Input.is_action_just_pressed("roll") \
			and not rolling and $RollCooldownTimer.is_stopped():
		$RollStartTimer.start()
		$KnightSprite.play("roll")

	move_and_slide()
	
	if is_on_floor() or is_on_wall() or on_ladder:
		$CoyoteFrameTimer.start()

	if is_on_floor() or on_ladder:
		last_wall_direction = FacingDirection.NONE
	elif is_on_wall():
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			if collision.get_normal().x < 0:
				last_wall_direction = FacingDirection.RIGHT
				break
			elif collision.get_normal().x > 0:
				last_wall_direction = FacingDirection.LEFT
				break
	
	if position.y > 5000:
		hazard_respawn()
		


func _on_coyote_frame_timer_timeout() -> void:
	last_wall_direction = FacingDirection.NONE

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("ladder_map"):
		on_ladder = true
	if body.is_in_group("hazard_map"):
		hazard_respawn()


func _on_hurt_box_body_exited(body: Node2D) -> void:
	if body.is_in_group("ladder_map"):
		on_ladder = false

func hazard_respawn():
	position = respawn_location
	velocity = Vector2(0, 0)
	end_roll()


func _on_knight_sprite_animation_finished() -> void:
	if $KnightSprite.animation == "roll":
		if Input.is_action_pressed("walk_left") or Input.is_action_pressed("walk_right"):
			$KnightSprite.play("run")
		else:
			$KnightSprite.play("idle")


func _on_roll_start_timer_timeout() -> void:
	start_roll(facing)
