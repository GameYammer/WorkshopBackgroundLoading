# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node

func find_all_children_of_type(target : Node, target_type) -> Array:
	var matches := []
	var to_search := [target]
	while not to_search.is_empty():
		var entry = to_search.pop_front()

		for child in entry.get_children():
			to_search.append(child)

		if is_instance_of(entry, target_type):
			matches.append(entry)

	return matches

func get_all_node_materials(node : Node) -> Array:
	var mats := []
	for mesh_inst in Util.find_all_children_of_type(node, MeshInstance3D):
		#print(mesh_inst)
		var mat : Material

		# Material Overlay
		mat = mesh_inst.get_material_overlay()
		if mat and not mats.has(mat):
			mats.append(mat)

		# Material Override
		mat = mesh_inst.get_material_override()
		if mat and not mats.has(mat):
			mats.append(mat)

		var surface_count : int = mesh_inst.mesh.get_surface_count()
		for i in surface_count:
			# Surface Material Override
			mat = mesh_inst.get_surface_override_material(i)
			if mat and not mats.has(mat):
				mats.append(mat)

			# Surface Material
			mat = mesh_inst.mesh.surface_get_material(i)
			if mat and not mats.has(mat):
				mats.append(mat)

	return mats

func get_all_node_particles(node : Node) -> Array:
	var retval := []
	for particles in Util.find_all_children_of_type(node, GPUParticles3D):
		var particles_copy = particles.duplicate()
		particles_copy.script = null
		retval.append(particles_copy)

	for particles in Util.find_all_children_of_type(node, CPUParticles3D):
		var particles_copy = particles.duplicate()
		particles_copy.script = null
		retval.append(particles_copy)

	return retval

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
