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

const THREAD_TROTTLE := 200

var _loading_thread : Thread
var _start_loading_time := 0.0
@onready var _material_cube := preload("res://src/MaterialCube/MaterialCube.tscn")

func _ready() -> void:
	await self.get_tree().create_timer(1.0).timeout

	# Start loading in a background thread
	_start_loading_time = Time.get_ticks_usec()

	var on_each_cb := Callable(self, "_on_each")
	var on_done_cb := Callable(self, "_on_done")
	_loading_thread = Thread.new()
	var err := _loading_thread.start(_start_loading.bind(on_each_cb, on_done_cb))
	assert(err == OK)
	#_start_loading(on_each_cb, on_done_cb)

func _start_loading(on_each_cb : Callable, on_done_cb : Callable) -> void:
	# Load and cache materials inside resource files
	print("Caching resources ...")
	var resources_to_cache := Global.get_resource_file_list(["tres", "res", "material"])
	#print(resources_to_cache)
	for resource_name in resources_to_cache:
		Global._resource_cache[resource_name] = ResourceLoader.load(resource_name)
		print("    %s" % [resource_name])

	# Load and cache the scenes
	print("Caching scenes ...")
	var scenes_to_cache := Global.get_resource_file_list(["tscn", "scn"])
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

	print("Caching materials ...")
	for mat in Global._material_cache:
		on_each_cb.call_deferred(mat)
		OS.delay_msec(THREAD_TROTTLE)

	print("Caching materials ...")
	for resource_name in Global._resource_cache:
		var res = Global._resource_cache[resource_name]
		if res is StandardMaterial3D:
			on_each_cb.call_deferred(res)
			OS.delay_msec(THREAD_TROTTLE)

	# Call _on_done back on the main thread
	OS.delay_msec(THREAD_TROTTLE)
	on_done_cb.call_deferred()


var _offset := Vector3.ZERO
func _on_each(material : StandardMaterial3D) -> void:
	#print([mat, mat.resource_path])
	var cube = _material_cube.instantiate()
	cube.mesh.material = material
	self.add_child(cube)
	cube.transform.origin = _offset
	_offset.x += 2
	print("    %s" % [material.resource_path])

func _on_done() -> void:
	# Get the time used
	var ticks := Time.get_ticks_usec() - _start_loading_time
	print("Loading took %s usec" % [ticks])

	# Wait so all the materials are loaded and shown on screen
	await self.get_tree().create_timer(3.0).timeout

	# Load the world scene and run it
	var world_scene = Global._scene_cache["res://src/World/World.tscn"]
	self.get_tree().change_scene_to_packed(world_scene)
