tool
extends EditorPlugin


func _enter_tree():
	# Initialization of the plugin goes here
	# Add the new type with a name, a parent type, a script and an icon
#	add_custom_type("Smooth", "Spatial", preload("smoothing.gd"), preload("smoothing.png"))
	add_custom_type("Smooth2D", "Node2D", preload("smooth2d.gd"), preload("smoothing_2d.png"))
	pass


func _exit_tree():
	# Clean-up of the plugin goes here
	# Always remember to remove it from the engine when deactivated
	remove_custom_type("Smoothing")
	remove_custom_type("Smoothing2D")
