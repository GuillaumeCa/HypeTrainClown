extends Control

@onready var config = Config.config


func _ready():
	$Panel/Margin/VBox/HBoxInput/UsernameInput.text = config["username"]
	$Panel/Margin/VBox/HSlider.value = config["train_scale"]

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
	Config.save_config(config)


func _on_validate_pressed():
	var username = $Panel/Margin/VBox/HBoxInput/UsernameInput.text
	var config = Config.config
	config["username"] = username
	Config.save_config(config)
	hide()
