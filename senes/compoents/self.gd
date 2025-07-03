extends CharacterBody2D

@onready var client:Client = get_node("/root/Client")
@onready var animation_player = $AnimationPlayer
@onready var sprites = $Sprites
@onready var event_bus:EventBus = get_node("/root/EventBus")
@onready var camera_2d = $Camera2D
@onready var sync_timer = $SyncTimer

var speed:int = 80
var direction:Vector2
# 记录上一次同步位置时所在的位置
var last_position:Vector2
var current_chunk:Vector2i
var typing:bool = false
var is_fishing:bool = false
var current_state:int = 0:
	set(value):
		if value == current_state:
			return
		current_state = value
		var state_change:Proto.protocol.PlayerStateChange = Proto.protocol.PlayerStateChange.new()
		state_change.set_action(current_state)
		client.send_msg(8,state_change.to_bytes())

func _ready():
	event_bus.update_message_focus.connect(_on_message_focus_update)

func _on_sync_timer_timeout():
	last_position = global_position
	var movement:Proto.protocol.Movement = Proto.protocol.Movement.new()
	movement.set_x(self.global_position.x * 10)
	movement.set_y(self.global_position.y * 10)
	movement.set_direction(sprites.scale.x == 1)
	if Vector2i(global_position.x / 320,global_position.y / 320) != current_chunk:
		current_chunk = Vector2i(global_position.x / 320,global_position.y / 320)
		var chunk_change:Proto.protocol.PlayerChunkChange = Proto.protocol.PlayerChunkChange.new()
		chunk_change.set_chunk_x(current_chunk.x)
		chunk_change.set_chunk_y(current_chunk.y)
		client.send_msg(5,chunk_change.to_bytes())
	client.send_msg(3,movement.to_bytes())

func _physics_process(delta):
	direction = Input.get_vector("left","right","up","down")
	velocity = direction * speed
	if is_fishing:
		return
	if direction != Vector2.ZERO && !typing:
		if direction.x > 0:
			sprites.scale.x = 1
		elif direction.x < 0:
			sprites.scale.x = -1
		animation_player.play("run")
		move_and_slide()
	else:
		animation_player.play("idle")

func _input(event:InputEvent):
	if Input.is_action_just_pressed("left_mouse") && !typing:
		if ! is_fishing:
			is_fishing = true
			animation_player.play("cast")
			current_state = 1
			return
		else:
			is_fishing = false
			current_state = 0

func _on_message_focus_update(flag:bool):
	typing = flag

# 正式开始钓鱼
func start_waiting():
	animation_player.play("wait")
