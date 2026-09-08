extends Node2D

@export var level_path: String
@export var spawn_name: String

var level: PackedScene

func _ready() -> void:
	assert(level_path != "", "Level path needs to be set")
	assert(spawn_name != "", "Spawn name needs to be set")
	
	level = load(level_path)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		get_node("/root/Main").call_deferred("switch_to_room", level, spawn_name)
