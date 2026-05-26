extends Sprite2D

@onready var hasShot = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	frame = 0
	Signals.hasRespawned.connect(on_hasRespawned)
	Signals.isDragging.connect(on_isDragging)
	Signals.shot.connect(on_shot)
	Signals.shotDirection.connect(on_shotDirection)
	Signals.current_aiming_force.connect(on_current_aiming_force)
	Signals.released.connect(on_released)

func on_released():
	frame = 0

func on_current_aiming_force(aimingForceArg):
	if aimingForceArg.length() < 150:
		frame = 1
	elif aimingForceArg.length() < 300:
		frame = 2
	else:
		frame = 3

func on_shotDirection(shootingRight):
	if shootingRight:
		flip_h = false
	else:
		flip_h = true

func on_shot() -> void:
	hasShot = true
	frame = 4
	$FrameDelta.start()

func on_hasRespawned(ballGbPosition) -> void:
	setPosition(ballGbPosition)

func on_isDragging(_dragStart, ballGbPosition) -> void:
	if hasShot:
		setPosition(ballGbPosition)
func setPosition(ballGbPosition):
	global_position = ballGbPosition
	global_position.y = global_position.y - 50
	global_position.x = global_position.x + 0.5


func _on_frame_delta_timeout() -> void:
	if frame == 6:
		frame = 0
		$FrameDelta.stop()
	else:
		frame += 1
	
