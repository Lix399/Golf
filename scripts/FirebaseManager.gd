extends Node

@onready var conn_established : int = -1 #-1 se non processato, 0 se stabilito e 1 se fallito
@onready var error = null
@onready var task: FirestoreTask = null
@onready var current_username_to_lower

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

func load_times(is_win_context):
	var auth = Firebase.Auth.auth

	if auth and auth.has("localid") and auth.localid != "":
		#downloads the entire database. Using querys is to complex and bugged
		task = Firebase.Firestore.list("times") 
		
		task.task_error.connect(on_query_error)
		task.task_finished.connect(on_collection_finished.bind(is_win_context))
	else:
		printerr("Errore: il login non e' valido!")


# Usiamo i tre punti (...) o definiamo gli argomenti per accettare tutto quello che arriva
func on_query_error(code, _status, message, data):
	printerr("--- ERRORE QUERY FIREBASE ---")
	printerr("Codice: ", code)
	printerr("Messaggio: ", message)
	printerr("Dati (cerca il link qui): ", data)
	
func on_collection_finished(_task: FirestoreTask, should_evaluate: bool):
	if _task._response_code == 0:
		var results = []
		var current_level = int(GameManager.levelNumber)
		
		#controls every document in the data received
		for doc in _task.data:
			var fields = doc.doc_fields
			#get("", x): if no levelNumber is found, x is returned. (in this case -1)
			if int(fields.get("levelNumber", -1)) == current_level:
				var data_with_id = fields.duplicate()
				#we add the document id (name) to each record
				data_with_id["doc_id"] = doc.doc_name 
				results.append(data_with_id)
		
		# Se abbiamo trovato dei tempi per questo livello, li ordiniamo
		if results.size() > 0:
			# we sort the results to succesfully display the leaderboard
			results.sort_custom(sort_leaderboard)
		else:
			print("Leaderboard empty")
			
		GameManager.level_online_times = results
		Signals.online_times_ready.emit()
		
		if should_evaluate:
			evaluate_and_save_time()
			
	else:
		printerr("Scaricamento collezione fallito. Codice: ", _task._response_code)

func evaluate_and_save_time():
	current_username_to_lower = str(GameManager.username).to_lower()
	var current_time = float(GameManager.winTime)
	var current_shots = float(GameManager.shots)
	var times = GameManager.level_online_times

	var existing_doc_id = ""
	var existing_time = 0.0
	var existing_shots = 0
	var user_found = false
	
	#check for already existing record from the user
	for t in times:
		if t["username"].to_lower() == current_username_to_lower:
			user_found = true
			existing_doc_id = t["doc_id"]
			existing_time = float(t["time"])
			existing_shots = int(t["shots"])
			break
	
	if user_found: #existing user
		if current_shots < existing_shots \
			or current_shots == existing_shots and current_time < existing_time:
			update_existing_time(existing_doc_id)
		else:
			Signals.task_succeeded.emit("Non hai battutto il tuo record, " + current_username_to_lower)
	
	else: #new user
		if times.size() < 50: #top 50 not full, record is inserted immedeately
			print("Classifica non ancora piena. Salvo il nuovo tempo!")
			save_new_time()
		else: #top 50 full, must be a better record
			var fiftieth_time = float(times[49]["time"]) 
			var fiftieth_shots = float(times[49]["shots"]) 
			if current_shots < fiftieth_shots \
				or current_shots == fiftieth_shots and current_time < fiftieth_time:
				save_new_time()
			else:
				Signals.task_succeeded.emit \
					("il tuo record non rientra nella top 50 purtroppo, " \
						+ current_username_to_lower)

func save_new_time():
	var auth = Firebase.Auth.auth
	var collectionid = "times"
	var data: Dictionary = {
		"shots": int(GameManager.shots),
		"time": float(GameManager.winTime),
		"username": str(GameManager.username),
		"levelNumber": int(GameManager.levelNumber)
	}
	
	if auth and auth.has("localid") and auth.localid != "":
		var collection: FirestoreCollection = Firebase.Firestore.collection(collectionid)
		
		task = collection.add("", data)
		
		if task == null: return
		
		task.task_finished.connect(save_time_finished)
		
	else:
		printerr("Errore auth in save_new_time")

func save_time_finished(_task: FirestoreTask):
	if task._response_code == 0:
		var position = update_local_and_get_position()
		Signals.task_succeeded.emit \
		("Record inserito, " + current_username_to_lower \
		 + ". La tua posizione attuale e' " + str(position))
	else:
		Signals.task_failed.emit()

func update_local_and_get_position() -> int:
	var times = GameManager.level_online_times
	var current_username = str(GameManager.username).to_lower()
	var current_level = int(GameManager.levelNumber)
	
	var user_found_locally = false
	
	# 1. Cerchiamo se l'utente è già presente nella lista locale
	for i in range(times.size()):
		if str(times[i]["username"]).to_lower() == current_username:
			# Trovato! Aggiorniamo i suoi dati locali
			times[i]["shots"] = int(GameManager.shots)
			times[i]["time"] = float(GameManager.winTime)
			user_found_locally = true
			break
	
	# 2. Se non c'era (nuovo record), lo aggiungiamo noi manualmente
	if not user_found_locally:
		var new_entry = {
			"username": GameManager.username,
			"shots": int(GameManager.shots),
			"time": float(GameManager.winTime),
			"levelNumber": current_level,
			"doc_id": "temp_id" # Non serve l'ID reale per l'ordinamento locale
		}
		times.append(new_entry)
	
	# 3. Chiediamo all'arbitro di rimettere tutto in ordine dopo la modifica
	times.sort_custom(sort_leaderboard)
	
	# 4. Troviamo la nuova posizione (filtrando per livello)
	var posizione = 1
	for t in times:
		# Guardiamo solo i record del livello attuale
		if int(t.get("levelNumber", -1)) == current_level:
			if str(t["username"]).to_lower() == current_username:
				return posizione # Ecco la tua posizione!
			posizione += 1
			
	return posizione
	
func check_position() -> int:
	var records = GameManager.level_online_times
	
	for i in range(records.size()):
		if records[i]["username"].to_lower() == current_username_to_lower:
			return i + 1
	
	return -1

func update_existing_time(doc_id: String):
	var collectionid = "times"
	var collection: FirestoreCollection = Firebase.Firestore.collection(collectionid)
	# Aggiorniamo solo colpi e tempo. Username e livello sono già giusti.
	var new_data: Dictionary = {
		"shots": int(GameManager.shots),
		"time": float(GameManager.winTime)
	}
	
	task = collection.update(doc_id, new_data)
	
	if task == null: return
	
	task.task_finished.connect(update_time_finished)

func update_time_finished(_task: FirestoreTask):
	if _task._response_code == 200 or _task._response_code == 0:
		var position = update_local_and_get_position()
		Signals.task_succeeded.emit \
		("Hai battuto il tuo record, " + current_username_to_lower \
		 + "! La tua posizione attuale e' " + str(position))
	else:
		printerr("Errore aggiornamento. Codice: ", _task._response_code)
		Signals.task_failed.emit()


func sort_leaderboard(a: Dictionary, b: Dictionary) -> bool:
	# Usiamo .get() con un valore altissimo di default nel caso 
	# scaricasse vecchi salvataggi che non avevano la voce "shots"
	var tiri_a = int(a.get("shots", 999)) 
	var tiri_b = int(b.get("shots", 999))

	if tiri_a != tiri_b:
		return tiri_a < tiri_b
		
	var tempo_a = float(a.get("time", 999.0))
	var tempo_b = float(b.get("time", 999.0))
	return tempo_a < tempo_b

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
