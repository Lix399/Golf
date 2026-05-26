extends Node2D

@onready var time: Label = $StopwatchLabel/TimeLabel
@onready var stopwatch: Label = $StopwatchLabel
@onready var countdownNumber: Label = $CountdownLabel
@onready var shootCdProgressBar: ProgressBar = $ShootCdProgressBar
@onready var shootCdNumber: Label = $ShootCdProgressBar/ShootCdNumber
@onready var aimingForceProgressBar: ProgressBar = $AimingForceProgressBar
@onready var stylebox

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.loadingLevel.connect(on_loadingLevel)
	Signals.cooldownStart.connect(on_cooldownStart)
	Signals.cooldownOver.connect(on_cooldownOver)
	Signals.hasWon.connect(on_hasWon)
	Signals.tryAgain.connect(on_tryAgain)
	Signals.isDragging.connect(on_isDragging)
	Signals.shot.connect(on_shotOrReleased)
	Signals.released.connect(on_shotOrReleased)
	stylebox = aimingForceProgressBar.get_theme_stylebox("fill").duplicate()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GameManager.isPlaying:
		processStopwatch(delta)
	if GameManager.isOnCooldown and !GameManager.isInHole:
		processCooldown()
	if GameManager.isAiming:
		processAiming()

func processAiming() -> void:
	var forceLength = GameManager.aimingForce.length()
	aimingForceProgressBar.value = forceLength
	
	if forceLength < 120:
		stylebox.bg_color =  Color("00ff00ff")
		aimingForceProgressBar.add_theme_stylebox_override("fill", stylebox)
	elif forceLength < 280:
		stylebox.bg_color =  Color("ffff00")
		aimingForceProgressBar.add_theme_stylebox_override("fill", stylebox)
	elif forceLength < 480:
		stylebox.bg_color = Color("d96700")
		aimingForceProgressBar.add_theme_stylebox_override("fill", stylebox)
	else:
		stylebox.bg_color = Color("d90000")
		aimingForceProgressBar.add_theme_stylebox_override("fill", stylebox)

func processCooldown() -> void:
	shootCdProgressBar.value = GameManager.coolDownTimeLeft
	shootCdNumber.text = str(GameManager.coolDownTimeLeft).pad_decimals(1)

func processStopwatch(delta) -> void:
	GameManager.playTime += delta
	time.text = str(GameManager.playTime).pad_decimals(3)

func on_shotOrReleased() -> void:
	aimingForceProgressBar.visible = false
	
func on_isDragging(_dragStart, _ballPosition) -> void:
	aimingForceProgressBar.visible = true	
	
func on_tryAgain() -> void:
	get_tree().reload_current_scene()
	shootCdProgressBar.visible = false
	stopwatch.visible = false
	
func on_hasWon() -> void:
	stopwatch.visible = false
	GameManager.winTime = time.text.pad_decimals(3).to_float()

func on_cooldownOver() -> void:
	shootCdProgressBar.visible = false

func on_cooldownStart(_lastPosition) -> void:
	shootCdProgressBar.visible = true

func on_loadingLevel(_levelPath) -> void:
	startCountDown()

func startCountDown() -> void:
	countdownNumber.visible = true
	get_tree().paused = true
	countdownNumber.text = str(3)
	await get_tree().create_timer(1).timeout
	countdownNumber.text = str(2)
	await get_tree().create_timer(1).timeout
	countdownNumber.text = str(1)
	await get_tree().create_timer(1).timeout
	stopwatch.visible = true
	countdownNumber.visible = false
	get_tree().paused = false
	Signals.countdownOver.emit()
