# aseprite.gd
# An animation solution for Godot Engine and Aseprite
# Created by Harmony Honey | hhoney.net
# Last tested with Godot v3.1.2 and Aseprite v1.2.16.3
#
# --- Purpose ---
# Play Animation Loops defined in Aseprite.
# Import data from .json file created by Aseprite.
# Assign a texture to the Sprite Node.
#
# --- Importing ---
# This script reads JSON Data created by Aseprite.
# Using "Export Sprite Sheet" (Ctrl+E in Aseprite),
# Export "Output File" (as .png) and "JSON Data" (as Hash structure)
# Export the Sprite Sheet as a "Horizontal Strip"
# Keep the .png and .json within the same folder in your Godot Project
#
# --- Using the Script ---
# Interact with the script at runtime by calling:
# set_loop(), get_loop() and try_loop()
#
# For all questions and comments, contact me on Discord @ Harrison#8571.

tool
extends Sprite
class_name Aseprite

# path to directory containing file_name.png and file_name.json
# exclude "res://" and final "/" | eg: "Image/Sheet/Monster"
export var file_dir: String = "Image"
# both .png and .json must share this name
export var file_name: String = "Player"

# --- Editor specific variables ---
# enable to load from disk
export var refresh: bool = false
# enable to preview animation
export var play_in_editor: bool = false

# variables for aseprite loop data
export var loop_active: int = 0
export var loop_name = []
export var loop_first = []
export var loop_last = []
export var loop_duration = []

var timer: float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# if inside editor
	if Engine.editor_hint:
		if refresh:
			refresh = false
			read()
		
		if not play_in_editor:
			frame = 0
			return
	
	# wait for timer
	timer += delta
	if timer < loop_duration[frame]:
		return # leave function
	timer -= loop_duration[frame]
	# post timer
	
	var new_frame = frame + 1
	if new_frame > loop_last[loop_active]:
		new_frame = loop_first[loop_active]
	frame = new_frame


# change the active loop, using the loop's name
# eg: set_loop("Run")
func set_loop(arg: String) -> bool:
	var new_loop = -1
	# check the names
	for i in range(loop_name.size()):
		if arg == loop_name[i]:
			new_loop = i
	
	# check if a loop has been found
	if new_loop == -1:
		print("set_loop Error: Name of loop not found!")
		return false # leave the function
	# continuing if no error
	timer = 0.0
	loop_active = new_loop
	frame = loop_first[loop_active]
	return true

# returns the name of active loop
func get_loop() -> String:
	return loop_name[loop_active]


# try_loop will start a loop,
# but only if that loop is not playing
func try_loop(arg: String) -> bool:
	if arg == loop_name[loop_active]:
		return false
	else:
		return set_loop(arg)


func json_parse():
	var file_path = "res://" + file_dir + "/" + file_name + ".json"
	
	var data_file = File.new()
	if data_file.open(file_path, File.READ) != OK:
		print("Error loading" + file_path)
		return false
	
	var data_text = data_file.get_as_text()
	data_file.close()
	
	var data_parse = JSON.parse(data_text)
	if data_parse.error != OK:
		print("Error parsing" + file_path)
		return false
	
	return data_parse.result


# read data from files on disk
func read():
	print("\n---Begin aseprite.gd read()---")
	print("Importing data from ", file_name, ".json")
	var json = json_parse()
	if not json.has("meta") or not json.meta.has("version"):
		print("failure")
		return false
	
	timer = 0.0
	play_in_editor = false
	loop_active = 0
	loop_duration = []
	loop_name = []
	loop_first = []
	loop_last = []
	
	var num = 0
	var key_name = file_name + " " + String(num) + ".aseprite"
	while (json.frames.has(key_name)):
		loop_duration.append(json.frames[key_name].duration / 1000)
		num += 1
		key_name = file_name + " " + String(num) + ".aseprite"
	print(file_name + ".aseprite contains: " + String(num - 1) + " frames")
	hframes = loop_duration.size()
	print("Durations: ", loop_duration, "\n")

	print("Size of frameTags: " + String(json.meta.frameTags.size()))
	for i in json.meta.frameTags.size():
		var thisTag = json.meta.frameTags[i]
		
		loop_name.append(thisTag.name)
		loop_first.append(thisTag.from)
		loop_last.append(thisTag.to)
	
	for i in range(loop_name.size()):
		print("Name: ", loop_name[i], ",\t First: ", loop_first[i], ",\t Last: ", loop_last[i])
	
	texture = load("res://" + file_dir + "/" + file_name + ".png")
	print("---End aseprite.gd read()---")

