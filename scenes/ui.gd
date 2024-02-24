extends Control

@onready var config = Master.config
@onready var open_overlay_btn = $Panel/Margin/VBox/OpenOverlay


signal open_overlay
signal update_username


func _ready():
	$Panel/Margin/VBox/HBoxInput/UsernameInput.text = config["username"]
	$Panel/Margin/VBox/HBoxContainer/HSlider.value = config["train_scale"]
	update_scale_label(config["train_scale"])

	if not OS.is_debug_build():
		$Panel/Margin/VBox/debug.hide()
		
	Master.events.connect(handle_events)

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
	update_scale_label(value)
	Master.save_config(config)


func update_scale_label(scale):
	$Panel/Margin/VBox/HBoxContainer/ScaleLabel.text = str(scale) + "x"

func _on_validate_pressed():
	var username = $Panel/Margin/VBox/HBoxInput/UsernameInput.text
	var config = Master.config
	config["username"] = username
	Master.save_config(config)
	update_username.emit()


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
		Master.HYPE_TRAIN_END_EVENT:
			add_log("Le train de la hype est terminé")
		Master.SUBSCRIBE_EVENT:
			add_log("Nouveau sub: " + data["user_name"])
		Master.RESUBSCRIBE_EVENT:
			add_log("Nouveau sub: " + data["user_name"])
			
