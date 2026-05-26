extends Sprite2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.isDragging.connect(on_isDragging)
	Signals.shot.connect(on_shotOrReleased)
	Signals.released.connect(on_shotOrReleased)

func on_shotOrReleased() -> void:
	visible = false
	
func on_isDragging(dragStart, _ballPosition) -> void:
	visible = true
	global_position = dragStart
