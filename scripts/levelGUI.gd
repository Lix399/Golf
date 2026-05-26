extends CanvasLayer

@onready var pauseMenu: Node2D = $PauseMenu
@onready var winMenu: Node2D = $WinMenu

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.paused.connect(on_paused)
	Signals.hasWon.connect(on_hasWon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func on_hasWon() -> void:
	get_tree().paused = true
	winMenu.visible = true

func on_paused() -> void:
	pauseMenu.visible = true
	get_tree().paused = true
