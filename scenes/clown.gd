extends Sprite2D

class_name Clown

var pseudo = ""

var default_color = "#f50000"
var color = ""

var jump_height = 12.0

func _ready():
	$Label.text = pseudo
	
	if color == "":
		color = default_color
	
	var text_color = "#ffffff" if color == default_color else color
	$Label.set("theme_override_colors/font_color", Color(text_color))
	
	$ClownHair.modulate = Color(color)
	
	
	animate()


func animate():
	var tw = create_tween().parallel().set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "position:y", -jump_height, 0.5)
	tw.tween_property($Label, "modulate:a", 1.0, 0.1)
	
	tw.chain().tween_property(self, "position:y", 0.0, 0.5)
	tw.tween_property($Label, "modulate:a", 0.0, 0.5).set_ease(Tween.EASE_OUT)


func _on_timer_timeout():
	animate()
