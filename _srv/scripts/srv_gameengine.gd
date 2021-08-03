extends Node


var current_level

var srv_levelscene : Node2D

var Tank = preload ("res://_common/scenes/tank.tscn")

var players_tanks = {}

var world

func _ready_level(level):
	srv_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	

	var j = 1
	for p in gb.srv_network_manager.players_list:
		var tank : CTank = Tank.instance()
		players_tanks[p] = tank
		tank.position = srv_levelscene.get_node ("Spawns/Spawn" + str(j)).position
		tank.name = str (p)
		srv_levelscene.get_node("Tanks").add_child(tank, true)
		j+=1

	rpc ("C_RCV_ready_level", level)


func _process(delta):
	pass

func _physics_process(delta):
	pass

func _input(event):
	pass
