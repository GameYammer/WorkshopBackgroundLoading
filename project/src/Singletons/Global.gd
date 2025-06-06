# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Node3D


func _ready() -> void:
	# Turn off the generic auto quit handler
	self.get_tree().set_auto_accept_quit(false)

	# Every 1 second show FPS in the title
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

var _is_quit_triggered := false
func _notification(what : int) -> void:
	#print("what: %s" % [what])

	if what == NOTIFICATION_WM_CLOSE_REQUEST and not _is_quit_triggered:
		_is_quit_triggered = true

		# Shut down all the background threads
		#await self.get_tree().create_timer(5.0).timeout
		Instancer.stop()
		ResourceCache.stop()

		#await self.get_tree().create_timer(5.0).timeout
		self.get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

		# Actually quit
		#await self.get_tree().create_timer(5.0).timeout
		print("Doing actual quit ....")
		self.get_tree().quit()
