extends Node2D

@onready var pointer: Polygon2D = $Pointer
@onready var flag : Area2D
@onready var notifier : VisibleOnScreenNotifier2D
@onready var screen_rect : Rect2 #the screen rect, used to know if a certain point is inside it
@onready var margin = 70 #the margin in pixels between the screen's border and the indicator

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Signals.ball_ready.connect(on_ball_ready)
	Signals.flag_ready.connect(on_flag_ready)

func on_flag_ready(flagArg: Node2D):
	flag = flagArg
	notifier = flag.get_node("Notifier")
#
#func on_ball_ready(ballArg: Node2D):
	#self.ball = ballArg
#
#func checkBall():
	#var ballPosition = ball.get_global_transform_with_canvas().origin
	#
	#if screen_rect.has_point(ballPosition):
		#visible = false
		#return
	#
	#var indicator_x = clamp(ballPosition.x, margin, screen_rect.size.x - margin)
	#var indicator_y = clamp(ballPosition.y, margin, screen_rect.size.y - margin)
	#
	#global_position = Vector2(indicator_x, indicator_y)

func checkFlag():
	
	#checks if the flag is on screen. Returns if it does
	if notifier.is_on_screen():
		visible = false
		return
	
	visible = true
	
	var flag_pos = flag.get_global_transform_with_canvas().origin
	var screen_size = get_viewport_rect().size
	
	#sets the x and y of the indicator on the flag clamp position
	global_position.x = clamp(flag_pos.x, margin, screen_size.x - margin)
	global_position.y = clamp(flag_pos.y, margin, screen_size.y - margin)

	var flag_direction = flag_pos - global_position #the direction from the indicator to the flag
	var angle = flag_direction.angle() #the angle of the direction (in radians)

	var radius = 41 
	pointer.position = Vector2.RIGHT.rotated(angle) * radius
	pointer.rotation = angle + PI/2

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	screen_rect = get_viewport_rect()
	
	if not flag or not notifier:
		pass
	else:
		checkFlag()
