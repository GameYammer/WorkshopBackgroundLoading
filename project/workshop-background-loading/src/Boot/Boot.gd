# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node3D

'''
# TODO
. Cache materials in dict by name instead of array
. Cache all scenes in res:// instead of hard coding them
. Create an instance of the World in the thread then switch to it instead of change_scene_to_packed
. Before loading the world, add a small sub viewport and load the scenes into it, to force shader compilation
'''


var _loading_thread : Thread
var _start_loading_time := 0.0
@onready var _material_cube := preload("res://src/MaterialCube/MaterialCube.tscn")

func _ready() -> void:
	await self.get_tree().create_timer(3.0).timeout

	# Start loading in a background thread
	_start_loading_time = Time.get_ticks_msec()
	_loading_thread = Thread.new()
	_loading_thread.start(_start_loading.bind(self))

func _start_loading(thing) -> void:
	# Get the names of all the scenes we want to cache
	var scene_names := [
		"res://src/Raptor/Raptor.tscn",
		"res://src/World/World.tscn",
	]

	# Load and cache the scenes
	print("Caching scenes ...")
	for scene_name in scene_names:
		Global._scene_cache[scene_name] = ResourceLoader.load(scene_name)
		print("    %s" % [scene_name])

	# Load and cache materials
	print("Finding materials ...")
	for scene_name in scene_names:
		var inst = Global._scene_cache[scene_name].instantiate()
		var mats := Global.get_all_node_materials(inst)
		for mat in mats:
			if not Global._material_cache.has(mat):
				Global._material_cache.append(mat)
				print("    %s" % [mat.resource_path])

	# Call the load done
	thing._done_loading.call_deferred()


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
	var ticks = Time.get_ticks_msec() - _start_loading_time
	print("Loading took %s MS" % [ticks])

	# Wait so all the materials are loaded and shown on screen
	await self.get_tree().create_timer(5.0).timeout

	# Load the world scene and run it
	var world_scene = Global._scene_cache["res://src/World/World.tscn"]
	self.get_tree().change_scene_to_packed(world_scene)
