extends CanvasLayer

@onready var loading = $Loading
@onready var check_files = $CheckFiles
@onready var download_file = $DownloadFile

const CHUNK_SIZE = 1024
var files_info:Dictionary[String,PackedStringArray]
var check_thread:Thread = Thread.new()
var pck_path:String
var server_config:ConfigFile = ConfigFile.new()
var address:String

signal start_check
signal check_complete

func _ready():
	if !FileAccess.file_exists("res://server_conf.cfg"):
		FileAccess.open("res://server_conf.cfg",7)
		server_config.load("res://server_conf.cfg")
		server_config.set_value("HotUpdateServer","address","hotupdate.zuishabi.top")
		server_config.set_value("LoginCenter","address","gateway.zuishabi.top")
		server_config.save("res://server_conf.cfg")
	server_config.load("res://server_conf.cfg")
	address = server_config.get_value("HotUpdateServer","address")
	if OS.has_feature("editor"):
		get_tree().change_scene_to_file.call_deferred("res://senes/login_menu/login.tscn")
	else:
		loading.show()
		start_check.connect(func():
			check_thread.start(check1)
		)
		check_complete.connect(check2)
		loading.load_complete.connect(load_complete)
		loading.change_status("获取资源列表中...",20,0.5)
		check_files.request("http://" + address + "/checkFiles",[],HTTPClient.METHOD_GET)

func check1():
	var exe_path = OS.get_executable_path()
	var exe_dir = exe_path.get_base_dir()
	pck_path = exe_dir + "/pcks/"
	var dir:DirAccess = DirAccess.open(pck_path)
	if dir == null:
		DirAccess.make_dir_absolute(pck_path)
		dir = DirAccess.open(pck_path)
	var files:PackedStringArray = dir.get_files()
	var file_hash:PackedStringArray
	for i:String in files:
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_MD5)
		var file:FileAccess = FileAccess.open(pck_path + i, FileAccess.READ)
		while file.get_position() < file.get_length():
			var remaining = file.get_length() - file.get_position()
			ctx.update(file.get_buffer(min(remaining, CHUNK_SIZE)))
		file_hash.append(ctx.finish().hex_encode())
	var required_files:PackedStringArray
	for i:int in files_info["files"].size():
		var index:int = files.find(files_info["files"][i])
		if index != -1 && file_hash[index] == files_info["md5s"][i]:
			files.remove_at(index)
			file_hash.remove_at(index)
		else:
			required_files.append(files_info["files"][i])
	# 清除多余文件
	for i:String in files:
		DirAccess.remove_absolute(pck_path + i)
	check_complete.emit.call_deferred(required_files)

func check2(required_files:PackedStringArray):
	check_thread.wait_to_finish()
	loading.change_status("修补缺失文件中...",80,5)
	for i:String in required_files:
		FileAccess.open(pck_path + i,7)
		download_file.download_file =pck_path + i
		download_file.request("http://" + address + "/downloadFile?name="+i)
		await download_file.request_completed
	loading.change_status("加载资源中",99,2)
	load_resource()

func load_resource():
	print("start loading")
	var dir:DirAccess = DirAccess.open(pck_path)
	var files:PackedStringArray = dir.get_files()
	for i:String in files:
		print(ProjectSettings.load_resource_pack(pck_path + i))
	loading.change_status("完成",100,1)

func load_complete():
	get_tree().change_scene_to_file("res://senes/login_menu/login.tscn")

func _on_check_files_request_completed(result:int, response_code:int, headers:PackedStringArray, body:PackedByteArray):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	files_info["files"] = json.data["files"] as PackedStringArray
	files_info["md5s"] = json.data["md5s"] as PackedStringArray
	loading.change_status("检查资源中...",50,5)
	start_check.emit()

func _on_download_file_request_completed(result, response_code, headers, body):
	print(1)
