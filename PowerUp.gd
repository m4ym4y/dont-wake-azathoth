extends AnimatedSprite


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var type = ""

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func init(_type):
	type = _type
	animation = _type

func _on_VisibilityNotifier2D_screen_exited():
	queue_free()
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
