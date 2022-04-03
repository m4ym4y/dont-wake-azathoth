extends Node

var high_score = 0
var score = 0

var non_number_regex

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	non_number_regex = RegEx.new()
	non_number_regex.compile('[^0-9]')
	if OS.get_name() == "HTML5":
		print("loading high score")
		var saved = JavaScript.eval("localStorage.getItem('azathoth_high_score')")
		print("saved value: ", saved)
		high_score = int(saved if saved else "0")

func set_high_score(_score):
	if _score > high_score:
		if OS.get_name() == "HTML5" and not non_number_regex.search(str(_score)):
			JavaScript.eval("localStorage.setItem('azathoth_high_score', '" + str(_score) + "')")
		high_score = _score

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
