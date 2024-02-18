extends PathFollow2D

class_name Wagon

var offset = 8
var max_clown = 7
@export var clown_scene: PackedScene

@onready var start = $Start

var clowns_count = 0

func is_full():
	return clowns_count == max_clown

func add_clown(clown_name: String):
	var clown = clown_scene.instantiate() as Clown
	clown.pseudo = clown_name
	clown.position = Vector2(clowns_count * -offset, 0)
	start.add_child(clown)
	clowns_count += 1
