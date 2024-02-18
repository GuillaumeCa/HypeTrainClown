extends Control

func _ready():
	$Panel/Margin/VBox/HBoxInput/UsernameInput.text = Config.config["username"]

func _on_sub_pressed():
	call_deferred("call_twitch", "channel.subscribe")

func _on_hype_end_pressed():
	call_deferred("call_twitch", "channel.hype_train.end")

func _on_hype_start_pressed():
	call_deferred("call_twitch", "channel.hype_train.begin")

func call_twitch(event):
	var r = OS.execute("twitch", ["event", "trigger", event, "--transport=websocket"])


func _on_h_slider_value_changed(value):
	Main.train_scale = value


func _on_validate_pressed():
	var username = $Panel/Margin/VBox/HBoxInput/UsernameInput.text
	Config.save_config({ "username": username })
	hide()
