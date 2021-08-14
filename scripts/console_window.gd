extends Node

################################### Settings
const console_initial_visibility = true
var console_label_line_to_draw		= 12
var console_history_cache_line_size	= 1000
###################################

#var Pconsole_Window 	= preload ("res://scenes/consoleWindow.tscn")
var dbg_history 	: PoolStringArray	= []
var console_window 	: HBoxContainer
var console_label 	: Label
var console_vscroll : VScrollBar


func _ready():
#	for n in get_tree().root.get_children():
#		if (n is Node2D) :
#			console_window = Pconsole_Window.instance()
#			n.add_child(console_window)
#	console_window.rect_position = Vector2 (10, gb.project_design_height - console_window.rect_min_size.y - 10 )
#			break
	pass

func _input(event):
	if Input.is_action_just_pressed("ui_switch_console_visibility"):
		if is_instance_valid(console_window) :
			console_window.visible = !console_window.visible

#######
####### Functions
#######

func print(value):
	var l_text : String = str (value)
	dbg_history.append_array( l_text.split('\n') )
	
	while  dbg_history.size()>console_history_cache_line_size:
		dbg_history.remove(0)
		if is_instance_valid(console_vscroll) :
			if (console_vscroll.value != console_vscroll.max_value) and console_vscroll.value>1:
				console_vscroll.value -= 1
	self.refresh()

func prints(values : Array):
	var concat_value = ""
	
	var j = 0
	for i in values:
		j += 1
		concat_value += str (i)
		if j<values.size():
			concat_value += " "
	
	self.print (concat_value)
	

func refresh():
	if is_instance_valid(console_window) :
		if console_window.visible:
			var was_on_last_line =  (console_vscroll.value == console_vscroll.max_value)

			var lines = dbg_history.size()
			console_vscroll.max_value = lines
			if was_on_last_line : 
				console_vscroll.value = console_vscroll.max_value
			
			var min_index = clamp(console_vscroll.value-console_label_line_to_draw, 0, INF)
			var max_index = console_vscroll.value
			if max_index <console_label_line_to_draw :
				max_index = console_label_line_to_draw
			if max_index >dbg_history.size():
				max_index = dbg_history.size()
			console_label.text = utils.array_slice_to_string(dbg_history, min_index, max_index, "\n")


