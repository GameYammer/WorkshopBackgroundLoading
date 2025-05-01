# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node

var _is_using_cache := false
var _resource_cache := {}
var _material_inst_cache := []
var _particle_inst_cache := []

var THREAD_THROTTLE_MSEC := 200

var _loading_thread : Thread
@onready var _material_cube := preload("res://src/MaterialCube/MaterialCube.tscn")

func get_resource(resource_path : String) -> Resource:
	if _is_using_cache:
		return _resource_cache[resource_path]
	else:
		return ResourceLoader.load(resource_path)

func setup(is_using_cache : bool, loading_scene_path : String, start_scene_path : String) -> void:
	_is_using_cache = is_using_cache

	if _is_using_cache:
		self.get_tree().change_scene_to_file(loading_scene_path)
	else:
		self.get_tree().change_scene_to_file(start_scene_path)

func start_caching_thread(on_each_cb : Callable, on_done_cb : Callable) -> void:
	_loading_thread = Thread.new()
	var err := _loading_thread.start(_start_loading.bind(on_each_cb, on_done_cb), Thread.PRIORITY_LOW)
	assert(err == OK)
	#_start_loading(on_each_cb, on_done_cb)

func _start_loading(on_each_cb : Callable, on_done_cb : Callable) -> void:
	print("Loading resource files ...")
	var resources_to_cache := self.get_resource_file_list(["tres", "res", "material", "tscn", "scn"])
	for resource_path in resources_to_cache:
		var res = ResourceLoader.load(resource_path)
		#print(["!!!", res.get_class()])
		_resource_cache[resource_path] = res
		print("    %s" % [resource_path])

	print("Finding materials in scene files ...")
	for scene_path in _resource_cache:
		var res = _resource_cache[scene_path]
		if res is PackedScene:
			var inst = res.instantiate()
			var mats := Util.get_all_node_materials(inst)
			for mat in mats:
				if not _material_inst_cache.has(mat):
					_material_inst_cache.append(mat)
					print("    %s" % [mat.resource_path])

			var particles := Util.get_all_node_particles(inst)
			for par in particles:
				if not _particle_inst_cache.has(par):
					_particle_inst_cache.append(par)
					print("    %s" % [par])

	print("Caching materials in resource files ...")
	for resource_path in _resource_cache:
		var res = _resource_cache[resource_path]
		if res is StandardMaterial3D:
			var cube = _material_cube.instantiate()
			cube.mesh.material = res
			on_each_cb.call_deferred(cube)
			print("    %s" % [res.resource_path])
			OS.delay_msec(THREAD_THROTTLE_MSEC)
		#elif res is ParticleProcessMaterial:
			#var cube = _material_cube.instantiate()
			#cube.mesh.material = res
			#on_each_cb.call_deferred(cube)
			#OS.delay_msec(THREAD_THROTTLE_MSEC)

	print("Caching materials in scenes ...")
	for mat in _material_inst_cache:
		var cube = _material_cube.instantiate()
		cube.mesh.material = mat
		on_each_cb.call_deferred(cube)
		print("    %s" % [mat])
		OS.delay_msec(THREAD_THROTTLE_MSEC)

	print("Caching materials in particles ...")
	for par in _particle_inst_cache:
		var new_particles = par.duplicate()
		new_particles.emitting = true
		on_each_cb.call_deferred(new_particles)
		print("    %s" % [par])
		OS.delay_msec(THREAD_THROTTLE_MSEC)

	# Call _on_done back on the main thread
	OS.delay_msec(THREAD_THROTTLE_MSEC)
	on_done_cb.call_deferred()

func get_resource_file_list(extensions : Array[String], paths_to_ignore := []) -> Array[String]:
	var resources : Array[String] = []

	# Get all the resource files in the project
	var to_search : Array[String] = ["res://"]
	while not to_search.is_empty():
		var path : String = to_search.pop_front()
		var dir := DirAccess.open(path)
		if dir == null:
			push_error("Failed to open directory: %s" % [path])
			continue

		dir.list_dir_begin()

		while true:
			var entry := dir.get_next()
			var full_entry := dir.get_current_dir().path_join(entry)

			if entry == "":
				break

			if dir.current_is_dir():
				if entry != "." and entry != "..":
					to_search.append(full_entry)
			else:
				var is_ignored := false
				for path_to_ignore in paths_to_ignore:
					if full_entry.begins_with(path_to_ignore):
						is_ignored = true

				if not is_ignored:
					if extensions.has(full_entry.get_extension().to_lower()):
						resources.append(full_entry)

		dir.list_dir_end()

	return resources
