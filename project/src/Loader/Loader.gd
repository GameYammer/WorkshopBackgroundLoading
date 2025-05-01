# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Control

'''
# TODO
. move all cache code into singleton called ResourceCache or something
. Add black loading screen with progress bar
. Add other Materials
. Cache materials in dict by name instead of array
. Create an instance of the World in the thread then switch to it instead of change_scene_to_packed
. Before loading the world, add a small sub viewport and load the scenes into it, to force shader compilation
. Add a function to instance sync and async as to not block main thread
'''

var _start_loading_time := 0.0
var _offset := Vector3.ZERO

@onready var _progress_bar := $CenterContainer/VBoxContainer/ProgressBar

func _ready() -> void:
	await self.get_tree().create_timer(1.0).timeout

	# Start loading in a background thread
	_start_loading_time = Time.get_ticks_usec()

	var on_each_cb := Callable(self, "_on_each")
	var on_done_cb := Callable(self, "_on_done")

	ResourceCache.start_caching_thread(on_each_cb, on_done_cb)

func _on_each(node_with_material : Node, total_progress := 0.0) -> void:
	# Add the node to the screen so the material will show and force the video card to compile it now
	self.add_child(node_with_material)
	node_with_material.transform.origin = _offset
	_offset.x += 2
	_progress_bar.value = total_progress * 100.0

func _on_done() -> void:
	# Get the time used
	var ticks := Time.get_ticks_usec() - _start_loading_time
	print("Loading took %s usec" % [ticks])

	# Wait so all the materials are loaded and shown on screen
	await self.get_tree().create_timer(3.0).timeout

	# Load the world scene and run it
	var world_scene = ResourceCache.get_resource("res://src/World/World.tscn")
	self.get_tree().change_scene_to_packed(world_scene)
