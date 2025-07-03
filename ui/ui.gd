class_name UI
extends CanvasLayer

@onready var pause_menu = $PauseMenu
@onready var event_bus:EventBus = get_node("/root/EventBus")

func _input(event):
	if !self.visible:
		return
	if event.is_action_pressed("esc"):
		pause_menu.visible = !pause_menu.visible

func _on_exit_pressed():
	get_tree().quit()
