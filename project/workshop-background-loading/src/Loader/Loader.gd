# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node3D

'''
# TODO
. Add black loading screen with progress bar
. Add other Materials
. Cache materials in dict by name instead of array
. Cache all scenes in res:// instead of hard coding them
. Create an instance of the World in the thread then switch to it instead of change_scene_to_packed
. Before loading the world, add a small sub viewport and load the scenes into it, to force shader compilation
'''


var _loading_thread : Thread
var _start_loading_time := 0.0
@onready var _material_cube := preload("res://src/MaterialCube/MaterialCube.tscn")

func _ready() -> void:
	await self.get_tree().create_timer(1.0).timeout

	# Start loading in a background thread
	_start_loading_time = Time.get_ticks_usec()

	var on_done_cb := Callable(self, "_done_loading")
	_loading_thread = Thread.new()
	var err := _loading_thread.start(_start_loading.bind(on_done_cb))
	assert(err == OK)
	#_start_loading(on_done_cb)

func _start_loading(on_done_cb : Callable) -> void:
	var scenes_to_cache := Global.get_resource_file_list(["tscn", "scn"])

	# Load and cache the scenes
	print("Caching scenes ...")
	for scene_name in scenes_to_cache:
		Global._scene_cache[scene_name] = ResourceLoader.load(scene_name)
		print("    %s" % [scene_name])

	# Load and cache materials
	print("Finding materials ...")
	for scene_name in scenes_to_cache:
		var inst = Global._scene_cache[scene_name].instantiate()
		var mats := Global.get_all_node_materials(inst)
		for mat in mats:
			if not Global._material_cache.has(mat):
				Global._material_cache.append(mat)
				print("    %s" % [mat.resource_path])

	# Call _done_loading back on the main thread
	on_done_cb.call_deferred()


func _done_loading() -> void:
	var offset := Vector3.ZERO
	print("Caching materials ...")
	for mat in Global._material_cache:
		#print([mat, mat.resource_path])
		var cube = _material_cube.instantiate()
		cube.mesh.material = mat
		self.add_child(cube)
		cube.transform.origin = offset
		offset.x += 2
		print("    %s" % [mat.resource_path])

	# Get the time used
	var ticks := Time.get_ticks_usec() - _start_loading_time
	print("Loading took %s usec" % [ticks])

	# Wait so all the materials are loaded and shown on screen
	await self.get_tree().create_timer(3.0).timeout

	# Load the world scene and run it
	var world_scene = Global._scene_cache["res://src/World/World.tscn"]
	self.get_tree().change_scene_to_packed(world_scene)
