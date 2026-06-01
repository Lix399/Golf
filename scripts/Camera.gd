extends Camera2D
@onready var areas = [$AreaUp, $AreaDown, $AreaRight, $AreaLeft]
@onready var ball : Node2D= null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.up_pressed.connect(on_up_pressed)
	Signals.down_pressed.connect(on_down_pressed)
	Signals.right_pressed.connect(on_right_pressed)
	Signals.left_pressed.connect(on_left_pressed)
	Signals.ball_ready.connect(on_ball_ready)
	Signals.isDragging.connect(on_isDragging)
	Signals.hasRespawned.connect(on_hasRespawned)
	
	#set_deferred("global_position", ball.global_position)

func on_hasRespawned(ballPosition):
	global_position = ballPosition

func on_ball_ready(ballArg: Node2D):
	self.ball = ballArg
	global_position = ball.global_position
	reset_smoothing()
#
#func on_loadingLevel():
	#global_position = GameManager.ballGbPosition

func on_isDragging(_dragStart, ballPosition):
	var screen_rect = get_viewport_rect()
	var ballPosition_on_screen = ball.get_global_transform_with_canvas().origin
	
	if !screen_rect.has_point(ballPosition_on_screen):
		global_position = ballPosition

func on_up_pressed():
	global_position.y += -6

func on_down_pressed():
	global_position.y += +6

func on_right_pressed():
	global_position.x += +6

func on_left_pressed():
	global_position.x += -6

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	global_position.x = clamp(global_position.x, limit_left, limit_right)
	global_position.y = clamp(global_position.y, limit_top, limit_bottom)
	return
	for i in 4:
		var bodies = areas.get(i).get_overlapping_bodies()
		
		for body in bodies:
			if body.is_in_group("Ball") :
				if i == 0:
					global_position.y += -10
				if i == 1:
					global_position.y += +10
				if i == 2:
					global_position.x += 10
				if i == 3:
					global_position.x += -10
