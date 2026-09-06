extends Node2D

@export var level: PackedScene
@export var spawn_name: String

func _ready() -> void:
	assert(level, "Level needs to be set")
	assert(spawn_name != "", "Spawn name needs to be set")
	
