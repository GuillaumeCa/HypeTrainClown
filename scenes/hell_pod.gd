extends Area2D

@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var despawn_timer: Timer = $DespawnTimer

var speed = 120

var user_name = ""

var colors = [
  "#FF0000", # Red
  "#FF7F00", # Orange
  "#FFFF00", # Yellow
  "#00FF00", # Lime
  "#00FFFF", # Cyan
  "#0000FF", # Blue
  "#8A2BE2", # Blue Violet
  "#FF00FF", # Magenta
  "#FF1493", # Deep Pink
  "#FFD700", # Gold
  "#32CD32", # Lime Green
  "#FF6347", # Tomato
  "#7CFC00", # Lawn Green
  "#FF4500", # Orange Red
  "#00FF7F", # Spring Green
  "#40E0D0", # Turquoise
  "#9400D3", # Dark Violet
  "#DC143C", # Crimson
  "#00CED1", # Dark Turquoise
  "#FF69B4", # Hot Pink
  "#00BFFF", # Deep Sky Blue
  "#6A5ACD", # Slate Blue
  "#FA8072", # Salmon
  "#20B2AA", # Light Sea Green
  "#FF8C00", # Dark Orange
  "#00FA9A", # Medium Spring Green
  "#9932CC", # Dark Orchid
  "#ADFF2F", # Green Yellow
  "#1E90FF"  # Dodger Blue
]

func _ready() -> void:
	$Label.hide()
	if user_name != "":
		$Label.show()
		$Label.text = user_name
	$ClownHair.modulate = Color(colors.pick_random())
	
	speed += randi_range(-20, 20)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += transform.y * speed * delta


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("floor"):
		gpu_particles_2d.emitting = false
		speed = 0
		if user_name == "":
			despawn_timer.start()


func _on_despawn_timer_timeout() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	await tw.finished
	queue_free()
