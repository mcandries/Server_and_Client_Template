extends CPreloader


var current_level

var srv_levelscene : Node2D

var players_tanks = {}

var world_states = []

func _ready_level(level):
	srv_levelscene = get_node ("/root/RootScene/ActiveScene/"+level)
	

	var j = 1
	for p in gb.srv_network_manager.players_list:
		var tank = Tank.instance()
		players_tanks[p] = tank
		tank.position = srv_levelscene.get_node ("Spawns/Spawn" + str(j)).position
		tank.name = str (p)
		srv_levelscene.get_node("Tanks").add_child(tank, true)
		j+=1

	rpc ("C_RCV_ready_level", level)


func _process(delta):
	pass

func _physics_process(delta):
	var wstate = create_new_world_state()
	world_states.append(wstate)
	rpc_unreliable("C_RCV_world_state", wstate)
	

func _input(event):
	pass


func create_new_world_state() -> Dictionary:
	var wstate = {
		"T" : OS.get_ticks_msec()
	}
	wstate["tanks"] = {}
	for tank in players_tanks.values():
		wstate["tanks"][tank.name] = {
			"PosX": tank.position.x,
			"PosY": tank.position.y
			}
	return wstate
