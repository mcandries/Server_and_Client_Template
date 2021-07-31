extends Node2D

const cli_entry_scene = preload("res://_cli/scenes/cli_example_menu.tscn")

func _ready():
	utils.change_scene(get_tree(), cli_entry_scene)

func _process(delta):
	pass

func _input(event):
	pass

