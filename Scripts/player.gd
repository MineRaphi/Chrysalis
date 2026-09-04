extends CharacterBody2D

enum MovementState { IDLE, RUN, JUMP, FALL, DASH }
enum ActionState { NONE, ATTACK, HURT }

var movement_state: MovementState = MovementState.IDLE
var action_state: ActionState = ActionState.NONE
var is_jumping = false

const SPEED = 300.0
const SPRINT_SPEED = 420.0
const JUMP_VELOCITY = -400.0

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# apply gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if velocity.y >= 0 or is_on_floor():
		is_jumping = false
	
	# jumps
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = true
	
	# jump release
	if Input.is_action_just_released("jump") and is_jumping:
		velocity.y = 0
		is_jumping = false
	
	# moves horizontaly
	var direction := Input.get_axis("left", "right")
	velocity.x = direction * SPEED
	
	_update_movement_state()
	_update_animation()
	move_and_slide()

func _update_movement_state() -> void:
	if not is_on_floor():
		if velocity.y < 0:
			movement_state = MovementState.JUMP
		else:
			movement_state = MovementState.FALL
	elif abs(velocity.x) > 0.1:
		movement_state = MovementState.RUN
	else:
		movement_state = MovementState.IDLE

func _update_animation() -> void:
	if velocity.x > 0:
		anim_sprite.flip_h = false
	elif velocity.x < 0:
		anim_sprite.flip_h = true
		
	if action_state == ActionState.HURT:
		print("hurt") #animation still needed
		return
	
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


func _on_deathzone_body_entered(body: Node2D) -> void:
	if body == self:
		call_deferred("_kill_player")

func _kill_player():
	get_tree().reload_current_scene()
