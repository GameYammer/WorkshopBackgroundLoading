# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends Control


@export var _button_start_cached : Button
@export var _button_start_uncached : Button


func _on_button_start_cached_pressed() -> void:
	self._start(true)

func _on_button_start_un_cached_pressed() -> void:
	self._start(false)

func _start(is_using_cache : bool) -> void:
	var loading_scene_path := "res://src/Loader/Loader.tscn"
	var start_scene_path := "res://src/World/World.tscn"
	ResourceCache.setup(is_using_cache, loading_scene_path, start_scene_path)
