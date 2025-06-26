extends Control

@onready var label = $VBoxContainer/Label
@onready var progress_bar = $VBoxContainer/ProgressBar

var tween:Tween
signal load_complete

func change_status(text:String,progress:int,len:float):
	label.text = text
	if tween && tween.is_running():
		tween.stop()  # 停止当前tween但保留进度
	tween = create_tween()
	tween.set_trans(Tween.TRANS_CIRC)
	tween.tween_property(progress_bar,"value",progress,len)
	if progress == 100:
		await tween.finished
		load_complete.emit()
