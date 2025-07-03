class_name Player
extends CharacterBody2D

@onready var name_text = $Name
@onready var idle_timer = $IdleTimer
@onready var animation_player = $AnimationPlayer
@onready var sprites = $Sprites
@onready var delete_timer = $DeleteTimer

const DIRECTION_THRESHOLD := 0.3
const DISTANCE_THRESHOLD := 0.1
var move_speed: float = 0.2  # 每次插值的固定步长（0.0~1.0）
var server_target_position: Vector2
var last_position: Vector2
var interpolation_factor: float = 1.0
var uid:int
var direction:Vector2
var current_state:int = 0

func update(player_name:String,player_state:int,direction:bool):
	name_text.text = player_name
	name_text.position.x =  -(name_text.size.x / 2)
	current_state = player_state
	if direction:
		sprites.scale.x = 1
	else:
		sprites.scale.x = -1
	if current_state == 0:
		animation_player.play("player_animation/idle")
	elif current_state == 1:
		animation_player.play("player_animation/wait")

func update_player_action(action:int):
	current_state = action
	if action == 0:
		animation_player.play("player_animation/idle")
	if action == 1:
		animation_player.play("player_animation/cast")

func move(target: Vector2):
	delete_timer.start()
	direction = (target - global_position).normalized()
	if direction != Vector2.ZERO:
		if direction.x > 0:
			sprites.scale.x = 1
		elif direction.x < 0:
			sprites.scale.x = -1
	if global_position.distance_to(target) > 50:
		global_position = target
		server_target_position = target
	else:
		last_position = global_position
		server_target_position = target
		interpolation_factor = 0.0

func _physics_process(delta: float):
	# 处理普通状态下的行为
	if current_state == 0:
		if server_target_position.distance_to(global_position) > DISTANCE_THRESHOLD:
				animation_player.play("player_animation/run")
				idle_timer.start()
		if interpolation_factor < 1.0:
			interpolation_factor += move_speed
			global_position = last_position.lerp(server_target_position, interpolation_factor)

func _on_idle_timer_timeout():
	if current_state != 0:
		return
	animation_player.play("player_animation/idle")
	global_position = server_target_position

# 当清理倒计时结束时销毁玩家
func _on_delete_timer_timeout():
	self.queue_free()

func start_waiting():
	animation_player.play("player_animation/wait")
