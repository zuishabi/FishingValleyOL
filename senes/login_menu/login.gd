extends CanvasLayer

@onready var login_request = $LoginRequest
@onready var email = $LoginPanel/VBoxContainer/Email/LineEdit
@onready var password = $LoginPanel/VBoxContainer/Password/LineEdit
@onready var error = $Error
var client:Client = preload("res://client/client.tscn").instantiate()
var event_bus:EventBus = preload("res://globals/event_bus.tscn").instantiate()
var ui:UI = preload("res://ui/ui.tscn").instantiate()
var server_config:ConfigFile = ConfigFile.new()

func _ready():
	get_tree().root.add_child(event_bus)
	get_tree().root.add_child(client)
	get_tree().root.add_child(ui)
	ui.hide()
	client.confirm_login.connect(login_success)
	server_config.load("res://server_conf.cfg")

func _on_rigister_button_pressed():
	OS.shell_open("http://www.zuishabi.top/register")

func _on_login_pressed():
	if email.text == "" || password.text == "":
		error.update("请填写完整信息")
		return
	var body:String = JSON.new().stringify({"email"=email.text,"pwd"=password.text,"service"="FishingValley"})
	login_request.request("http://"+server_config.get_value("LoginCenter","address")+"/login",[],HTTPClient.METHOD_POST,body)

func _on_login_request_request_completed(result:int,response_code:int,headers:PackedStringArray,body:PackedByteArray):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	if response_code != 200:
		error.update("服务器不在线")
		return
	if json.data["status"] == "login successful":
		var port:int = json.data["port"]
		var ip:String = json.data["ip"]
		var key:String = json.data["key"]
		client.connect_to_server(ip,port,key)
	else:
		error.update(json.data["status"])

func login_success(sucess:bool,uid:int,content:String):
	if sucess:
		get_tree().change_scene_to_file("res://senes/main/main.tscn")
	else:
		error.update(content)
