extends CharacterBody2D

@onready var client:Client = get_node("/root/Client")
var speed:int = 300

func _on_sync_timer_timeout():
	var movement:Proto.protocol.Movement = Proto.protocol.Movement.new()
	movement.set_x(self.global_position.x)
	movement.set_y(self.global_position.y)
	client.send_msg(3,movement.to_bytes())

func _input(event):
	pass

func _physics_process(delta):
	if !InputMap.has_action("left"):
		print(111)
	var direction = Input.get_vector("left","right","up","down")
	velocity = direction * speed
	if direction != Vector2.ZERO:
		move_and_slide()
