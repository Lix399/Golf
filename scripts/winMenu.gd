extends Node2D

@onready var winMenuAppearTime: Timer = $WinMenuAppearTime
@onready var winTimeLabel: Label = $WinTimeLabel
@onready var newRecord: Label = $NewRecord
@onready var task_result: Label = $TaskResult

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Signals.ballInHole.connect(on_ballInHole)
	Signals.hasWon.connect(on_hasWon)
	Signals.resetState.connect(on_resetState)
	Signals.newRecord.connect(on_newRecord)
	Signals.task_succeeded.connect(on_task_succeeded)
	Signals.task_failed.connect(on_task_failed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func on_task_succeeded():
	print("Task succeded in winmenu")
	task_result.visible = true
	task_result.text = "tempo caricato online!"
	
func on_task_failed():
	task_result.visible = true
	task_result.text = "impossibile caricare il tempo online!"

func on_resetState() -> void:
	newRecord.visible = false
	
	
func on_newRecord() -> void:
	newRecord.visible = true
	
func on_hasWon() -> void:
	winTimeLabel.text = str(GameManager.winTime) + "\nsecondi"
	print(winTimeLabel.text)
	
func on_ballInHole() -> void:
	winMenuAppearTime.start()

func _on_win_menu_appear_time_timeout() -> void:
	Signals.hasWon.emit()

func _on_try_again_pressed() -> void:
	print("Try again")
	get_tree().paused = false
	Signals.tryAgain.emit()
	visible = false

func _on_exit_pressed() -> void:
	get_tree().paused = false
	visible = false
	Signals.resetState.emit()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
