extends Node2D

func _on_hole_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Ball"):
		Signals.ballInHole.emit()
