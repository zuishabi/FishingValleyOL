class_name Player
extends CharacterBody2D

var move_speed: float = 0.18  # 每次插值的固定步长（0.0~1.0）
var server_target_position: Vector2
var last_position: Vector2
var interpolation_factor: float = 0.0

func move(target: Vector2):
	last_position = global_position
	server_target_position = target
	interpolation_factor = 0.0  # 重置插值进度

func _physics_process(delta: float):
	if interpolation_factor < 1.0:
		interpolation_factor += move_speed  # 固定步长，非 delta 依赖
		global_position = last_position.lerp(server_target_position, interpolation_factor)
	else:
		global_position = server_target_position  # 确保最终对齐
