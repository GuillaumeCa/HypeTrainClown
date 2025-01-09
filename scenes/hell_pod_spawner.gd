extends Node2D

@export var hellpod_scn: PackedScene
@onready var raid_sound = $RaidSound


func spawn(username: String, count: int):
	raid_sound.play()
	var leader_pod = spawn_pod(username, count)
	
	for i in count - 1:
		prints("spawning:", i)
		spawn_pod()
		await get_tree().create_timer(randf_range(0.05, 0.1) * 300/count).timeout
	
	await get_tree().create_timer(10).timeout
	leader_pod.queue_free()


func spawn_pod(user_name: String = "", count = 0) -> Node2D:
	var instance = hellpod_scn.instantiate() as Node2D
	
	instance.position = Vector2(randf_range(0, 1600), -54)
	
	if user_name != "":
		instance.user_name = user_name
		instance.position = Vector2(800, -54)
		instance.z_index = 1
		instance.pod_count = count
	
	instance.rotation = deg_to_rad(-15)
	add_child(instance)
	
	return instance
