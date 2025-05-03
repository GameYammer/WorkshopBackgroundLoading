# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node


var _is_logging := true
var _resource_cache := {}
var _material_inst_cache := []
var _particle_inst_cache := []
var _node_inst_cache := []

var _thread_sleep_ms := 100
var _loading_thread : Thread

@onready var _material_cube := preload("res://src/MaterialCube/MaterialCube.tscn")

func get_resource(resource_path : String) -> Resource:
	if not _resource_cache.has(resource_path):
		_resource_cache[resource_path] = ResourceLoader.load(resource_path)

	return _resource_cache[resource_path]

func start_caching_thread(on_each_cb : Callable, on_done_cb : Callable, thread_sleep_ms := 100) -> void:
	_thread_sleep_ms = thread_sleep_ms
	_loading_thread = Thread.new()
	var err := _loading_thread.start(_run_caching_thread.bind(on_each_cb, on_done_cb), Thread.PRIORITY_LOW)
	assert(err == OK)
	#_run_caching_thread(on_each_cb, on_done_cb)


func _run_caching_thread(on_each_cb : Callable, on_done_cb : Callable) -> void:
	if _is_logging: print("Loading resource files ...")
	var resources_to_cache := Util.get_resource_file_list(["tres", "res", "material", "tscn", "scn"])
	for resource_path in resources_to_cache:
		var res = ResourceLoader.load(resource_path)
		#print(["!!!", res.get_class()])
		_resource_cache[resource_path] = res
		if _is_logging: print("    %s" % [resource_path])

	if _is_logging: print("Finding scenes in group 'precache' ...")
	for scene_path in _resource_cache:
		var res = _resource_cache[scene_path]
		if res is PackedScene:
			var inst = res.instantiate()
			inst.script = null
			if inst.is_in_group("precache"):
				_node_inst_cache.append(inst)

	if _is_logging: print("Finding materials in scene files ...")
	for scene_path in _resource_cache:
		var res = _resource_cache[scene_path]
		if res is PackedScene:
			var inst = res.instantiate()
			var mats := Util.get_all_node_materials(inst)
			for mat in mats:
				if not _material_inst_cache.has(mat):
					_material_inst_cache.append(mat)
					if _is_logging: print("    %s" % [mat.resource_path])

			var particles := Util.get_all_node_particles(inst)
			for par in particles:
				if not _particle_inst_cache.has(par):
					_particle_inst_cache.append(par)
					if _is_logging: print("    %s" % [par])

	# Count things to cache
	var progress := 0.0
	var total := 0.0
	var count := 0.0
	for resource_path in _resource_cache:
		if _resource_cache[resource_path] is StandardMaterial3D:
			total += 1
	for mat in _material_inst_cache:
		total += 1
	for par in _particle_inst_cache:
		total += 1
	for node in _node_inst_cache:
		total += 1

	if _is_logging: print("Caching materials in resource files ...")
	for resource_path in _resource_cache:
		var res = _resource_cache[resource_path]
		if res is StandardMaterial3D:
			var cube = _material_cube.instantiate()
			cube.mesh.material = res

			count += 1
			progress = count / total
			on_each_cb.call_deferred(cube, progress)
			if _is_logging: print("    %s" % [res.resource_path])
			OS.delay_msec(_thread_sleep_ms)
		#elif res is ParticleProcessMaterial:
			#var cube = _material_cube.instantiate()
			#cube.mesh.material = res

			#count += 1
			#progress = count / total
			#on_each_cb.call_deferred(cube, progress)
			#OS.delay_msec(_thread_sleep_ms)

	if _is_logging: print("Caching materials in scenes ...")
	for mat in _material_inst_cache:
		var cube = _material_cube.instantiate()
		cube.mesh.material = mat

		count += 1
		progress = count / total
		on_each_cb.call_deferred(cube, progress)
		if _is_logging: print("    %s" % [mat])
		OS.delay_msec(_thread_sleep_ms)

	if _is_logging: print("Caching particle materials ...")
	for par in _particle_inst_cache:
		var new_particles = par.duplicate()
		new_particles.emitting = true

		count += 1
		progress = count / total
		on_each_cb.call_deferred(new_particles, progress)
		if _is_logging: print("    %s" % [par])
		OS.delay_msec(_thread_sleep_ms)

	if _is_logging: print("Caching node materials in group precache ...")
	for inst in _node_inst_cache:
		var new_inst = inst.duplicate()

		count += 1
		progress = count / total
		on_each_cb.call_deferred(new_inst, progress)
		if _is_logging: print("    %s" % [inst])
		OS.delay_msec(_thread_sleep_ms)

	# Call _on_done back on the main thread
	OS.delay_msec(_thread_sleep_ms)
	on_done_cb.call_deferred()
