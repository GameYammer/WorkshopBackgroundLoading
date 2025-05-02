# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node3D



func _on_button_add_raptor_pressed() -> void:
	var cb := func(raptor : CharacterBody3D) -> void:
		var start := 0
		var end := 0
		print("===========================================")

		start = Time.get_ticks_usec()
		#print("!!! Got: %s" % [raptor])
		self.add_child(raptor)
		const r := 10.0
		raptor.transform.origin = Vector3(
			randf_range(-r, r),
			0.0,
			randf_range(-r, r),
		)
		end = Time.get_ticks_usec()
		print("Add to world time: %s usec" % [end - start])
	Instancer.create_async("res://src/Raptor/Raptor.tscn", cb)


func _on_button_add_raptor_sync_pressed() -> void:
	var start := 0
	var end := 0
	print("===========================================")

	# Load scene file
	start = Time.get_ticks_usec()
	var scene : PackedScene = ResourceCache.get_resource("res://src/Raptor/Raptor.tscn")
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

func _on_button_add_smoke_pressed() -> void:
	var cb := func(smoke : GPUParticles3D) -> void:
		var start := 0
		var end := 0
		print("===========================================")

		start = Time.get_ticks_usec()
		#print("!!! Got: %s" % [smoke])
		self.add_child(smoke)
		const r := 10.0
		smoke.transform.origin = Vector3(
			randf_range(-r, r),
			0.0,
			randf_range(-r, r),
		)
		end = Time.get_ticks_usec()
		print("Add to world time: %s usec" % [end - start])
	Instancer.create_async("res://src/Effects/BlackSmokeConstant/BlackSmokeConstant.tscn", cb)

func _on_button_add_smoke_sync_pressed() -> void:
	var start := 0
	var end := 0
	print("===========================================")

	# Load scene file
	start = Time.get_ticks_usec()
	var scene : PackedScene = ResourceCache.get_resource("res://src/Effects/BlackSmokeConstant/BlackSmokeConstant.tscn")
	end = Time.get_ticks_usec()
	print("Load tscn file time: %s usec" % [end - start])

	# Instance smoke scene
	start = Time.get_ticks_usec()
	var smoke : GPUParticles3D = scene.instantiate()
	end = Time.get_ticks_usec()
	print("Create instance time: %s usec" % [end - start])

	# Add the smoke to the world at a random position
	start = Time.get_ticks_usec()
	self.add_child(smoke)
	const r := 10.0
	smoke.transform.origin = Vector3(
		randf_range(-r, r),
		0.0,
		randf_range(-r, r),
	)
	end = Time.get_ticks_usec()
	print("Add to world time: %s usec" % [end - start])
