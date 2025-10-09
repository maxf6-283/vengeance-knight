extends Area2D



func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("knight_hurtbox"):
		var knight = area.get_parent()
		if "respawn_location" in knight:
			knight.respawn_location = position
