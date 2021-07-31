extends Node

################################### Settings
var srv_tree_process_divider = 1  #srv_tree is process as often as cli_tree
const srv_tree_root_scene_path = "res://_srv/srv_root_scene.tscn"
###################################

onready var cli_tree : SceneTree = get_tree()
var srv_tree : SceneTree = SceneTree.new()
var srv_tree_viewport
var srv_tree_visible = false

func _ready():
	#init
	srv_tree.init()
	srv_tree_viewport = srv_tree.root

	#set SceneTree stretching & options
	#srv_tree.set_screen_stretch(SceneTree.STRETCH_MODE_DISABLED,SceneTree.STRETCH_ASPECT_IGNORE, Vector2(0,0))
	srv_tree.set_screen_stretch(int(ProjectSettings.get_setting("display/window/stretch/mode")),int(ProjectSettings.get_setting("display/window/stretch/aspect")), Vector2(0,0),float (ProjectSettings.get_setting("display/window/stretch/shrink")))

	

	#active processing
	srv_tree.root.set_process(true)
	srv_tree.root.set_physics_process(true)

	#set viewport options
	srv_tree_viewport.size = Vector2 (0,0)  # to hide viewport elsewise it draw on top of the main scenetree
	srv_tree_viewport.render_direct_to_screen = false
	srv_tree_viewport.transparent_bg = false
	srv_tree_viewport.render_direct_to_screen = false
	
	#caught the main tree "screen_resized" to reset the srv_tree screen_stretch
	get_tree().connect("screen_resized", self, "_on_screen_resized")

	srv_tree.change_scene(srv_tree_root_scene_path)

func _process(delta):
	if (get_tree().get_frame() % srv_tree_process_divider) == 0:
		#make server tree process alive
		srv_tree.idle(delta)

func _physics_process(delta):
	#make server tree physics process alive
	srv_tree.iteration(delta)
	
#func 
#	srv_tree.finish()

func _input(event):
	if Input.is_action_just_pressed("k_f12"):
		srv_tree_visible = !srv_tree_visible
		if srv_tree_visible:
			srv_tree_viewport.size = get_tree().root.size
			disabled_input_on_all_cli_Node2D()
		else:
			srv_tree_viewport.size = Vector2 (0,0)
			restore_input_on_all_cli_Node2D()
	
	if srv_tree_visible :
		srv_tree.input_event(event)


func disabled_input_on_all_cli_Node2D():
	for n in cli_tree.root.get_children():
		if (n is Node) and n.name!="srvtree_manager":
			var n1 : Node = n #for autocompletion
			n1.set_meta("set_process_input_SVG", n1.is_processing_input())
			n1.set_process_input(false)

func restore_input_on_all_cli_Node2D():
	for n in cli_tree.root.get_children():
		if (n is Node) and n.name!="srvtree_manager":
			var n1 : Node = n #for autocompletion
			if n1.has_meta("set_process_input_SVG"):
				var val = n1.get_meta("set_process_input_SVG")
				n1.set_process_input(bool(val))



func _on_screen_resized():
	if not srv_tree_visible :
		srv_tree_viewport.size = Vector2 (0,0)
	else :
		srv_tree_viewport.size = get_tree().root.size




