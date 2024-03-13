extends Control

@onready var config = Master.config
@onready var open_overlay_btn = $Panel/Margin/VBox/OpenOverlay


signal open_overlay
signal connect_user(connect)


var demo_users = ["Ddurieux", "StazHopper", "Balokuclem", "Dguillaume"]


var is_loading = false
var user_connected = false

func _ready():
	$Panel/Margin/VBox/HBoxInput/UsernameInput.text = config["username"]
	update_scale(config["train_scale"])
	

	if not OS.is_debug_build():
		$Panel/Margin/VBox/debug.hide()
		
	Master.events.connect(handle_events)


func _process(delta):
	$Panel/Margin/VBox/HBoxInput/UsernameInput.editable = !is_loading and !user_connected
	$Panel/Margin/VBox/HBoxInput/Validate.text = "Deconnexion" if user_connected else "Connexion"

func _on_sub_pressed():
	call_deferred("call_twitch", "channel.subscribe")

func _on_hype_end_pressed():
	call_deferred("call_twitch", "channel.hype_train.end")

func _on_hype_start_pressed():
	call_deferred("call_twitch", "channel.hype_train.begin")

func call_twitch(event):
	var r = OS.execute("twitch", ["event", "trigger", event, "--transport=websocket"])


func _on_h_slider_value_changed(value):
	config["train_scale"] = value
	update_scale(value)
	Master.save_config(config)


func update_scale(new_scale):
	$Panel/Margin/VBox/HBoxContainer/ScaleLabel.text = str(new_scale) + "x"
	$Panel/Margin/VBox/HBoxContainer/ScaleSlider.value = new_scale

func _on_validate_pressed():
	var username = $Panel/Margin/VBox/HBoxInput/UsernameInput.text
	config["username"] = username
	Master.save_config(config)
	user_connected = !user_connected
	connect_user.emit(user_connected)


func _on_open_overlay_pressed():
	open_overlay.emit()
	
func toggle_open_overlay(open: bool):
	open_overlay_btn.text = "Ouvrir overlay" if open else "Fermer overlay"

func add_log(text: String):
	$Panel/Margin/VBox/Logs.text += text + "\n"

func handle_events(type: String, data: Dictionary):
	match type:
		Master.HYPE_TRAIN_BEGIN_EVENT:
			add_log("Le train de la hype a démarré")
		Master.HYPE_TRAIN_PROGRESS_EVENT:
			add_log("Le train de la hype a progressé. niveau=" + str(data["level"]) + " progress=" + str(data["progress"]))
		Master.HYPE_TRAIN_END_EVENT:
			add_log("Le train de la hype est terminé")
		Master.CHAT_NOTIFICATION_EVENT:
			add_log("Nouvelle notification du chat: " + data["notice_type"])
			prints("chat notification:", type, data)
		#Master.SUBSCRIBE_EVENT, Master.RESUBSCRIBE_EVENT:
			#add_log("Nouveau sub: " + data["user_name"])


func _on_demo_start_pressed():
	Master.send_event(Master.HYPE_TRAIN_BEGIN_EVENT, {})

func _on_demo_sub_pressed():
	var user = demo_users[randi() % demo_users.size()] + str(randi_range(0, 100))
	Master.send_event(Master.CHAT_NOTIFICATION_EVENT, { "notice_type": "sub", "chatter_user_name": user, "chatter_user_login": user, "color": "" })


func _on_demo_end_pressed():
	Master.send_event(Master.HYPE_TRAIN_END_EVENT, {})
