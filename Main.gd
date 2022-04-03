extends Node2D

export (PackedScene) var note_scene
export (PackedScene) var indicator_scene
export (PackedScene) var powerup_scene

var powerups = [ "clock", "flute", "z" ]
var locations = [ "hline", "jline", "kline", "lline" ]
var neighbor_note = {
	hline = "jline",
	jline = "kline",
	kline = "lline",
	lline = "hline",
}
const base_note_speed = 120.0
const base_wait_time = 0.8

const note_size = 16.0
const note_step = 32.0
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
var health = 10

var global_timer = 0
var timer = 0
var pitch_scale = 1.0

var PlayerVars

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()

	PlayerVars = get_node("/root/PlayerVars")
	PlayerVars.get_node("Music").stop()
	$HighScoreMeter.text = str(PlayerVars.high_score)

	yield(get_tree().create_timer(0.4), "timeout")
	$NoteTimer.start()
	set_health(health)

func random_note():
	return locations[randi() % locations.size()]

func set_new_state():
	if randi() % 10 == 0:
		state_counter = 1
		state = "powerup"
	else:
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
	elif state == "powerup":
		spawn_powerup()
		return []

func increment_combo():
	if broke_combo:
		combo_counter = 0
		get_node("Sounds/perfect").pitch_scale = 1
	elif got_combo:
		combo_counter += 1
		if combo_counter % 20 == 0 and get_node("Sounds/perfect").pitch_scale < 2.0:
			get_node("Sounds/perfect").pitch_scale += 0.2
	broke_combo = false
	got_combo = false
	$ComboMeter.text = str(combo_counter)

func set_health(n):
	health = n
	if health <= 0:
		PlayerVars.set_high_score(PlayerVars.score)
		get_tree().change_scene("res://GameOver.tscn")
	else:
		$HealthBar.set_health(n)

func apply_pitch_scale ():
	$NoteTimer.wait_time = base_wait_time / pitch_scale
	$Music.pitch_scale = pitch_scale

func _on_Music_finished():
	if timer > 50:
		timer = 0
		pitch_scale += 0.1
		apply_pitch_scale()
	$Music.play()

func spawn_powerup():
	var type = powerups[randi() % powerups.size()]
	var line = random_note()
	var powerup = powerup_scene.instance()

	powerup.add_to_group("notes")
	powerup.add_to_group("attack")
	powerup.position = get_node(line).position
	powerup.init(type)
	add_child(powerup)

func increment_score(bonus = 0):
	PlayerVars.score += 1 + bonus
	$ScoreMeter.text = str(PlayerVars.score)

func _on_NoteTimer_timeout():
	global_timer += 1
	timer += 1

	if global_timer % 2 == 1:
		$Cultist.play("on")
		$Azathoth.play("on")
	else:
		$Cultist.play("off")
		$Azathoth.play("off")

	advance_notes()
	increment_combo()
	# set_health(min(health + 1, max_health))

	var lines = next_notes()
	for line in lines:
		var note = note_scene.instance()
		note.add_to_group(line)
		note.add_to_group("notes")
		note.position = get_node(line).position
		note.get_node("AnimatedSprite").play(line)
		add_child(note)

func miss_note():
	set_health(health - 1)
	$MissSound.play()
	pass

func advance_notes():
	var notes = get_tree().get_nodes_in_group("notes")
	for note in notes:
		note.position.y = note.position.y + note_step
		if note.is_in_group("attack"):
			continue
		elif note.position.y > target_end and note.get_node("AnimatedSprite").animation != "break":
			note.get_node("AnimatedSprite").play("break")
			broke_combo = true
			miss_note()

func in_target(entity, tolerance = 0):
	if entity.position.y > target_start - tolerance and entity.position.y < target_end:
		return true

func clear_notes():
	var notes = get_tree().get_nodes_in_group("notes")
	for note in notes:
		if note.is_in_group("attack"):
			continue
		else:
			note.get_node("AnimatedSprite").play("break")
			increment_score(combo_counter / 10)

func _input(event):
	if event.is_action_pressed("attack"):
		$Attack.play("attack")

		var attackables = get_tree().get_nodes_in_group("attack")
		for attackable in attackables:
			# TODO: play sounds
			if in_target(attackable, note_step) and attackable.animation != "break":
				attackable.play("break")
				if attackable.type == "z":
					get_node("Sounds/z").play()
					set_health(health + 1)
				elif attackable.type == "clock":
					get_node("Sounds/clock").play()
					if pitch_scale > 0.5:
						var old_pitch_scale = pitch_scale
						pitch_scale = 0.5
						apply_pitch_scale()
						yield(get_tree().create_timer(10), "timeout")
						pitch_scale = old_pitch_scale
						apply_pitch_scale()
				elif attackable.type == "flute":
					get_node("Sounds/flute").play()
					clear_notes()

	for line in locations:
		if event.is_action_pressed(line):
			$Sounds.get_node(line).pitch_scale = pitch_scale
			$Sounds.get_node(line).play()
			var found_note = false
			var near_hit = null
			var notes = get_tree().get_nodes_in_group(line)

			for note in notes:
				if note.get_node("AnimatedSprite").animation == "break":
					continue
				elif in_target(note):
					note.get_node("AnimatedSprite").play("break")
					note.get_node("CPUParticles2D").emitting = true
					found_note = true
				elif in_target(note, note_step):
					near_hit = note

			if found_note:
				get_node("Sounds/perfect").play()
				display_indicator("perfect", line)
				got_combo = true
				increment_score(combo_counter / 10)
			elif near_hit != null:
				near_hit.get_node("AnimatedSprite").play("break")
				display_indicator("hit", line)
				increment_score()
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
