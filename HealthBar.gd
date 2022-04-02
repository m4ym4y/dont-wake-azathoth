extends Node2D

export (PackedScene) var heart_scene

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var heart_width = 16
var padding = 8
var max_width = 5

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func set_health(health):
	var hearts = get_tree().get_nodes_in_group("heart")
	for heart in hearts:
		heart.queue_free()

	for i in range(0, health, 1):
		var heart = heart_scene.instance()
		heart.add_to_group("heart")
		heart.position.x = (i % max_width) * (heart_width + padding)
		heart.position.y = (i / 5) * (heart_width + padding)
		add_child(heart)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
