class_name Client
extends Node

var get_processor:Thread
var put_processor:Thread
var lock:Mutex = Mutex.new()
var semaphora:Semaphore = Semaphore.new()
var msg_channel:Array[Message]
var generator:AudioStreamPlayer
var tcp_conn:StreamPeerTCP = StreamPeerTCP.new()
#判断是否登录
var login:bool = false

@onready var event_bus:EventBus = get_node("/root/EventBus")

class Message:
	var msg_id:int
	var data:PackedByteArray

# tcp服务器验证登录码后触发
signal confirm_login(sucess:bool,uid:int,content:String)

func _ready():
	get_processor = Thread.new()
	put_processor = Thread.new()

func connect_to_server(ip:String,port:int,key):
	print(ip," ",port)
	if tcp_conn.connect_to_host(ip,port) != OK:
		confirm_login.emit(false,0,"连接服务器失败,1")
		return
	tcp_conn.poll()
	for i in 5:
		if tcp_conn.get_status() == StreamPeerTCP.Status.STATUS_CONNECTED:
			break
		tcp_conn.poll()
		await get_tree().create_timer(0.5).timeout
	if tcp_conn.get_status() != StreamPeerTCP.Status.STATUS_CONNECTED:
		tcp_conn.disconnect_from_host()
		confirm_login.emit(false,0,"连接服务器失败,2")
		return
	get_processor.start(get_msg)
	put_processor.start(_send_msg)
	var login_msg:Proto.protocol.ConfirmLogin = Proto.protocol.ConfirmLogin.new()
	login_msg.set_key(key)
	send_msg(1,login_msg.to_bytes())

func send_msg(msg_id:int,data:PackedByteArray):
	lock.lock()
	var msg:Message = Message.new()
	msg.data = data
	msg.msg_id = msg_id
	msg_channel.push_back(msg)
	lock.unlock()
	semaphora.post()

func _send_msg():
	while 1:
		semaphora.wait()
		lock.lock()
		# 如果收到了信号量但是消息队列为空，则代表要结束这个线程
		if msg_channel.size() == 0:
			return
		var msg:Message = msg_channel.pop_front() as Message
		lock.unlock()
		tcp_conn.put_32(msg.data.size())
		tcp_conn.put_32(msg.msg_id)
		tcp_conn.put_data(msg.data)

func get_msg():
	while 1:
		if tcp_conn.get_status() != StreamPeerTCP.Status.STATUS_CONNECTED:
			print("断开连接")
			if login:
				event_bus.show_error.emit.call_deferred("与服务器断开连接",1,back_to_login_menu)
			return
		var msg_len:int = tcp_conn.get_32()
		var msg_id:int =  tcp_conn.get_32()
		var data = tcp_conn.get_data(msg_len)
		var err = data[0]
		if err == OK:
			var msg:PackedByteArray = data[1]
			parse_msg(msg_id,msg)

func back_to_login_menu():
	get_processor.wait_to_finish()
	#get_tree().change_scene_to_file("res://scenes/start_menu/start_menu.tscn")

func parse_msg(msg_id:int,msg:PackedByteArray):
	if msg_id == 1:
		var rsp:Proto.protocol.ConfirmLoginResponse = Proto.protocol.ConfirmLoginResponse.new()
		rsp.from_bytes(msg)
		confirm_login.emit.call_deferred(rsp.get_success(),rsp.get_id(),rsp.get_content())
	elif msg_id == 3:
		var move:Proto.protocol.Movement = Proto.protocol.Movement.new()
		move.from_bytes(msg)
		event_bus.plyer_move.emit.call_deferred(move)
	elif msg_id == 10:
		var rsp:Proto.protocol.PlayerNameRsp = Proto.protocol.PlayerNameRsp.new()
		rsp.from_bytes(msg)
		event_bus.get_player_name.emit.call_deferred(rsp)
	elif msg_id == 4:
		# 用户离开游戏
		pass
	elif msg_id == 6:
		# 服务器传送玩家
		var transmit:Proto.protocol.TransmitPlayer = Proto.protocol.TransmitPlayer.new()
		transmit.from_bytes(msg)
		event_bus.transmit_player.emit.call_deferred(transmit)
