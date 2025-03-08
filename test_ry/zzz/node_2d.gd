extends Node2D

# Constants
const LANE_COUNT = 4
const LANE_WIDTH = 80
const LANE_SPACING = 100
const NOTE_SPEED = 400
const JUDGMENT_RANGES = {
	"PERFECT": 10,
	"GREAT": 20,
	"GOOD": 35,
	"BAD": 50,
	"MISS": 70
}
const JUDGMENT_SCORES = {
	"PERFECT": 100,
	"GREAT": 80,
	"GOOD": 50,
	"BAD": -20,
	"MISS": -50
}
const JUDGMENT_COLORS = {
	"PERFECT": Color(0, 1, 1),  # Cyan
	"GREAT": Color(0, 1, 0),    # Green
	"GOOD": Color(1, 1, 0),     # Yellow
	"BAD": Color(1, 0.53, 0),   # Orange
	"MISS": Color(1, 0, 0)      # Red
}

# Variables
var score = 0
var total_notes = 0
var stats = {
	"PERFECT": 0,
	"GREAT": 0,
	"GOOD": 0,
	"BAD": 0,
	"MISS": 0
}
var lanes = []
var note_scene = preload("res://Note.tscn")

# UI Elements
@onready var score_label = $ScoreLabel
@onready var stats_label = $StatsLabel
@onready var judgment_label = $JudgmentLabel

func _ready():
	# Initialize lanes
	for i in range(LANE_COUNT):
		var lane = {
			"key": ["A", "S", "K", "L"][i],
			"position": Vector2(100 + (i * LANE_SPACING), 0)
		}
		lanes.append(lane)
	
	# Start spawning notes
	$NoteSpawnTimer.start()

func _process(delta):
	# Handle input
	for i in range(LANE_COUNT):
		if Input.is_action_just_pressed(lanes[i].key):
			check_hit(i)

func spawn_note():
	# Randomly choose number of notes (1 or 2)
	var note_count = randi() % 2 + 1
	var available_lanes = range(LANE_COUNT)
	
	for i in range(note_count):
		if available_lanes.size() == 0:
			break
			
		var lane_idx = randi() % available_lanes.size()
		var lane = available_lanes[lane_idx]
		available_lanes.remove_at(lane_idx)
		
		var note = note_scene.instantiate()
		note.position = Vector2(lanes[lane].position.x, -50)
		add_child(note)
		total_notes += 1
		update_stats_display()

func check_hit(lane_idx):
	var closest_note = null
	var closest_distance = INF
	
	# Find closest note in the lane
	for note in get_tree().get_nodes_in_group("notes"):
		if abs(note.position.x - lanes[lane_idx].position.x) < 5:
			var distance = abs(note.position.y - 520)  # Target line Y position
			if distance < closest_distance:
				closest_distance = distance
				closest_note = note
	
	# Check judgment
	if closest_note and closest_distance <= JUDGMENT_RANGES.MISS:
		for judgment in JUDGMENT_RANGES.keys():
			if closest_distance <= JUDGMENT_RANGES[judgment]:
				if judgment != "MISS":
					closest_note.queue_free()
				show_judgment(judgment)
				update_score(JUDGMENT_SCORES[judgment])
				update_stats(judgment)
				spawn_hit_effect(lanes[lane_idx].position, JUDGMENT_COLORS[judgment])
				return
	else:
		show_judgment("BAD")
		update_score(JUDGMENT_SCORES.BAD)
		update_stats("BAD")
		spawn_hit_effect(lanes[lane_idx].position, JUDGMENT_COLORS.BAD)

func show_judgment(text):
	judgment_label.text = text
	judgment_label.modulate = JUDGMENT_COLORS[text]
	$JudgmentAnimation.play("show")

func update_score(points):
	score += points
	score_label.text = "Score: " + str(score)

func update_stats(judgment):
	stats[judgment] += 1
	update_stats_display()

func update_stats_display():
	var stats_text = "Total Notes: %d\n" % total_notes
	for judgment in stats.keys():
		stats_text += "%s: %d\n" % [judgment, stats[judgment]]
	stats_label.text = stats_text

func spawn_hit_effect(position, color):
	var effect = $HitEffectTemplate.duplicate()
	effect.position = position
	effect.modulate = color
	add_child(effect)
	effect.show()
	await get_tree().create_timer(0.2).timeout
	effect.queue_free()

func _on_note_spawn_timer_timeout():
	spawn_note()
