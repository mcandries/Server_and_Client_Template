extends Node

static func array_slice_to_string (array : Array, from : int, to : int, separator : String) -> String: 
	var result = ""
	for i in range (from, to):
		result += str (array [i]) + separator
	return result

static func change_scene (tree : SceneTree, scene_path : String):
	var active_scene = tree.root.get_node("/root/RootScene/ActiveScene")
	for n in active_scene.get_children():
		n.queue_free()
	var scene = load (scene_path)
	active_scene.add_child(scene.instance())
