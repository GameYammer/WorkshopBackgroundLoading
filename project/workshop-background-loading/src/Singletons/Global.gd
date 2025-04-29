
extends Node3D


var _scene_cache := {}
var _material_cache := []

func _ready() -> void:
	# Every 1 second show FPS in the title and label
	var timer := Timer.new()
	Global.add_child(timer)
	var err := timer.connect(&"timeout", Callable(self, &"_on_timer_fps_timeout"))
	assert(err == OK)
	timer.set_wait_time(1.0)
	timer.set_one_shot(false)
	timer.start()
	timer.emit_signal("timeout")

func _on_timer_fps_timeout() -> void:
	var godot_debug := "DEBUG" if OS.is_debug_build() else "RELEASE"
	var fps := Engine.get_frames_per_second()
	var title := "(Engine: %s) | FPS: %s" % [godot_debug, fps]
	self.get_window().set_title(title)


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

func get_all_node_materials(node : Node3D) -> Array:
	var mats := []
	for mesh_inst in find_all_children_of_type(node, MeshInstance3D):
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
