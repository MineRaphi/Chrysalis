extends CharacterBody2D

enum MovementState { IDLE, RUN, JUMP, FALL, DASH, WALL, SPRINT }
enum ActionState { NONE, ATTACK, HURT }

var movement_state: MovementState = MovementState.IDLE
var action_state: ActionState = ActionState.NONE

var disable_player := false
var is_jumping := false
var is_dashing := false
var is_dash_on_cooldown := false
var is_double_jump_avalible := true
var is_wall_sliding := false
var movement_disabled := false
var is_attack_on_cooldown := false
var combo_state := 0
var look_direction := 1
var look_updown := 0
var camera_distance := Vector2(0, 0)
var last_save_ground_pos := Vector2(0, 0)

var already_hit_this_attack: Array = []

const SPEED = 240.0
const DASH_SPEED = 600.0
const SPRINT_SPEED = 320.0
const WALL_SLIDE_SPEED = 200.0
const JUMP_VELOCITY = -400.0
const POGO_VELOCITY = -275.0

const CAMERA_MIN_DIS_X = 16
const CAMERA_MAX_DIS_X = 64

const CAMERA_MIN_DIS_Y = -48
const CAMERA_MAX_DIS_Y = 48
const CAMERA_OFFSET_Y = -16

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera_target: Marker2D = $CameraTarget
@onready var camera: Camera2D = $CameraTarget/Camera2D
@onready var dash_timer: Timer = $Timer/DashTimer
@onready var dash_cooldown: Timer = $Timer/DashCooldown
@onready var wall_jump_timer: Timer = $Timer/WallJumpTimer
@onready var combo_timer: Timer = $Timer/ComboTimer
@onready var attack_cooldown: Timer = $Timer/AttackCooldown
@onready var slash: AnimatedSprite2D = $Slash
@onready var attack_box: Area2D = $AttackBox
@onready var hurtbox: Area2D = $Hurtbox


func _physics_process(delta: float) -> void:
	if disable_player:
		return
	
	_handle_dash_input()
	
	if is_dashing:
		_apply_dash_movement()
	else:
		_apply_gravity(delta)
		_handle_sprint_input()
		_handle_movement_input()
		_handle_wall_slide()
		_handle_jump_input()
		_handle_attack_input()
	
	_handle_cooldown_resets()
	
	if action_state == ActionState.ATTACK:
		_handle_attack_hit()
	
	_update_data()
	_update_camera()
	_update_movement_state()
	_update_animation()
	move_and_slide()


func _handle_dash_input() -> void:
	# detects dash
	if Input.is_action_just_pressed("dash") and PlayerAbilities.has_dash and not is_dash_on_cooldown:
		is_dashing = true
		is_dash_on_cooldown = true
		dash_timer.start()

func _handle_sprint_input() -> void:
	if Input.is_action_pressed("dash") and not is_dashing and PlayerAbilities.has_dash:
		movement_state = MovementState.SPRINT
	if Input.is_action_just_released("dash"):
		movement_state = MovementState.RUN

func _apply_dash_movement() -> void:
	velocity.y = 0
	if look_direction > 0:
		velocity.x = DASH_SPEED
	else:
		velocity.x = -DASH_SPEED

func _apply_gravity(delta: float) -> void:
	# apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

func _handle_movement_input() -> void:
	# moves horizontaly
	if not movement_disabled:
		var direction := Input.get_axis("left", "right")
		if movement_state == MovementState.SPRINT:
			velocity.x = direction * SPRINT_SPEED
		else:
			velocity.x = direction * SPEED

func _handle_wall_slide() -> void:
	# wall slide: clamp fall speed while pressed against a wall in the air
	is_wall_sliding = is_on_wall_only() and not is_on_floor() and velocity.y > 0 and PlayerAbilities.has_wall_jump
	if is_wall_sliding:
		# -1 = wall on right, 1 = wall on left
		var wall_side = sign(get_wall_normal().x)
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)
		velocity.x += -wall_side

func _handle_jump_input() -> void:
	if velocity.y >= 0 or is_on_floor():
		is_jumping = false
	
	# jumps
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			is_jumping = true
		elif is_wall_sliding:
			# -1 = wall on right, 1 = wall on left
			var wall_side = sign(get_wall_normal().x)
			velocity.y = JUMP_VELOCITY
			velocity.x = wall_side * SPEED
			is_jumping = true
			
			movement_disabled = true
			wall_jump_timer.start()
		elif is_double_jump_avalible and PlayerAbilities.has_double_jump:
			velocity.y = JUMP_VELOCITY
			is_jumping = true
			is_double_jump_avalible = false
			
	
	# jump release
	if Input.is_action_just_released("jump") and is_jumping:
		velocity.y = 0
		is_jumping = false

func _handle_attack_input() -> void:
	# attack
	if Input.is_action_just_pressed("attack") and not is_wall_sliding and not is_attack_on_cooldown and combo_state < 3:
		action_state = ActionState.ATTACK
		#is_attack_on_cooldown = true
		#combo_state += 1
		#attack_cooldown.start()
		#combo_timer.start()
		_slash()

