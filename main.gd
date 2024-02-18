extends Node2D

class_name Main

const HYPE_TRAIN_BEGIN_EVENT = "channel.hype_train.begin"
const HYPE_TRAIN_END_EVENT = "channel.hype_train.end"
const SUBSCRIBE_EVENT = "channel.subscribe"
const RESUBSCRIBE_EVENT = "channel.subscription.message"

@onready var train_path = $TrainPath

@export var wagon_scene: PackedScene
@export var client_id = "bgqfa37gk9hm8rqrd12afpmzrzf2yo"
@export var username = ""

var id: TwitchIDConnection
var api: TwitchAPIConnection
var eventsub: TwitchEventSubConnection



# to start the debug server with twitch cli: twitch event websocket start-server
#const url = "wss://eventsub.wss.twitch.tv/ws?keepalive_timeout_seconds=30"
const url = "ws://127.0.0.1:8080/ws"
var train_offset = 75
var train_init_voffset = 15.0
var speed = 30.0

static var train_scale = 1.0

var current_speed = 0.0

var hype_mode = false
var wagons = []
var subs = {}

var config


# Called when the node enters the scene tree for the first time.
func _ready():
	config = Config.config
	#ProjectSettings.set("rendering/viewport/transparent_background", true)
	#ProjectSettings.set("application/boot_splash/bg_color", Color(0, 0, 0, 0))
	#ProjectSettings.set("display/window/size/transparent", true)
	#RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	#get_tree().root.borderless = true
	
	if not OS.is_debug_build():
		get_tree().root.mode = Window.MODE_FULLSCREEN
		setup_twitch_connection()
	else:
		$DebugWebSocketClient.connect_to_url(url)
	
	wagons = train_path.get_children()
	
	wagons[0].v_offset = train_init_voffset * train_scale

func setup_twitch_connection():
	
	# We will login using the Implicit Grant Flow, which only requires a client_id.
	# Alternatively, you can use the Authorization Code Grant Flow or the Client Credentials Grant Flow.
	# Note that the Client Credentials Grant Flow will only return an AppAccessToken, which can not be used
	# for the majority of the Twitch API or to join a chat room.
	var auth : ImplicitGrantFlow = ImplicitGrantFlow.new()
	# For the auth to work, we need to poll it regularly.
	get_tree().process_frame.connect(auth.poll) # You can also use a timer if you don't want to poll on every frame.

	# Next, we actually get our token to authenticate. We want to be able to read and write messages,
	# so we request the required scopes. See https://dev.twitch.tv/docs/authentication/scopes/#twitch-access-token-scopes
	var token : UserAccessToken = await(auth.login(client_id, [
		"channel:read:hype_train",
		"channel:read:subscriptions",
	]))
	
	if (token == null):
		# Authentication failed. Abort.
		return

	# Store the token in the ID connection, create all other connections.
	id = TwitchIDConnection.new(token)
	api = TwitchAPIConnection.new(id)
	eventsub = TwitchEventSubConnection.new(api)
	# For everything to work, the id connection has to be polled regularly.
	get_tree().process_frame.connect(id.poll)
	
	await(eventsub.connect_to_eventsub())
	eventsub.event.connect(handle_events)
	
	var user_ids : Dictionary = await(api.get_users_by_name([username]))
	if (user_ids.has("data") && user_ids["data"].size() > 0):
		var user_id : String = user_ids["data"][0]["id"]
		print("Found user '%s' with id: %s" % [username, user_id])
		eventsub.subscribe_event(HYPE_TRAIN_BEGIN_EVENT, "1", {"broadcaster_user_id": user_id})
		eventsub.subscribe_event(HYPE_TRAIN_END_EVENT, "1", {"broadcaster_user_id": user_id})
		eventsub.subscribe_event(SUBSCRIBE_EVENT, "1", {"broadcaster_user_id": user_id})
		eventsub.subscribe_event(RESUBSCRIBE_EVENT, "1", {"broadcaster_user_id": user_id})


func _process(delta):
	for path: PathFollow2D in wagons:
		path.scale = Vector2(train_scale, train_scale)
		if hype_mode:
			current_speed = lerp(current_speed, speed, 0.05)
			path.v_offset = lerp(path.v_offset, 0.0, 0.07)
		else:
			current_speed = lerp(current_speed, 0.0, 0.05)
			path.v_offset = lerp(path.v_offset, train_init_voffset * train_scale, 0.07)

		path.progress = path.progress + current_speed * delta
		path.modulate.a = lerp(path.modulate.a, 1.0 if hype_mode else 0.0, 0.2)

	$Track.width = 20 * train_scale
	
	if Input.is_action_just_pressed("show_ui"):
		var ui: Control = $CanvasLayer/UI
		if ui.visible:
			ui.hide()
		else:
			ui.show()
	
	if Input.is_action_just_pressed("quit"):
		get_tree().quit()
	

func on_session_received():
	print("session received")
	

func handle_events(type: String, event_data: Dictionary) -> void:
	print(type, event_data)
	match type:
		HYPE_TRAIN_BEGIN_EVENT:
			hype_mode = true
		HYPE_TRAIN_END_EVENT:
			hype_mode = false
			var t = get_tree().create_timer(1)
			await t.timeout
			reset_train()
		SUBSCRIBE_EVENT: handle_sub(event_data)
		RESUBSCRIBE_EVENT: handle_sub(event_data)

func handle_sub(event):
	var user = event["user_name"]
	var login = event["user_login"]
	
	# if user is already on the train don't add it again
	#if login in subs:
		#return
	subs[login] = 1
	prints("user", user, "just subbed !")
	
	var wagon_idx = 0
	while wagon_idx < wagons.size():
		var wagon: Wagon = wagons[wagon_idx]
		if not wagon.is_full():
			wagon.add_clown(user)
			return
		wagon_idx += 1
	
	var new_wagon = wagon_scene.instantiate() as Wagon
	new_wagon.progress = wagons[wagon_idx-1].progress - (train_offset * train_scale)
	new_wagon.v_offset = train_init_voffset * train_scale
	train_path.add_child(new_wagon)
	new_wagon.add_clown(user)
	wagons = train_path.get_children()

func _on_web_socket_client_data_received(peer, message: PackedByteArray, is_string):
	var parsed = JSON.parse_string(message.get_string_from_utf8())
	#prints("ws message:", parsed)
	var message_type = parsed["metadata"]["message_type"]
	prints("msg type:", message_type)
	if message_type == "notification":
		var payload = parsed["payload"]
		var sub_type = payload["subscription"]["type"]
		
		if sub_type == "channel.hype_train.begin":
			hype_mode = true
		if sub_type == "channel.hype_train.end":
			hype_mode = false
			var t = get_tree().create_timer(1)
			await t.timeout
			reset_train()
			
		if sub_type == "channel.subscribe":
			handle_sub(payload["event"])
	
func reset_train():
	for idx in wagons.size():
		wagons[idx].queue_free()
	wagons.clear()
	
	var new_wagon = wagon_scene.instantiate()
	new_wagon.progress = 100
	new_wagon.v_offset = train_init_voffset * train_scale
	train_path.add_child(new_wagon)
	wagons.append(new_wagon)

