extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.flag_ready.emit.call_deferred(self)
