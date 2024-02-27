extends Node2D

class_name Main

@export var client_id = "bgqfa37gk9hm8rqrd12afpmzrzf2yo"
@onready var ui = $CanvasLayer/UI

var id: TwitchIDConnection
var api: TwitchAPIConnection
var eventsub: TwitchEventSubConnection

var overlay_window_scene = preload("res://scenes/overlay_window.tscn")


# to start the debug server with twitch cli: twitch event websocket start-server
#const url = "wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30"
const DEBUG_WS_URL = "ws://127.0.0.1:8080/ws"

var config
var username = ""

var window

var debug = false

func _ready():
	config = Master.config
	username = config["username"]
	
	# size of the config window
	#get_window().size = Vector2i(900, 400)

	if debug or !OS.is_debug_build():
		if username:
			setup_twitch_connection()
	else:
		$DebugWebSocketClient.connect_to_url(DEBUG_WS_URL)
	

func setup_twitch_connection():
	ui.add_log("Connexion à twitch en cours...")
	# We will login using the Implicit Grant Flow, which only requires a client_id.
	# Alternatively, you can use the Authorization Code Grant Flow or the Client Credentials Grant Flow.
	# Note that the Client Credentials Grant Flow will only return an AppAccessToken, which can not be used
	# for the majority of the Twitch API or to join a chat room.
	var auth : ImplicitGrantFlow = ImplicitGrantFlow.new()
	# For the auth to work, we need to poll it regularly.
	get_tree().process_frame.connect(auth.poll) # You can also use a timer if you don't want to poll on every frame.

	# Next, we actually get our token to authenticate. 
	# See https://dev.twitch.tv/docs/authentication/scopes/#twitch-access-token-scopes
	var token : UserAccessToken = await(auth.login(client_id, [
		"channel:read:hype_train",
		#"channel:read:subscriptions",
		"user:read:chat"
	]))
	
	if (token == null):
		# Authentication failed. Abort.
		ui.add_log("L'authentification a échoué.")
		return

	# Store the token in the ID connection, create all other connections.
	id = TwitchIDConnection.new(token)
	api = TwitchAPIConnection.new(id)
	eventsub = TwitchEventSubConnection.new(api)
	# For everything to work, the id connection has to be polled regularly.
	get_tree().process_frame.connect(id.poll)
	
	ui.add_log("Connexion aux évenements twitch...")
	await(eventsub.connect_to_eventsub())
	eventsub.event.connect(Master.send_event)
	ui.add_log("Connexion réussi !")
	
	var user_ids : Dictionary = await(api.get_users_by_name([username]))
	if (user_ids.has("data") && user_ids["data"].size() > 0):
		var user_id : String = user_ids["data"][0]["id"]
		print("Found user '%s' with id: %s" % [username, user_id])
		ui.add_log("Utilisateur '%s' trouvé avec l'id: %s" % [username, user_id])
		
		subscribe_event(Master.HYPE_TRAIN_BEGIN_EVENT, user_id)
		subscribe_event(Master.HYPE_TRAIN_PROGRESS_EVENT, user_id)
		subscribe_event(Master.HYPE_TRAIN_END_EVENT, user_id)
		subscribe_event(Master.CHAT_NOTIFICATION_EVENT, user_id, user_id)
		
		#subscribe_event(Master.SUBSCRIBE_EVENT, user_id)
		#subscribe_event(Master.RESUBSCRIBE_EVENT, user_id)
	else:
		ui.add_log("Utilisateur non trouvé")

func subscribe_event(type, broadcaster_user_id, user_id = null):
	var condition = {"broadcaster_user_id": broadcaster_user_id}
	if user_id:
		condition["user_id"] = str(user_id)
		
	print(condition)
	var sub = await eventsub.subscribe_event(type, "1", condition)
	if sub == -1:
		ui.add_log("Impossible de se connecter à l'évenement: " + type)
	else:
		ui.add_log("Connexion à l'évenement " + type + " réussie")


func on_session_received():
	print("session received")



func _on_web_socket_client_data_received(peer, message: PackedByteArray, is_string):
	var parsed = JSON.parse_string(message.get_string_from_utf8())
	#prints("ws message:", parsed)
	var message_type = parsed["metadata"]["message_type"]
	prints("msg type:", message_type)
	if message_type == "notification":
		var payload = parsed["payload"]
		var sub_type = payload["subscription"]["type"]
		
		if sub_type == "channel.hype_train.begin":
			Master.send_event(sub_type, {})
		if sub_type == "channel.hype_train.end":
			Master.send_event(sub_type, {})
		if sub_type == "channel.subscribe":
			Master.send_event(sub_type, payload["event"])



func _on_ui_open_overlay():
	if window:
		ui.toggle_open_overlay(true)
		window.queue_free()
		window = null
		return
	
	window = overlay_window_scene.instantiate() as Window
	window.close_requested.connect(on_close.bind(window))
	var size = DisplayServer.screen_get_size(DisplayServer.get_primary_screen())
	window.size = size
	
	ui.toggle_open_overlay(false)
	add_child(window)
	
	
func on_close(window):
	ui.toggle_open_overlay(true)
	window.queue_free()


func _on_ui_update_username():
	username = config["username"]
	if not OS.is_debug_build() and username:
		setup_twitch_connection()
