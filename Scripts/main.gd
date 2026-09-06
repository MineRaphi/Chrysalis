extends Node2D

func _ready() -> void:
	var start_room = load("res://Levels/TestLevels/test_level.tscn")
	add_child(start_room.instantiate())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
