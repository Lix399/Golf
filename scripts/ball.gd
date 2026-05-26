extends RigidBody2D

@onready var cooldown: Timer = $Cooldown
@onready var respawnTime: Timer = $RespawnTime

var dragging = false
var dragStart = Vector2.ZERO
var shootingRight : bool
var lastPosition : Vector2 = Vector2.ZERO
var speed
var checkSpeed = false
var pendingRespawn = false

func _ready() -> void:
	Signals.shot.connect(on_shot)
	Signals.outOfBounds.connect(on_outOfBounds)
	Signals.paused.connect(on_paused)
	Signals.resumed.connect(on_resumed)
	lastPosition = global_position
	Signals.resetState.connect(on_resetState)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && GameManager.canShoot:
			if event.pressed:
				mousePressed() #prepara il tiro
			elif dragging:
				mouseReleased() #tira la palla

func _process(_delta: float) -> void:
	
	if checkSpeed:
		call_deferred("checkBallSpeedForCooldown")
	
	if cooldown.time_left > 0:
		GameManager.coolDownTimeLeft = cooldown.time_left
		
	if dragging:
		GameManager.aimingForce = shootingForce()
	
func checkBallSpeedForCooldown() -> void:
	speed = linear_velocity.length()
	
	if speed < 1:
		checkSpeed = false
		lastPosition = global_position
		cooldown.start()
		if !GameManager.isInHole: 
			Signals.cooldownStart.emit(lastPosition)

func on_resumed() -> void:
	cooldown.paused = false
	respawnTime.paused = false
	
func on_resetState() -> void:
	dragging = false
	dragStart = Vector2.ZERO
	lastPosition = Vector2.ZERO
	checkSpeed = false
	pendingRespawn = false
	
func on_paused() -> void:
	cooldown.paused = true
	respawnTime.paused = true
	
func on_outOfBounds() -> void:
	print("OUT OF BOUNDS!!!!!")
	checkSpeed = false
	respawnTime.start()
	call_deferred("respawnBall")
	
func on_shot() -> void:
	checkSpeed = true

func mousePressed() -> void:
	dragging = true
	dragStart = get_global_mouse_position()
	Signals.isDragging.emit(dragStart, global_position)

func mouseReleased() -> void:
	var forceMult = GameManager.forceMult_normal
	dragging = false
	var force = shootingForce()
	if force.length() > 10:
		apply_central_impulse(force * forceMult) # Viene applicata la forza sulla palla 2.1
		Signals.shotDirection.emit(shootingRight)
		Signals.shot.emit()
	else:
		Signals.released.emit()

func shootingForce() -> Vector2:
	var currentMousePosition = get_global_mouse_position()
	
	if abs(currentMousePosition.x) < abs(dragStart.x):
		shootingRight = true
	else:
		shootingRight = false
	
	var direction = (dragStart - currentMousePosition) # Offset in pixel relativo a dragStart
	var force : Vector2
	if direction.length() > 10:
		force = direction.limit_length(GameManager.maxForceVector)
	return force

func _on_cooldown_timeout() -> void:
	Signals.cooldownOver.emit()
	print("ORA PUOI TIRARE!!!!!!!!!!!")

func respawnBall() -> void:
	pendingRespawn = true
	freeze = true 
	visible = false

func _on_respawn_time_timeout() -> void:
	freeze = false
	visible = true
	print("Respawnato!!!!!")

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if pendingRespawn:
		state.transform.origin = lastPosition
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0
		pendingRespawn = false
		Signals.hasRespawned.emit(lastPosition)
		cooldown.start()
		Signals.cooldownStart.emit(lastPosition)
