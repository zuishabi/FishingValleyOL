class_name Player
extends CharacterBody2D

@onready var name_text = $Name
@onready var animation_tree = $AnimationTree
@onready var idle_timer = $IdleTimer
@onready var sprite_2d = $Sprite2D

const DIRECTION_THRESHOLD := 0.3
const DISTANCE_THRESHOLD := 0.1
var move_speed: float = 0.2  # 每次插值的固定步长（0.0~1.0）
var server_target_position: Vector2
var last_position: Vector2
var interpolation_factor: float = 0.0
var uid:int
var is_moving:bool = false
var direction:Vector2
var last_direction:Vector2

func update(player_name:String):
	name_text.text = player_name
	name_text.position.x =  -(name_text.size.x / 2)

func move(target: Vector2):
	direction = (target - global_position).normalized()
	if direction != Vector2.ZERO && direction.distance_to(last_direction) > DIRECTION_THRESHOLD:
		animation_tree["parameters/idle/blend_position"] = direction
		animation_tree["parameters/walk/blend_position"] = direction
		last_direction = direction
	if global_position.distance_to(target) > 50:
		global_position = target
		server_target_position = target
	else:
		last_position = global_position
		server_target_position = target
		interpolation_factor = 0.0

func _physics_process(delta: float):
	if server_target_position.distance_to(global_position) > DISTANCE_THRESHOLD:
		is_moving = true
		idle_timer.start()
	if interpolation_factor < 1.0:
		interpolation_factor += move_speed
		global_position = last_position.lerp(server_target_position, interpolation_factor)

func _on_idle_timer_timeout():
	is_moving = false
	global_position = server_target_position
