extends Area2D

func _physics_process(_delta: float) -> void:
	var bodies = get_overlapping_bodies()
	
	for body in bodies:
		if body.is_in_group("Ball"):
			Signals.has_touched_sand.emit()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Ball"):
		Signals.has_exited_sand.emit()
