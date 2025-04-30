# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends CharacterBody3D

@onready var _animation_player := $RaptorModel/AnimationPlayer

func _ready() -> void:
	_animation_player.play("Walk")
