class_name SaveGame
extends Resource

@export var times : Array[float] = []
@export var shots : Array[int] = []

# Sostituisci "func new():" con "func _init():"
func _init() -> void:
	times.clear()
	for i in GameManager.NUMBER_OF_LEVELS:
		times.append(-1.0)
		shots.append(-1)
		
	
