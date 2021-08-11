
extends Node

################################### Settings
var 	srv_tree_enable			 = true
const 	srv_tree_root_scene_path = "res://_srv/srv_root_scene.tscn"
var 	srv_tree_process_divider = 1  #srv_tree is process as often as cli_tree
###################################

onready var cli_tree : SceneTree = get_tree()
var cli_tree_viewport : Viewport

var srv_tree : SceneTree
var srv_tree_viewport : Viewport
var srv_tree_visible_fullscreen = false
var srv_tree_visible_overlay = false

var first_process = true

func _ready():
	cli_tree_viewport = get_tree().root
	get_tree().connect("screen_resized", self, "_on_screen_resized") #caught the main tree "screen_resized" to process Aspect Ratio of Main Scene & Srv Scene
	
	if srv_tree_enable :
		srv_tree = SceneTree.new()
		#init
		srv_tree.init()
		srv_tree_viewport = srv_tree.root

		#active processing
		srv_tree.root.set_process(true)
		srv_tree.root.set_physics_process(true)

		#set viewport options
		srv_tree_viewport.render_direct_to_screen = false
		srv_tree_viewport.transparent_bg = false
		srv_tree_viewport.render_direct_to_screen = false
		srv_tree_viewport.fxaa = true
		srv_tree_viewport.msaa = Viewport.MSAA_16X
		srv_tree_viewport.gui_snap_controls_to_pixels = true
		srv_tree_viewport.usage = Viewport.USAGE_2D

		# to hide viewport elsewise it draw on top of the main scenetree
		srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED 
		
		#load the srv root scene
		srv_tree.change_scene(srv_tree_root_scene_path)

	

func _process(delta):
	if first_process:
		if ProjectSettings.get_setting("display/window/size/test_width")!=0 and ProjectSettings.get_setting("display/window/size/test_height")!=0:
			cli_tree_viewport.size = Vector2 (ProjectSettings.get_setting("display/window/size/test_width"), ProjectSettings.get_setting("display/window/size/test_height"))
			_on_screen_resized()
		first_process = false
		
	if srv_tree_enable :
		if (get_tree().get_frame() % srv_tree_process_divider) == 0:
			#make server tree process alive
			srv_tree.idle(delta)

func _physics_process(delta):
	if srv_tree_enable :
		#make server tree physics process alive
		srv_tree.iteration(delta)

func _input(event):
	if srv_tree_enable :
		
		if Input.is_action_just_pressed("ui_switch_scene"):
			switch_active_tree()

		if Input.is_action_just_pressed("ui_switch_scene_overlay"):
#			srv_tree_viewport.set_attach_to_screen_rect(Rect2(0,0,600,600))
#			srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
			switch_active_tree_overlay()
		
		if srv_tree_visible_fullscreen :
			srv_tree.input_event(event)
			cli_tree.set_input_as_handled()
		
		if srv_tree_visible_overlay : 
			srv_tree.input_event(event)	


func switch_active_tree():
	
	if srv_tree_visible_overlay : 
		switch_active_tree_overlay()
	
	srv_tree_visible_fullscreen = !srv_tree_visible_fullscreen
	if srv_tree_visible_fullscreen:
		var cli_tree_viewport = cli_tree.root
#				var svg_size = cli_tree_viewport.size 
		cli_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
#		cli_tree_viewport.set_attach_to_screen_rect(Rect2())
#				cli_tree_viewport.size = Vector2(0,0)
		srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
#		srv_tree_viewport.set_attach_to_screen_rect(Rect2(0,0,1920,1080))
#				srv_tree_viewport.size = svg_size
		disabled_input_on_all_cli_Node2D(cli_tree)
		restore_input_on_all_cli_Node2D(srv_tree)
	else:
		var cli_tree_viewport = cli_tree.root
#				var svg_size = srv_tree_viewport.size 
		cli_tree_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
#		cli_tree_viewport.set_attach_to_screen_rect(Rect2(0,0,1920,1080))
#				cli_tree_viewport.size = svg_size
		srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
#		srv_tree_viewport.set_attach_to_screen_rect(Rect2())
#				srv_tree_viewport.size = Vector2(0,0)
		disabled_input_on_all_cli_Node2D(srv_tree)
		restore_input_on_all_cli_Node2D(cli_tree)

