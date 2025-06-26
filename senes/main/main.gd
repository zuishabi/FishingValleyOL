extends Node2D

@onready var event_bus:EventBus = get_node("/root/EventBus")
var user_map:Dictionary[int,Player]
const PLAYER = preload("res://senes/compoents/player.tscn")

func _ready():
	event_bus.plyer_move.connect(_on_player_move)

func _on_player_move(move:Proto.protocol.Movement):
	if user_map.has(move.get_uid()):
		user_map[move.get_uid()].move(Vector2(move.get_x(),move.get_y()))
	else:
		var player:Player = PLAYER.instantiate()
		self.add_child(player)
		user_map[move.get_uid()] = player
		player.move(Vector2(move.get_x(),move.get_y()))
