extends Node

const NUMBER_OF_LEVELS = 2

const SAVE_PATH = "user://save.tres"
var saveData : SaveGame = null

@onready var level_online_times
@onready var playTime : float = 0
@onready var shots : int = 0
@onready var levelPath : String
@onready var levelNumber : int
@onready var levelString : String
@onready var winTime : float
@onready var insideLevel : bool = false
@onready var isPlaying : bool = false
@onready var winMenuAppearTime = 0.3
@onready var isAiming : bool = false
@onready var shootingRight : bool = false
@onready var isPaused : bool = false
@onready var canShoot : bool = false
@onready var isInHole : bool = false
@onready var isOnCooldown : bool = false
@onready var coolDownTimeLeft : float = 0
@onready var ballGbPosition : Vector2
@onready var aimingForce : Vector2
@onready var dragStart : Vector2
@onready var maxForceVector : float = 500
@onready var forceMult_normal : float = 2.4
@onready var username : String = ""

# Called upon entering the scene tree
func _ready() -> void:
	connect_signals()
	
	#crea o carica i dati di salvataggio
	if ResourceLoader.exists(SAVE_PATH):
		saveData = ResourceLoader.load(SAVE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	else:
		saveData = SaveGame.new()
		ResourceSaver.save(saveData, SAVE_PATH)

func connect_signals():
	Signals.shot.connect(on_shot)
	Signals.released.connect(on_released)
	Signals.paused.connect(on_paused)
	Signals.resumed.connect(on_resumed)
	Signals.countdownOver.connect(on_countdownOver)
	Signals.cooldownStart.connect(on_cooldownStart)
	Signals.cooldownOver.connect(on_cooldownOver)
	Signals.hasWon.connect(on_hasWon)
	Signals.ballInHole.connect(on_ballInHole)
	Signals.outOfBounds.connect(on_outOfBounds)
	Signals.hasRespawned.connect(on_hasRespawned)
	Signals.tryAgain.connect(on_tryAgain)
	Signals.loadingLevel.connect(on_loadingLevel)
	Signals.resetState.connect(on_resetState)
	Signals.isDragging.connect(on_isDragging)
	Signals.username_set.connect(on_username_set)
	Signals.levelInfoPressed.connect(on_levelInfoPressed)
	Signals.shotDirection.connect(on_shotDirection)
	Signals.current_aiming_force.connect(on_current_aiming_force)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	if Input.is_action_pressed("Up"):
		Signals.up_pressed.emit()
	if Input.is_action_pressed("Down"):
		Signals.down_pressed.emit()
	if Input.is_action_pressed("Left"):
		Signals.left_pressed.emit()
	if Input.is_action_pressed("Right"):
		Signals.right_pressed.emit()
		

func _input(input: InputEvent) -> void:
	if input.is_action_pressed("Escape"):
		Signals.esc.emit()
	if input.is_action_pressed("F11"):
		setFullscreen()

func on_current_aiming_force(aimingForceArg):
	self.aimingForce = aimingForceArg

func on_levelInfoPressed(levelPressed):
	if Cloud.conn_established == 0:
		Cloud.load_times(levelPressed)

func on_username_set(username_set):
	self.username = username_set

func on_shotDirection(shootingRightArg):
	self.shootingRight = shootingRightArg

func setFullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func registerNewTime():
	print("level number  in register new time : " + str(levelNumber))
	if saveData.times.get(levelNumber) == -1 \
		or shots < saveData.shots.get(levelNumber) \
		or winTime < saveData.times.get(levelNumber):
		print("Nuovo record in register new time, win time: " +str (winTime))
		saveData.times.set(levelNumber, winTime)
		saveData.shots.set(levelNumber, shots)
		print("Salvato!: " , str(ResourceSaver.save(saveData, SAVE_PATH)))
		Signals.newRecord.emit()

func on_hasWon() -> void:
	call_deferred("registerNewTime")
	if Cloud.conn_established == 0 and !username.is_empty():
		Cloud.save_time()

func on_isDragging(dragStartArg, ballPosition) -> void:
	dragStart = dragStartArg
	ballGbPosition = ballPosition
	isAiming = true

func on_resumed() -> void:
	isPaused = false

func on_resetState() -> void:
	playTime = 0
	shots = 0
	levelNumber = -1
	levelString = "null"
	winTime = -1
	insideLevel = false
	isPlaying = false
	winMenuAppearTime = 0.3
	isAiming = false
	isPaused = false
	canShoot = false
	isInHole = false
	isOnCooldown = false
	coolDownTimeLeft = 0

func on_tryAgain() -> void:
	get_tree().change_scene_to_file(levelPath)
	
	Signals.resetState.emit()
	Signals.loadingLevel.emit(levelPath)
	
	
func on_loadingLevel(levelPathParameter) -> void:
	shots = 0
	insideLevel = true
	levelPath = levelPathParameter
	levelNumber = (levelPath.substr(18, levelPath.length() - levelPath.find(".") - 4)).to_int()
	levelString = "level_" + str(levelNumber)
	
func on_hasRespawned(_lastPosition) -> void:
	canShoot = true
	
func on_outOfBounds() -> void:
	canShoot = false
	
func on_ballInHole() -> void:
	isInHole = true
	isPlaying = false
	canShoot = false
	
func on_cooldownStart(_lastPosition) -> void:
	canShoot = false
	isOnCooldown = true
	
func on_cooldownOver() -> void:
	canShoot = true
	isOnCooldown = false
	
func on_countdownOver() -> void:
	isPlaying = true
	canShoot = true
	
func on_paused() -> void:
	isPaused = true
	print("is paused messo a true")
	
func on_released() -> void:
	isAiming = false
	
func on_shot() -> void:
	canShoot = false
	isOnCooldown = true
	isAiming = false
