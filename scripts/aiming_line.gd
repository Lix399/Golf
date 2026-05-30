extends Line2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.isDragging.connect(on_isDragging)
	Signals.shot.connect(on_shotOrReleased)
	Signals.released.connect(on_shotOrReleased)
	
func _process(_delta: float) -> void:
	if GameManager.isAiming:
		set_point_position(1, get_global_mouse_position())

func on_shotOrReleased() -> void:
	visible = false
	visible = false
	
func on_isDragging(_dragStart, _ballPosition) -> void:
	visible = true
	clear_points()
	add_point(get_viewport().get_mouse_position())
	add_point(get_global_mouse_position())
