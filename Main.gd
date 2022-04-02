extends Node2D

export (PackedScene) var note_scene
export (PackedScene) var indicator_scene

var locations = [ "hline", "jline", "kline", "lline" ]
var neighbor_note = {
	hline = "jline",
	jline = "kline",
	kline = "lline",
	lline = "hline",
}
const base_note_speed = 120.0

const note_size = 16.0
const note_step = 33.0
const target_start = 393.0
const target_end = 434.0

var states = [ "single", "alter", "scale", "double"]
var state
var state_counter = 0
var primary_note

var broke_combo = false
var got_combo = false
var combo_counter = 0
var max_health = 100
var health = 100

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	yield(get_tree().create_timer(0.4), "timeout")
	$NoteTimer.start()

func random_note():
	return locations[randi() % locations.size()]

func set_new_state():
	state = states[randi() % states.size()]
	if state == "single":
		primary_note = random_note()
		state_counter = 2 + randi() % 4
	elif state == "alter":
		primary_note = random_note()
		state_counter = 2 + (randi() % 2) * 2
	elif state == "scale":
		primary_note = random_note()
		state_counter = 4 + randi() % 6
	elif state == "double":
		primary_note = random_note()
		state_counter = 1 + randi() % 2

func next_notes():
	if state_counter == 0:
		set_new_state()
	state_counter -= 1
	if state == "single":
		return [ primary_note ]
	elif state == "alter":
		return [ primary_note if state_counter % 2 == 0 else neighbor_note[primary_note] ]
	elif state == "scale":
		primary_note = neighbor_note[primary_note]
		return [ primary_note ]
	elif state == "double":
		return [ primary_note, neighbor_note[primary_note] ]

func increment_combo():
	if broke_combo:
		combo_counter = 0
	elif got_combo:
		combo_counter += 1
	broke_combo = false
	got_combo = false
	$ComboMeter.text = str(combo_counter)

func set_health(n):
	health = n
	$Health.text = str(health) + "%"

func _on_NoteTimer_timeout():
	advance_notes()
	increment_combo()
	set_health(min(health + 1, max_health))

	var lines = next_notes()
	for line in lines:
		var note = note_scene.instance()
		note.add_to_group(line)
		note.add_to_group("notes")
		note.position = get_node(line).position
		note.get_node("AnimatedSprite").play(line)
		add_child(note)

func miss_note():
	set_health(health - 10)
	$MissSound.play()
	pass

func advance_notes():
	var notes = get_tree().get_nodes_in_group("notes")
	for note in notes:
		note.position.y = note.position.y + note_step
		if note.position.y > target_end and note.get_node("AnimatedSprite").animation != "break":
			note.get_node("AnimatedSprite").play("break")
			broke_combo = true
			miss_note()

func _input(event):
	for line in locations:
		if event.is_action_pressed(line):
			$Sounds.get_node(line).play()
			var found_note = false
			var notes = get_tree().get_nodes_in_group(line)

			for note in notes:
				if note.position.y > target_start and note.position.y < target_end:
					note.get_node("AnimatedSprite").play("break")
					found_note = true

			if found_note:
				display_indicator("perfect", line)
				got_combo = true
			else:
				broke_combo = true
				display_indicator("miss", line)
				miss_note()

func display_indicator(state, line, offset = 0):
	var indicator = indicator_scene.instance()
	
	indicator.animation = state
	indicator.position = Vector2(get_node(line).position.x, (target_start + target_end) / 2.0 + offset)

	add_child(indicator)
	yield(get_tree().create_timer(0.5), "timeout")
	indicator.queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