func _handle_cooldown_resets() -> void:
	if is_dash_on_cooldown and (is_on_floor() or is_wall_sliding) and dash_cooldown.is_stopped():
		dash_cooldown.start()
	
	if not is_double_jump_avalible and (is_on_floor() or is_wall_sliding):
		is_double_jump_avalible = true

func _handle_attack_hit() -> void:
	for area in attack_box.get_overlapping_areas():
		if area.name == "Hurtbox" and not already_hit_this_attack.has(area):
			already_hit_this_attack.append(area)
			area.get_parent().take_damage(1)

func _update_data() -> void:
	if is_wall_sliding:
		# -1 = wall on right, 1 = wall on left
		look_direction = sign(get_wall_normal().x)
	else:
		if velocity.x > 0:
			look_direction = 1
		elif velocity.x < 0:
			look_direction = -1
	
	if Input.is_action_pressed("up"):
		look_updown = 1
	elif Input.is_action_pressed("down"):
		look_updown = -1
	else:
		look_updown = 0

func _update_movement_state() -> void:
	if is_dashing:
		movement_state = MovementState.DASH
	elif is_wall_sliding:
		movement_state = MovementState.WALL
	elif not is_on_floor():
		if velocity.y < 0:
			movement_state = MovementState.JUMP
		else:
			movement_state = MovementState.FALL
	elif abs(velocity.x) > 0.1:
		if movement_state == MovementState.SPRINT:
			return
		movement_state = MovementState.RUN
	else:
		movement_state = MovementState.IDLE

func _update_animation() -> void:
	if look_direction > 0:
		anim_sprite.flip_h = false
	elif look_direction < 0:
		anim_sprite.flip_h = true
	
	if action_state == ActionState.HURT:
		print("hurt") #animation still needed
		return
	
	#if action_state == ActionState.ATTACK:
	#	anim_sprite.play("attack_" + str(combo_state))
	#	return
	
	match movement_state:
		MovementState.IDLE:
			anim_sprite.play("idle")
		MovementState.RUN:
			anim_sprite.play("run")
		MovementState.JUMP:
			anim_sprite.play("jump")
		MovementState.FALL:
			anim_sprite.play("fall")
		MovementState.DASH:
			anim_sprite.play("dash")
		MovementState.WALL:
			anim_sprite.play("wall_slide")
		MovementState.SPRINT:
			anim_sprite.play("sprint")

func _update_camera() -> void:
	camera_distance.x = abs(velocity.x / 3)
	camera_distance.y = velocity.y / 2
	
	if not is_wall_sliding:
		camera_distance.x = look_direction * clamp(camera_distance.x, CAMERA_MIN_DIS_X, CAMERA_MAX_DIS_X)
	else:
		camera_distance.x = 0
	camera_distance.y = clamp(camera_distance.y, CAMERA_MIN_DIS_Y, CAMERA_MAX_DIS_Y)
	camera_distance.y += CAMERA_OFFSET_Y
	
	camera_target.position.x = lerp(camera_target.position.x, camera_distance.x, 0.1)
	camera_target.position.y = lerp(camera_target.position.y, camera_distance.y, 0.1)
	
	camera.position_smoothing_speed = max(velocity.length()/50, 2)

func _on_dash_timer_timeout() -> void:
	is_dashing = false

func _on_dash_cooldown_timeout() -> void:
	is_dash_on_cooldown = false

func _on_wall_jump_timer_timeout() -> void:
	movement_disabled = false

func _hazard_respawn():
	position = last_save_ground_pos
	snap_camera_to_target()

func _on_attack_cooldown_timeout() -> void:
	is_attack_on_cooldown = false
	action_state = ActionState.NONE

func _on_combo_timer_timeout() -> void:
	combo_state = 0

func _on_save_ground_pos_timeout() -> void:
	if is_on_floor():
		last_save_ground_pos = position

func snap_camera_to_target():
	camera.reset_smoothing()

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "deathzone":
		call_deferred("_hazard_respawn")
	
	if area.name == "Save":
		get_node("/root/Main").save_game()

func _slash() -> void:
	slash.visible = true
	action_state = ActionState.ATTACK
	already_hit_this_attack.clear()
	already_hit_this_attack.append(hurtbox)
	
	if look_updown < 0 and not is_on_floor():
		slash.rotation_degrees = 90
		slash.flip_h = false
		attack_box.rotation_degrees = 90
		slash.position = Vector2(7, -8)
	elif look_updown > 0:
		slash.rotation_degrees = 90
		slash.flip_h = true
		attack_box.rotation_degrees = -90
		slash.position = Vector2(6, -32)
	else:
		if look_direction > 0:
			slash.flip_h = false
			attack_box.rotation_degrees = 0
		elif look_direction < 0:
			slash.flip_h = true
			attack_box.rotation_degrees = 180
		
		slash.rotation_degrees = 0
		slash.position = Vector2(look_direction * 14, -26)

	
	slash.play("slash")
	
	await slash.animation_finished
	slash.visible = false
	action_state = ActionState.NONE

func disable() -> void:
	disable_player = true
	hide()

func enable() -> void:
	disable_player = false
	show()
