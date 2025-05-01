# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node3D



func _on_button_add_raptor_pressed() -> void:
	var start := 0
	var end := 0
	print("===========================================")

	# Load scene file
	start = Time.get_ticks_usec()
	var scene : PackedScene
	if Global._is_using_cache:
		scene = Global._resource_cache["res://src/Raptor/Raptor.tscn"]
	else:
		scene = ResourceLoader.load("res://src/Raptor/Raptor.tscn")
	end = Time.get_ticks_usec()
	print("Load tscn file time: %s usec" % [end - start])

	# Instance raptor scene
	start = Time.get_ticks_usec()
	var raptor : CharacterBody3D = scene.instantiate()
	end = Time.get_ticks_usec()
	print("Create instance time: %s usec" % [end - start])

	# Add the raptor to the world at a random position
	start = Time.get_ticks_usec()
	self.add_child(raptor)
	const r := 10.0
	raptor.transform.origin = Vector3(
		randf_range(-r, r),
		0.0,
		randf_range(-r, r),
	)
	end = Time.get_ticks_usec()
	print("Add to world time: %s usec" % [end - start])
