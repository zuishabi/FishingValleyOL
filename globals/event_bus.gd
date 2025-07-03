class_name EventBus
extends Node

# 显示一个错误信息
signal show_error

# 有玩家移动
signal plyer_move(move:Proto.protocol.Movement)

# 获取到玩家的名称
signal get_player_info(rsp:Proto.protocol.PlayerInfoRsp)

# 服务器传送玩家
signal transmit_player(target:Proto.protocol.TransmitPlayer)

# 玩家退出
signal player_leave(leave:Proto.protocol.PlayerLeave)

# 获取消息
signal get_speak(speak:Proto.protocol.Speak)

# 聊天框更新聚焦
signal update_message_focus(flag:bool)

# 玩家动作更新
signal update_player_action(action:Proto.protocol.PlayerStateChange)

# disable camera
signal disable_camera(flag:bool)
