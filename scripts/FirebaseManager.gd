extends Node

@onready var conn_established : int = -1 #-1 se non processato, 0 se stabilito e 1 se fallito
@onready var error = null
@onready var task: FirestoreTask = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Firebase.process_mode = Node.PROCESS_MODE_ALWAYS
	Firebase.Auth.process_mode = Node.PROCESS_MODE_ALWAYS
	Firebase.Firestore.process_mode = Node.PROCESS_MODE_ALWAYS
	Firebase.Auth.signup_succeeded.connect(on_signupSucceeded)
	Firebase.Auth.signup_failed.connect(on_signupFailed)
	Firebase.Auth.login_succeeded.connect(on_loginSucceeded)
	Firebase.Auth.login_failed.connect(on_loginFailed)
	
	if Firebase.Auth.has_signal("token_refresh_succeeded"):
		Firebase.Auth.token_refresh_succeeded.connect(on_tokenRefreshSucceeded)

	await get_tree().process_frame
	
	# Controlla se Firebase ha gia' eseguito il login se no procediamo a farlo noi
	if Firebase.Auth.auth and Firebase.Auth.auth.has("localid") and Firebase.Auth.auth.localid != "":
		_handle_connection_success()
		return

	if !Firebase.Auth.check_auth_file():
		Firebase.Auth.login_anonymous()

func load_times(levelNumber):
	var auth = Firebase.Auth.auth
	
	if auth and auth.has("localid") and auth.localid != "":
		
		var query : FirestoreQuery = FirestoreQuery.new()
		query.from("times")
		query.where("levelNumber", FirestoreQuery.OPERATOR.EQUAL, levelNumber)
		query.order_by("time", FirestoreQuery.DIRECTION.ASCENDING)
		
		task = Firebase.Firestore.query(query)
		task.task_error.connect(on_query_error)
		task.task_finished.connect(on_query_finished)
		
	else:
		printerr("Errore: il login non e' valido!")

# Usiamo i tre punti (...) o definiamo gli argomenti per accettare tutto quello che arriva
func on_query_error(code, _status, message, data):
	print("--- ERRORE QUERY FIREBASE ---")
	print("Codice: ", code)
	print("Messaggio: ", message)
	print("Dati (cerca il link qui): ", data)

func on_query_finished(_task):
	if task._response_code == 0:
		var results = []
		
		#prendiamo tutti i documenti dalla task per passarli a GameManager
		for doc in task.data:
			results.append(doc.doc_fields)
			print(str(doc))
		GameManager.level_online_times = results
		Signals.online_times_ready.emit()
	else:
		printerr("Query fallita")

func save_time():
	var auth = Firebase.Auth.auth
	var collectionid = "times"
	var data: Dictionary = {
		"time": float(GameManager.winTime),
		"username": str(GameManager.username),
		"levelNumber": int(GameManager.levelNumber)
	}
	
	if auth and auth.has("localid") and auth.localid != "":
		var collection: FirestoreCollection = Firebase.Firestore.collection(collectionid)
		task = collection.add("", data)
		
		if task == null:
			printerr("collection.add() ha restituito un task null")
			return
			
		task.task_finished.connect(on_task_finished)
	else:
		printerr("Errore: il login non e' valido!")

func on_task_finished(_task: FirestoreTask):
	if self.task._response_code == 0:
		Signals.task_succeeded.emit()
	else:
		Signals.task_failed.emit()

func on_signupSucceeded(auth):
	Firebase.Auth.save_auth(auth)
	_handle_connection_success()

func on_loginSucceeded(auth):
	Firebase.Auth.save_auth(auth)
	_handle_connection_success()

func on_signupFailed(_error_code, message):
	_handle_connection_failed(message)

func on_loginFailed(_error_code, message):
	_handle_connection_failed(message)

func on_tokenRefreshSucceeded(auth):
	Firebase.Auth.save_auth(auth)
	_handle_connection_success()

func _handle_connection_success():
	conn_established = 0
	Signals.conn_established.emit()

func _handle_connection_failed(message):
	conn_established = 1
	self.error = message
	Signals.conn_established.emit()
