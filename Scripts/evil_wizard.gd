extends CharacterBody2D

const START_HEALTH = 3

var health = START_HEALTH

func _ready() -> void:
	add_to_group("enemy")

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

func take_damage(damage: int):
	health -= damage
	
	if health <= 0:
		queue_free()
