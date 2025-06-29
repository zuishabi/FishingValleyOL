class_name EventBus
extends Node

# 显示一个错误信息
signal show_error

# 有玩家移动
signal plyer_move(move:Proto.protocol.Movement)

# 获取到玩家的名称
signal get_player_name(rsp:Proto.protocol.PlayerNameRsp)

# 服务器传送玩家
signal transmit_player(target:Proto.protocol.TransmitPlayer)
