extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var PlayerVars = get_node("/root/PlayerVars")
	$HighScore.text = str(PlayerVars.high_score)
	pass # Replace with function body.

func _input(event):
	if event.is_action_pressed("attack"):
		get_tree().change_scene("res://InstructionScene.tscn")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
