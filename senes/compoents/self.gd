extends CharacterBody2D

@onready var client:Client = get_node("/root/Client")
@onready var animation_tree = $AnimationTree
var speed:int = 80
var direction:Vector2
var is_moving:bool = false
# 记录上一次同步位置时所在的位置
var last_position:Vector2

func _on_sync_timer_timeout():
	if last_position.distance_to(global_position) < 0.1:
		return
	last_position = global_position
	var movement:Proto.protocol.Movement = Proto.protocol.Movement.new()
	movement.set_x(self.global_position.x)
	movement.set_y(self.global_position.y)
	client.send_msg(3,movement.to_bytes())

func _physics_process(delta):
	direction = Input.get_vector("left","right","up","down")
	velocity = direction * speed
	if direction != Vector2.ZERO:
		animation_tree["parameters/idle/blend_position"]=direction
		animation_tree["parameters/walk/blend_position"]=direction
		is_moving = true
		move_and_slide()
	else:
		is_moving = false
