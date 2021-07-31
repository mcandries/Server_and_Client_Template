# * ServerTree physics work at the same tick as the ClientTree (main SceneTree) tick
# * Each Tree handle inputs if it has the visiblity (when ServerTree has visibility, it take the input, otherwise ClientTree take the input)
# * ServerTree Process can tick at a lower tick than ClienTree, by setting the "srv_tree_process_divider". (example if set to 3 and the projet FPS is set to 60, the server will tick process at 20 fps)
#
