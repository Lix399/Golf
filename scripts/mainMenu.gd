extends Node2D

@onready var mainButtons = $MainMenuGUI/MainButtons
@onready var ballScene: PackedScene = preload("res://scenes/Ball.tscn")
@onready var rng = RandomNumberGenerator.new()
@onready var ball = null
@onready var title: Label = $MainMenuGUI/Title
@onready var level_select = $MainMenuGUI/LevelSelect
@onready var mainMenuGUI: CanvasLayer = $MainMenuGUI
@onready var selectedLevel : int
@onready var levelInfo: Control = $MainMenuGUI/LevelInfo
@onready var levelInfoLabel: Label = $MainMenuGUI/LevelInfo/LevelInfoLabel
@onready var your_time: Label = $MainMenuGUI/LevelInfo/YourRecordsLabel/YourTime
@onready var levelIcon: TextureRect = $MainMenuGUI/LevelInfo/LevelIcon
@onready var online_connection: Label = $MainMenuGUI/OnlineConnection
@onready var username_label: Label = $MainMenuGUI/MainButtons/UsernameLabel
@onready var username_btn: Button = $MainMenuGUI/MainButtons/UsernameBtn
@onready var line_edit: LineEdit = $MainMenuGUI/MainButtons/UsernameBtn/LineEdit
@onready var online_times_container: VBoxContainer = $MainMenuGUI/LevelInfo/OnlineRecordsLabel/ScrollContainer/OnlineTimesContainer
@onready var online_record_model: Label = $MainMenuGUI/LevelInfo/OnlineRecordsLabel/ScrollContainer/OnlineTimesContainer/OnlineRecord1
var levelIcons : TextureRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rng.randomize()
	Signals.conn_established.connect(on_conn_established)
	Signals.online_times_ready.connect(on_online_times_ready)
	
	if !GameManager.username.is_empty():
		username_label.visible = false
		username_btn.visible = false

func on_online_times_ready():
	var times = GameManager.level_online_times
	
	#elimina i tempi duplicati per evitare di aggiungere doppioni dopo
	@warning_ignore("shadowed_variable_base_class")
	for duplicate in online_times_container.get_children():
		if duplicate != online_record_model:
			duplicate.queue_free()
	
	#aggiunge i tempi duplicando un modello
	for i in range(times.size()):
		if i == 0:
			online_record_model.text = str(i + 1) + ". " +str(times[i].time) + " | " + str(times[i].username)
		else:
			var copy = online_record_model.duplicate()
			copy.text = str(i + 1) + ". " +str(times[i].time) + " | " + str(times[i].username)
			online_times_container.add_child(copy)

func on_conn_established():
	print("Main menu conn established")
	setup_cloud_label()
	$MainMenuGUI/OnlineConnection/FadeOutStart.start()
	if Cloud.conn_established == 0:
		$MainMenuGUI/LevelInfo/OnlineRecordsLabel.visible = true

func _on_fade_out_start_timeout() -> void:
	$MainMenuGUI/OnlineConnection/FadeOut.start()
	
func _on_fade_out_timeout() -> void:
	var transparency = online_connection.self_modulate.a
	
	if transparency == 0:
		$MainMenuGUI/OnlineConnection/FadeOut.stop()
		online_connection.visible = false
		
	online_connection.self_modulate = Color(1, 1, 1, transparency - 0.1)
	
func setup_cloud_label():
	if Cloud.conn_established == 0:
		online_connection.text = "Sei connesso online!"
	else:
		print("Non riuscita")
		online_connection.text = "Connessione al server non riuscita"
	online_connection.visible = true

func _on_play_pressed() -> void:
	mainButtons.visible = false
	level_select.visible = true
	
func _on_secret_button_pressed() -> void:
	if ball != null:
		spawnNewBall()
			
	else:
		ball = ballScene.instantiate()
		ball.z_index = 5
		ball.visible = true
		ball.position.x = int(rng.randf_range(0, 800))
		ball.position.y = -30
		mainMenuGUI.add_child(ball)

func spawnNewBall() -> void:
	var newBall = ballScene.instantiate()
	newBall.z_index = 5
	newBall.position.x = int(rng.randf_range(0, 1920))
	newBall.position.y = -30
	mainMenuGUI.add_child(newBall)

func _on_level_pressed(levelPressed) -> void:
	Signals.levelInfoPressed.emit(levelPressed)
	selectedLevel = levelPressed
	level_select.visible = false
	levelInfoLabel.text = "livello " +  str(selectedLevel + 1)
	var iconPath = "res://graphics/sprites/level icons/Level" + str(selectedLevel) + "Icon.png"
	levelIcon.texture = load(iconPath)
	levelInfo.visible = true
	your_time.text = str(GameManager.saveData.times.get(selectedLevel))
	your_time.visible = true

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_play_level_pressed() -> void:
	var levelScenePath = "res://scenes/Level" + str(selectedLevel) + ".tscn"
	get_tree().change_scene_to_file(levelScenePath)
	Signals.loadingLevel.emit(levelScenePath)


func _on_username_btn_pressed() -> void:
	line_edit.visible = true
	line_edit.grab_focus()

func _on_line_edit_text_submitted(new_text: String) -> void:
	if !new_text.is_empty():
		Signals.username_set.emit(new_text)
		line_edit.visible = false
		username_label.visible = false
		username_btn.visible = false
	else:
		username_label.text = "Nome non valido"
		line_edit.visible = false


func _on_level_select_back_pressed() -> void:
	level_select.visible = false
	mainButtons.visible = true


func _on_level_info_back_pressed() -> void:
	level_select.visible = true
	levelInfo.visible = false
