class_name Main
extends Node2D

@onready var event_bus:EventBus = get_node("/root/EventBus")
@onready var client:Client = get_node("/root/Client")
@onready var ui:UI = get_node("/root/UI")
@onready var players = $Players
@onready var self_player = $Players/Self
# 在当前区域内的用户列表
var user_map:Dictionary[int,Player]
const PLAYER = preload("res://senes/compoents/player.tscn")

func _ready():
	ui.show()
	event_bus.plyer_move.connect(_on_player_move)
	event_bus.get_player_info.connect(_on_get_player_info)
	event_bus.transmit_player.connect(_on_transmit_player)
	event_bus.player_leave.connect(_on_player_leave)
	event_bus.update_player_action.connect(_on_player_action_changed)
	var ready:Proto.protocol.UserReady = Proto.protocol.UserReady.new()
	client.send_msg(2,ready.to_bytes())

func _on_player_move(move:Proto.protocol.Movement):
	if user_map.has(move.get_uid()) && user_map[move.get_uid()] != null:
		user_map[move.get_uid()].move(Vector2(float(move.get_x()) / 10.0,float(move.get_y()) / 10.0))
	else:
		var player:Player = PLAYER.instantiate()
		players.add_child(player)
		player.uid = move.get_uid()
		player.global_position = Vector2(float(move.get_x()) / 10.0,float(move.get_y()) / 10.0)
		player.server_target_position = player.global_position
		user_map[move.get_uid()] = player
		var player_name_req:Proto.protocol.PlayerInfoReq = Proto.protocol.PlayerInfoReq.new()
		player_name_req.set_uid(player.uid)
		client.send_msg(10,player_name_req.to_bytes())

func _on_get_player_info(rsp:Proto.protocol.PlayerInfoRsp):
	user_map[rsp.get_uid()].update(rsp.get_name(),rsp.get_state(),rsp.get_direction())

func _on_transmit_player(target:Proto.protocol.TransmitPlayer):
	self_player.global_position = Vector2(float(target.get_x()) / 10.0,float(target.get_y()) / 10.0)
	self_player.sync_timer.start()

func _on_player_leave(leave:Proto.protocol.PlayerLeave):
	user_map[leave.get_uid()].queue_free()
	user_map.erase(leave.get_uid())

func _on_player_action_changed(action:Proto.protocol.PlayerStateChange):
	if user_map.has(action.get_uid()) && user_map[action.get_uid()] != null:
		user_map[action.get_uid()].update_player_action(action.get_action())
