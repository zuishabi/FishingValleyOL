class_name Main
extends Node2D

@onready var event_bus:EventBus = get_node("/root/EventBus")
@onready var client:Client = get_node("/root/Client")
@onready var players = $Players
@onready var self_player = $Players/Self
# 在当前区域内的用户列表
var user_map:Dictionary[int,Player]
const PLAYER = preload("res://senes/compoents/player.tscn")

func _ready():
	event_bus.plyer_move.connect(_on_player_move)
	event_bus.get_player_name.connect(_on_get_player_name)
	event_bus.transmit_player.connect(_on_transmit_player)
	event_bus.player_leave.connect(_on_player_leave)
	var ready:Proto.protocol.UserReady = Proto.protocol.UserReady.new()
	client.send_msg(2,ready.to_bytes())

func _on_player_move(move:Proto.protocol.Movement):
	if user_map.has(move.get_uid()):
		user_map[move.get_uid()].move(Vector2(move.get_x(),move.get_y()))
	else:
		var player:Player = PLAYER.instantiate()
		players.add_child(player)
		player.uid = move.get_uid()
		user_map[move.get_uid()] = player
		player.move(Vector2(float(move.get_x()) / 10.0,float(move.get_y()) / 10.0))
		var player_name_req:Proto.protocol.PlayerNameReq = Proto.protocol.PlayerNameReq.new()
		player_name_req.set_uid(player.uid)
		client.send_msg(10,player_name_req.to_bytes())

func _on_get_player_name(rsp:Proto.protocol.PlayerNameRsp):
	user_map[rsp.get_uid()].update(rsp.get_name())

func _on_transmit_player(target:Proto.protocol.TransmitPlayer):
	self_player.global_position = Vector2(float(target.get_x()) / 10.0,float(target.get_y()) / 10.0)

func _on_player_leave(leave:Proto.protocol.PlayerLeave):
	user_map[leave.get_uid()].queue_free()
	user_map.erase(leave.get_uid())
