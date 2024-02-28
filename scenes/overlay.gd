extends Node2D


@export var wagon_scene: PackedScene

@onready var train_path = $TrainPath
@onready var config = Master.config

var train_offset = 75
var train_init_voffset = 15.0
var speed = 30.0

var train_scale = 1.0:
	get:
		return config["train_scale"]

var current_speed = 0.0

var hype_mode = false
var wagons = []
var subs = {}

func _ready():
	wagons = train_path.get_children()
	
	wagons[0].v_offset = train_init_voffset * train_scale
	
	Master.events.connect(handle_events)
	

func handle_events(type: String, data: Dictionary):
	prints("got event in window", type, data)
	match type:
		Master.HYPE_TRAIN_BEGIN_EVENT:
			hype_mode = true
		Master.HYPE_TRAIN_PROGRESS_EVENT:
			hype_mode = true
		Master.HYPE_TRAIN_END_EVENT:
			hype_mode = false
			var t = get_tree().create_timer(1)
			await t.timeout
			reset_train()
		#Master.SUBSCRIBE_EVENT, Master.RESUBSCRIBE_EVENT: handle_sub(data)
		Master.CHAT_NOTIFICATION_EVENT:
			handle_chat_notif(data)


func handle_chat_notif(data):
	var notice_type = data["notice_type"]
	match(notice_type):
		"sub": add_user(data["chatter_user_name"], data["chatter_user_login"], data["color"])
		"subgift":
			add_user(data["chatter_user_name"], data["chatter_user_login"], data["color"])
			add_user(data["recipient_user_name"], data["recipient_user_login"])
		"resub":
			if data[notice_type]["is_gift"] and !data[notice_type]["gifter_is_anonymous"]:
				add_user(data[notice_type]["gifter_user_name"], data[notice_type]["gifter_user_login"])
			add_user(data["chatter_user_name"], data["chatter_user_login"], data["color"])
		"community_sub_gift", "prime_paid_upgrade":
			add_user(data["chatter_user_name"], data["chatter_user_login"], data["color"])
		"gift_paid_upgrade", "pay_it_forward":
			if !data[notice_type]["gifter_is_anonymous"]:
				add_user(data[notice_type]["gifter_user_name"], data[notice_type]["gifter_user_login"])
			add_user(data["chatter_user_name"], data["chatter_user_login"], data["color"])


func add_user(username, login, color = ""):
	
	# if user is already on the train don't add it again
	if login in subs:
		return
	subs[login] = 1
	prints("user", username, "just subbed !")
	
	var wagon_idx = 0
	while wagon_idx < wagons.size():
		var wagon: Wagon = wagons[wagon_idx]
		if not wagon.is_full():
			wagon.add_clown(username, color)
			return
		wagon_idx += 1
	
	var new_wagon = wagon_scene.instantiate() as Wagon
	new_wagon.progress = wagons[wagon_idx-1].progress - (train_offset * train_scale)
	new_wagon.v_offset = train_init_voffset * train_scale
	train_path.add_child(new_wagon)
	new_wagon.add_clown(username, color)
	wagons = train_path.get_children()

func reset_train():
	for idx in wagons.size():
		wagons[idx].queue_free()
	wagons.clear()
	
	var new_wagon = wagon_scene.instantiate()
	new_wagon.progress = 100
	new_wagon.v_offset = train_init_voffset * train_scale
	train_path.add_child(new_wagon)
	wagons.append(new_wagon)

func _process(delta):
	var i = 0
	var prev_progress = 0
	for path: PathFollow2D in wagons:
		path.scale = Vector2(train_scale, train_scale)
		if hype_mode:
			current_speed = lerp(current_speed, speed, 0.05)
			path.v_offset = lerp(path.v_offset, 0.0, 0.07)
		else:
			current_speed = lerp(current_speed, 0.0, 0.05)
			path.v_offset = lerp(path.v_offset, train_init_voffset * train_scale, 0.07)
		if i > 0:
			path.progress = prev_progress - (train_offset * train_scale)
		path.progress = path.progress + current_speed * delta
		path.modulate.a = lerp(path.modulate.a, 1.0 if hype_mode else 0.0, 0.2)
		
		
		prev_progress = path.progress
		i += 1

	$Track.width = 20 * train_scale
