# * ServerTree physics work at the same tick as the ClientTree (main SceneTree) tick
# * Each Tree handle inputs if it has the visiblity (when ServerTree has visibility, it take the input, otherwise ClientTree take the input)
# * ServerTree Process can tick at a lower tick than ClienTree, by setting the "srv_tree_process_divider". (example if set to 3 and the projet FPS is set to 60, the server will tick process at 20 fps)
#
# --- TODO : 
# * Rework by using single SceneTree with "node_path" setting, instead of two sceneTree..................
# * if client connect while server refuse new connection, it "work" for client...
# * add dtls
# * add server info (server name, etc.)
# * add option to enable/disabled Upnp
# * add a "local network" thing, with  set_bind on all network but don't do internet things like upnp + show the local(s) IP(s) instead of the Internet one ?
# * add support for UDP Nat Push-Throught with external server
# * add support for pure relay server
# * 