func switch_active_tree_overlay():
	#if we are already on fullscreen overlay mode, let's go back to Main SceneTree view
	if srv_tree_visible_fullscreen : 
		switch_active_tree() 
	
	#switch overlay mode
	srv_tree_visible_overlay = ! srv_tree_visible_overlay
	if srv_tree_visible_overlay:
		srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		srv_tree_viewport.set_attach_to_screen_rect(Rect2(0,0,cli_tree_viewport.size.x/2,cli_tree_viewport.size.y/2))
		srv_tree_viewport.canvas_transform
	else:
		srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
		srv_tree_viewport.set_attach_to_screen_rect(Rect2(0,0, cli_tree_viewport.size.x, cli_tree_viewport.size.y))
		

func kill_srvtree():
	srv_tree_enable = false
	srv_tree_viewport.get_node("/root/RootScene").queue_free()
	srv_tree_viewport.call_deferred("free")
	call_deferred("free")

#######
####### Events
#######
func _on_screen_resized():
	###
	# We MUST do the aspect ratio of the main scene by ourself (do not use project setting display/window/stretch/mode or display/window/stretch/aspect !)
	###
	var initial_aspect_ratio =  gb.project_design_width/float(gb.project_design_height)
	if get_tree().root.size.y>0:  #to avoid div/0
		var current_aspect_ratio = get_tree().root.size.x / get_tree().root.size.y*1.0
		var new_x_size : float
		var new_y_size : float
		
		if current_aspect_ratio>initial_aspect_ratio: #we keep the Y size, and extend the X size
			new_y_size = get_tree().root.size.y
			new_x_size = int (round (new_y_size * initial_aspect_ratio))
		else: #we keep the X size, and extend the Y size
			new_x_size = get_tree().root.size.x
			new_y_size = int(round(new_x_size / initial_aspect_ratio))
			
		#Make a manual "2D Expand" style resize of the main sceneTree Viewport
		var cli_tree_viewport_camera2D = cli_tree_viewport.get_node("/root/RootScene/RootCamera2D")
		if is_instance_valid(cli_tree_viewport_camera2D): #to allow "F6" play current scene in Editor without crash
			cli_tree_viewport_camera2D.zoom = Vector2 (gb.project_design_width/new_x_size, gb.project_design_height/new_y_size)
		
		if srv_tree_enable : 
			#make the Srv SceneTree size sync with the Windows Size when it's resized
			srv_tree_viewport.size = get_tree().root.size

			#Make a manual "2D Expand" style resize of the Server sceneTree Viewport
			var srv_tree_viewport_camera2D = srv_tree_viewport.get_node("/root/RootScene/RootCamera2D")
			srv_tree_viewport_camera2D.zoom = Vector2 (gb.project_design_width/new_x_size,gb.project_design_height/new_y_size)

		if srv_tree_visible_overlay:
			srv_tree_viewport.set_attach_to_screen_rect(Rect2(0,0,cli_tree_viewport.size.x/2,cli_tree_viewport.size.y/2))



#######
####### Functions
#######

func disabled_input_on_all_childs (node : Node):
	node.set_meta("set_process_input_SVG", node.is_processing_input())
	node.set_process_input(false)
	for n in node.get_children():
		if n is Node:
			disabled_input_on_all_childs(n)

func disabled_input_on_all_cli_Node2D(tree : SceneTree):
	for n in tree.root.get_children():
		if (n is Node) and n.name!="srvtree_manager" and n.name!="common_key_shortcut":
			disabled_input_on_all_childs(n)

func restore_input_on_all_childs (node : Node):
	if node.has_meta("set_process_input_SVG"):
		var val = node.get_meta("set_process_input_SVG")
		node.set_process_input(bool(val))
	for n in node.get_children():
		if n is Node:
			restore_input_on_all_childs(n)	

func restore_input_on_all_cli_Node2D(tree : SceneTree):
	for n in tree.root.get_children():
		if (n is Node) and n.name!="srvtree_manager" and n.name!="common_key_shortcut":
			restore_input_on_all_childs (n)
