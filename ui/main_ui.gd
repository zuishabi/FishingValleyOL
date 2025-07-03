extends Control

@onready var text_edit = $MessageMenu/VBoxContainer/HBoxContainer/TextEdit
@onready var v_box_container = $MessageMenu/VBoxContainer/ScrollContainer/VBoxContainer
@onready var client:Client = get_node("/root/Client")
@onready var event_bus:EventBus = get_node("/root/EventBus")
@onready var chat_board = $MessageMenu/VBoxContainer/HBoxContainer

const speak_message = preload("res://ui/speak_message.tscn")
var message_count:int = 0

func _ready():
	event_bus.get_speak.connect(_on_get_speak)
	chat_board.hide()

func _input(event):
	if event.is_action_pressed("show_chat_board"):
		chat_board.visible = !chat_board.visible
		if chat_board.visible:
			text_edit.grab_focus.call_deferred()
		else:
			text_edit.release_focus()
		text_edit.clear()

func _on_send_pressed():
	if text_edit.text == "":
		return
	var speak:Proto.protocol.Speak = Proto.protocol.Speak.new()
	speak.set_msg(text_edit.text)
	client.send_msg(7,speak.to_bytes())
	text_edit.clear()

func _on_get_speak(speak:Proto.protocol.Speak):
	message_count += 1
	var new_msg:SpeakMessage = speak_message.instantiate()
	v_box_container.add_child(new_msg)
	v_box_container.move_child(new_msg,-1)
	if message_count > 20:
		v_box_container.remove_child(v_box_container.get_child(0))
	new_msg.update(speak.get_user_name(),speak.get_msg())
	new_msg.show_msg()
	if !text_edit.has_focus():
		new_msg.start_timer()

func _on_text_edit_focus_entered():
	event_bus.update_message_focus.emit(true)
	for i:SpeakMessage in v_box_container.get_children():
		i.show_msg()

func _on_text_edit_focus_exited():
	event_bus.update_message_focus.emit(false)
	for i:SpeakMessage in v_box_container.get_children():
		i.start_timer()
