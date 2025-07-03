class_name SpeakMessage
extends PanelContainer

@onready var user_name = $HBoxContainer/UserName
@onready var rich_text_label = $HBoxContainer/RichTextLabel
@onready var timer = $Timer

func update(user_name:String,msg:String):
	self.user_name.text = user_name + ":"
	rich_text_label.text = msg

func show_msg():
	self.show()
	timer.stop()

func start_timer():
	timer.start()

func _on_timer_timeout():
	var tween:Tween = create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(self,"modulate",Color(1,1,1,0),1)
	await tween.finished
	modulate = Color(1,1,1,1)
	self.hide()
