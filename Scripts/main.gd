extends Node2D

@export var start_room = load("res://Levels/TestLevels/test_level.tscn")

@onready var current_room_node: Node2D = $currentRoom
@onready var player: CharacterBody2D = $Player
@onready var main_menu: CanvasLayer = $mainMenu

var current_room_path: String

func _ready() -> void:
	player.disable()

func switch_to_room(level: PackedScene, spawn_name: String = "default"):
	var col_lay_save = player.collision_layer
	player.collision_layer = 0
	
	current_room_path = level.resource_path
	
	var next_room = level.instantiate()
	var spawn = next_room.find_child(spawn_name)
	
	if spawn:
		player.position = spawn.position
	else:
		player.position = Vector2(0, 0)
	
	player.snap_camera_to_target()
	
	for child in current_room_node.get_children():
		child.queue_free()
	
	current_room_node.add_child(next_room)
	
	await get_tree().process_frame
	
	player.collision_layer = col_lay_save

func _on_start_button_pressed() -> void:
	player.enable()
	main_menu.hide()
	await get_tree().process_frame
	switch_to_room(start_room)

func _on_load_button_pressed() -> void:
	load_game()

func save_game() -> void:
	var save_data = {
		"current_room": current_room_path,
		"spawn_name": "save",
		"abilities": {
			"has_dash": PlayerAbilities.has_dash,
			"has_double_jump": PlayerAbilities.has_double_jump,
			"has_wall_jump": PlayerAbilities.has_wall_jump
		}
	}
	
	var file = FileAccess.open("user://savegame.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data))
	file.close()

func load_game() -> void:
	if not FileAccess.file_exists("user://savegame.json"):
		return
	
	var file = FileAccess.open("user://savegame.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	
	var save_data = JSON.parse_string(content)
	
	PlayerAbilities.has_dash = save_data["abilities"]["has_dash"]
	PlayerAbilities.has_double_jump = save_data["abilities"]["has_double_jump"]
	PlayerAbilities.has_wall_jump = save_data["abilities"]["has_wall_jump"]
	
	player.enable()
	main_menu.hide()
	await get_tree().process_frame
	
	switch_to_room(load(save_data["current_room"]), save_data["spawn_name"])
