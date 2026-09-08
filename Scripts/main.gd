extends Node2D

@export var start_room = load("res://Levels/TestLevels/test_level.tscn")

@onready var current_room: Node2D = $currentRoom
@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	var col_lay_save = player.collision_layer
	player.collision_layer = 0
	
	switch_to_room(start_room)
	
	await get_tree().create_timer(0.1).timeout
	
	player.collision_layer = col_lay_save

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func switch_to_room(level: PackedScene, spawn_name: String = "default"):
	print(level, spawn_name)
	var next_room = level.instantiate()
	
	var spawn = next_room.find_child(spawn_name)
	
	if spawn:
		player.position = spawn.position
	else:
		player.position = Vector2(0, 0)
	
	for child in current_room.get_children():
		child.queue_free()
	
	current_room.add_child(next_room)
