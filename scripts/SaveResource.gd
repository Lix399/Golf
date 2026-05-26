class_name SaveGame
extends Resource

@export var times : Array[float] = []

# Sostituisci "func new():" con "func _init():"
func _init() -> void:
	times.clear()
	for i in GameManager.NUMBER_OF_LEVELS:
		times.append(-1.0) # Usa -1.0 per far capire a Godot che è un float
		print("Riempito la posizione ", i, "\nTimes[" , i , "] = " , times[i])
		
	
