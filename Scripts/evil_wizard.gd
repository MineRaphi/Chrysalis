extends CharacterBody2D

enum STATE { IDLE, HURT }

const START_HEALTH = 3

@onready var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D

var health = START_HEALTH
var state = STATE.IDLE

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if state == STATE.IDLE:
		anim_sprite.play("idle")
	elif state == STATE.HURT:
		anim_sprite.play("hurt")
	
	move_and_slide()

func take_damage(damage: int):
	health -= damage
	
	if health <= 0:
		queue_free()
		
	state = STATE.HURT
	
	await anim_sprite.animation_finished
	
	state = STATE.IDLE
	
	
	
