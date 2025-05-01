# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node3D

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

const THREAD_THROTTLE := 200

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
	var err := _loading_thread.start(_start_loading.bind(on_each_cb, on_done_cb), Thread.PRIORITY_LOW)
	assert(err == OK)
	#_start_loading(on_each_cb, on_done_cb)

func _start_loading(on_each_cb : Callable, on_done_cb : Callable) -> void:
	print("Loading resource files ...")
	var resources_to_cache := Global.get_resource_file_list(["tres", "res", "material", "tscn", "scn"])
	for resource_path in resources_to_cache:
		var res = ResourceLoader.load(resource_path)
		#print(["!!!", res.get_class()])
		Global._resource_cache[resource_path] = res
		print("    %s" % [resource_path])

	print("Finding materials in scene files ...")
	for scene_path in Global._resource_cache:
		var res = Global._resource_cache[scene_path]
		if res is PackedScene:
			var inst = res.instantiate()
			var mats := Global.get_all_node_materials(inst)
			for mat in mats:
				if not Global._material_inst_cache.has(mat):
					Global._material_inst_cache.append(mat)
					print("    %s" % [mat.resource_path])

			var particles := Global.get_all_node_particles(inst)
			for par in particles:
				if not Global._particle_inst_cache.has(par):
					Global._particle_inst_cache.append(par)
					print("    %s" % [par])

	print("Caching materials in resource files ...")
	for resource_path in Global._resource_cache:
		var res = Global._resource_cache[resource_path]
		if res is StandardMaterial3D:
			var cube = _material_cube.instantiate()
			cube.mesh.material = res
			on_each_cb.call_deferred(cube)
			print("    %s" % [res.resource_path])
			OS.delay_msec(THREAD_THROTTLE)
		#elif res is ParticleProcessMaterial:
			#var cube = _material_cube.instantiate()
			#cube.mesh.material = res
			#on_each_cb.call_deferred(cube)
			#OS.delay_msec(THREAD_THROTTLE)

	print("Caching materials in scenes ...")
	for mat in Global._material_inst_cache:
		var cube = _material_cube.instantiate()
		cube.mesh.material = mat
		on_each_cb.call_deferred(cube)
		print("    %s" % [mat])
		OS.delay_msec(THREAD_THROTTLE)

	print("Caching materials in particles ...")
	for par in Global._particle_inst_cache:
		var new_particles = par.duplicate()
		new_particles.emitting = true
		on_each_cb.call_deferred(new_particles)
		print("    %s" % [par])
		OS.delay_msec(THREAD_THROTTLE)

	# Call _on_done back on the main thread
	OS.delay_msec(THREAD_THROTTLE)
	on_done_cb.call_deferred()


var _offset := Vector3.ZERO
func _on_each(node : Node) -> void:
	self.add_child(node)
	node.transform.origin = _offset
	_offset.x += 2

func _on_done() -> void:
	# Get the time used
	var ticks := Time.get_ticks_usec() - _start_loading_time
	print("Loading took %s usec" % [ticks])

	# Wait so all the materials are loaded and shown on screen
	await self.get_tree().create_timer(3.0).timeout

	# Load the world scene and run it
	var world_scene = Global._resource_cache["res://src/World/World.tscn"]
	self.get_tree().change_scene_to_packed(world_scene)
