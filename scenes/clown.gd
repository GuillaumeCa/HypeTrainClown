extends Sprite2D

class_name Clown

var pseudo = ""
var color = "#f50000"

func _ready():
	$Label.text = pseudo
	$Label.set("theme_override_colors/font_color", Color(color))
	$ClownHair.modulate = Color(color)
	animate()


func animate():
	var tw = create_tween().parallel()
	tw.tween_property(self, "position:y", -4.0, 0.5)
	tw.tween_property($Label, "modulate:a", 1.0, 0.1)
	
	tw.chain().tween_property(self, "position:y", 0.0, 0.5)
	tw.tween_property($Label, "modulate:a", 0.0, 0.5)


func _on_timer_timeout():
	animate()
