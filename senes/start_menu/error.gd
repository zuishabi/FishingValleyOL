extends Window

@onready var label = $Label

func _ready():
	self.hide()

func update(msg:String):
	self.show()
	label.text = msg

func _on_close_requested():
	self.hide()
