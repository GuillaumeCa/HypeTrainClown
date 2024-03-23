extends Node

const HYPE_TRAIN_BEGIN_EVENT = "channel.hype_train.begin"
const HYPE_TRAIN_PROGRESS_EVENT = "channel.hype_train.progress"
const HYPE_TRAIN_END_EVENT = "channel.hype_train.end"
const SUBSCRIBE_EVENT = "channel.subscribe"
const RESUBSCRIBE_EVENT = "channel.subscription.message"
const CHAT_NOTIFICATION_EVENT = "channel.chat.notification"

var config_filename = "user://config.cfg"
var config

var config_version = "1.0"

const default_config = {
	"username": "",
	"train_scale": 1.0,
	"auth": null,
	"enable_raid": false
}

signal events(type, data)

func _ready():
	print("init config")
	init_config()

func init_config():
	if FileAccess.file_exists(config_filename):
		config = load_config()
	else:
		var cfg = default_config.duplicate()
		cfg["v"] = config_version
		save_config(cfg)
		config = cfg

func save_config(cfg: Dictionary):
	var f = FileAccess.open(config_filename, FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))
	return cfg

func load_config() -> Dictionary:
	var f = FileAccess.open(config_filename, FileAccess.READ)
	var txt = f.get_as_text()
	var data = JSON.parse_string(txt)
	
	if !("v" in data) or data["v"] != config_version:
		var cfg = default_config.duplicate()
		cfg["v"] = config_version
		return save_config(cfg)
	
	if not "enable_raid" in data:
		data["enable_raid"] = false
	
	save_config(data)
	
	return data


func send_event(type: String, data: Dictionary):
	events.emit(type, data)
