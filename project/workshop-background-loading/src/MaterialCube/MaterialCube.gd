# Copyright (c) 2025 Game Yammer
# This file is licensed under the MIT License
# https://github.com/GameYammer/WorkshopBackgroundLoading

extends MeshInstance3D

var _rotation_velocity := Vector3.ZERO

func _ready() -> void:
	const r := 180
	_rotation_velocity = Vector3(
		randf_range(-r, r),
		randf_range(-r, r),
		randf_range(-r, r),
	)

func _physics_process(delta : float) -> void:
	self.rotation_degrees += _rotation_velocity * delta
