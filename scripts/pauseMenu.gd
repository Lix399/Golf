extends Node2D

@onready var levelNumberLb: Label = $LevelNumber

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.loadingLevel.connect(on_loadingLevel)
	Signals.esc.connect(on_esc)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func on_loadingLevel(_levelPath : String) -> void:
	levelNumberLb.text = "LIVELLO " + str(GameManager.levelNumber + 1)

func on_esc() -> void:
	if GameManager.insideLevel:
		if GameManager.isPlaying:
			$LevelNumber.text = "livello " + str(GameManager.levelNumber + 1)
			visible = true
			get_tree().paused = true
			Signals.paused.emit()
		else:
			visible = false
			get_tree().paused = false
			Signals.resumed.emit()


func _on_resume_pressed() -> void:
			visible = false
			get_tree().paused = false
			Signals.resumed.emit()

func _on_exit_pressed() -> void:
	get_tree().paused = false
	visible = false
	Signals.resetState.emit()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


func _on_try_again_pressed() -> void:
	get_tree().paused = false
	Signals.tryAgain.emit()
	visible = false
