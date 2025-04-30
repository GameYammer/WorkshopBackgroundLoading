# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Control


@export var _button_start_cached : Button
@export var _button_start_uncached : Button


func _on_button_start_cached_pressed() -> void:
	Global._is_using_cache = true
	self.get_tree().change_scene_to_file("res://src/Loader/Loader.tscn")


func _on_button_start_un_cached_pressed() -> void:
	Global._is_using_cache = false
	self.get_tree().change_scene_to_file("res://src/World/World.tscn")
