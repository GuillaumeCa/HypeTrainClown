extends Node

var config_filename = "user://config.cfg"
var config

func _ready():
	print("init config")
	init_config()

func init_config():
	if FileAccess.file_exists(config_filename):
		config = load_config()
		print(config)
	else:
		var cfg = {
			"username": "",
			"train_scale": 1.0
		}
		save_config(cfg)
		config = cfg

func save_config(cfg: Dictionary):
	var f = FileAccess.open(config_filename, FileAccess.WRITE)
	f.store_string(JSON.stringify(cfg))

func load_config() -> Dictionary:
	var f = FileAccess.open(config_filename, FileAccess.READ)
	var txt = f.get_as_text()
	return JSON.parse_string(txt)
