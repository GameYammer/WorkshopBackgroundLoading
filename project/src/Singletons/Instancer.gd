# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node

var _thread : Thread
var _mutex : Mutex
var _semaphore : Semaphore
var _to_inst := []

func create_async(scene_path : String, cb : Callable) -> void:
	var entry := {
		"scene_path" : scene_path,
		"cb" : cb,
	}

	_mutex.lock()
	_to_inst.push_back(entry)
	_mutex.unlock()

	_semaphore.post()

func create_sync(scene_path : String) -> Node:
	var scene := ResourceCache.get_resource(scene_path)
	var inst = scene.instantiate()
	return inst

func start_instancer_thread() -> void:
	_thread = Thread.new()
	_mutex = Mutex.new()
	_semaphore = Semaphore.new()
	var err := _thread.start(_run_instancer_thread, Thread.PRIORITY_LOW)
	assert(err == OK)

func _run_instancer_thread() -> void:
	while true:
		_semaphore.wait()

		var has_entries := true
		while has_entries:
			_mutex.lock()
			var entry = _to_inst.pop_front()
			_mutex.unlock()

			if entry:
				var scene_path : String = entry["scene_path"]
				var cb : Callable = entry["cb"]
				var scene := ResourceCache.get_resource(scene_path)
				var inst = scene.instantiate()
				cb.call_deferred(inst)
			else:
				has_entries = false
