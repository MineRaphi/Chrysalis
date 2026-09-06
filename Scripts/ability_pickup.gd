extends Area2D




func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		PlayerAbilities.has_dash = true
		PlayerAbilities.has_double_jump = true
		PlayerAbilities.has_wall_jump = true
