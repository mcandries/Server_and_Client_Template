extends Node

################################### Settings
const 	srv_tree_enable			 = true
const 	srv_tree_root_scene_path = "res://_srv/srv_root_scene.tscn"
var 	srv_tree_process_divider = 1  #srv_tree is process as often as cli_tree
###################################

onready var cli_tree : SceneTree = get_tree()
var cli_tree_viewport : Viewport

var srv_tree : SceneTree = SceneTree.new()
var srv_tree_viewport : Viewport
var srv_tree_visible = false

var first_process = true

func _ready():
	cli_tree_viewport = get_tree().root
	get_tree().connect("screen_resized", self, "_on_screen_resized")
	
	if srv_tree_enable :
		#init
		srv_tree.init()
		srv_tree_viewport = srv_tree.root

		#set SceneTree stretching & options
#		srv_tree.set_screen_stretch(int(ProjectSettings.get_setting("display/window/stretch/mode")),int(ProjectSettings.get_setting("display/window/stretch/aspect")), Vector2(0,0),float (ProjectSettings.get_setting("display/window/stretch/shrink")))
#		srv_tree.set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED,SceneTree.STRETCH_ASPECT_EXPAND, Vector2(0,0),float (ProjectSettings.get_setting("display/window/stretch/shrink")))

		#active processing
		srv_tree.root.set_process(true)
		srv_tree.root.set_physics_process(true)

		#set viewport options
		srv_tree_viewport.render_direct_to_screen = false
		srv_tree_viewport.transparent_bg = false
		srv_tree_viewport.render_direct_to_screen = false
#		srv_tree_viewport.size = get_tree().root.size
#		srv_tree_viewport.size = Vector2 (ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))
		srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED # to hide viewport elsewise it draw on top of the main scenetree
		
		#caught the main tree "screen_resized" to reset the srv_tree screen_stretch
		

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
		if Input.is_action_just_pressed("k_f12"):
			srv_tree_visible = !srv_tree_visible
			if srv_tree_visible:
				var cli_tree_viewport = cli_tree.root
#				var svg_size = cli_tree_viewport.size 
				cli_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
#				cli_tree_viewport.size = Vector2(0,0)
				srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
#				srv_tree_viewport.size = svg_size
				disabled_input_on_all_cli_Node2D(srv_tree)
				restore_input_on_all_cli_Node2D(cli_tree)
			else:
				var cli_tree_viewport = cli_tree.root
#				var svg_size = srv_tree_viewport.size 
				cli_tree_viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
#				cli_tree_viewport.size = svg_size
				srv_tree_viewport.render_target_update_mode = Viewport.UPDATE_DISABLED
#				srv_tree_viewport.size = Vector2(0,0)
				disabled_input_on_all_cli_Node2D(cli_tree)
				restore_input_on_all_cli_Node2D(srv_tree)
		
		if srv_tree_visible :
			srv_tree.input_event(event)
			cli_tree.set_input_as_handled()

			

#######
####### Events
#######
func _on_screen_resized():
#	prints ( get_tree().root.size ) 
	# We NEED to to the aspect ratio of the main scene by ourself (do not use project setting display/window/stretch/mode or display/window/stretch/aspect !)
	var initial_aspect_ratio =  gb.project_design_width/float(gb.project_design_height)
	
	if get_tree().root.size.y>0:  #avoird div/0
		var current_aspect_ratio = get_tree().root.size.x / get_tree().root.size.y*1.0
		var new_x_size : float
		var new_y_size : float
		
		if current_aspect_ratio>initial_aspect_ratio: #we keep the Y size, and extend the X size
			new_y_size = get_tree().root.size.y
			new_x_size = int (round (new_y_size * initial_aspect_ratio))
		else: #we keep the X size, and extend the Y size
			new_x_size = get_tree().root.size.x
			new_y_size = int(round(new_x_size / initial_aspect_ratio))
			
	#	prints (initial_aspect_ratio, current_aspect_ratio, new_x_size, new_y_size, gb.project_design_width/new_x_size, gb.project_design_height/new_y_size  ) 
		var cli_tree_viewport_camera2D = cli_tree_viewport.get_node("/root/RootScene/RootCamera2D")
	#	cli_tree_viewport_camera2D.zoom = Vector2 (ProjectSettings.get_setting("display/window/size/width")/get_tree().root.size.x,ProjectSettings.get_setting("display/window/size/height")/get_tree().root.size.y)
		cli_tree_viewport_camera2D.zoom = Vector2 (gb.project_design_width/new_x_size, gb.project_design_height/new_y_size)
		
		if srv_tree_enable : 
	#		srv_tree_viewport.size = Vector2 (ProjectSettings.get_setting("display/window/size/width"), ProjectSettings.get_setting("display/window/size/height"))
	#		srv_tree_viewport.size = Vector2 (1920,1080)
			srv_tree_viewport.size = get_tree().root.size

	#		srv_tree_viewport.size_override_stretch = true
	#		srv_tree_viewport.set_size_override(true, get_tree().root.size, Vector2 (0,0))
	#		srv_tree_viewport.size_override_stretch = true
			var srv_tree_viewport_camera2D = srv_tree_viewport.get_node("/root/RootScene/RootCamera2D")
			#srv_tree_viewport_camera2D.zoom = Vector2 (ProjectSettings.get_setting("display/window/size/width")/get_tree().root.size.x,ProjectSettings.get_setting("display/window/size/height")/get_tree().root.size.y)
			srv_tree_viewport_camera2D.zoom = Vector2 (gb.project_design_width/new_x_size,gb.project_design_height/new_y_size)



#######
####### Functions
#######
func disabled_input_on_all_cli_Node2D(tree : SceneTree):
	for n in tree.root.get_children():
		if (n is Node) and n.name!="srvtree_manager":
			var n1 : Node = n #for autocompletion
			n1.set_meta("set_process_input_SVG", n1.is_processing_input())
			n1.set_process_input(false)

func restore_input_on_all_cli_Node2D(tree : SceneTree):
	for n in tree.root.get_children():
		if (n is Node) and n.name!="srvtree_manager":
			var n1 : Node = n #for autocompletion
			if n1.has_meta("set_process_input_SVG"):
				var val = n1.get_meta("set_process_input_SVG")
				n1.set_process_input(bool(val))




