# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Control


@export var _button_start_cached : Button
@export var _button_start_uncached : Button


func _on_button_start_with_pre_load_pressed() -> void:
	self._start(true)

func _on_button_start_normal_pressed() -> void:
	self._start(false)

func _start(is_pre_loading : bool) -> void:
	Instancer.start_instancer_thread()

	if is_pre_loading:
		self.get_tree().change_scene_to_file("res://src/LoadingScreen/LoadingScreen.tscn")
	else:
		self.get_tree().change_scene_to_file("res://src/World/World.tscn")
