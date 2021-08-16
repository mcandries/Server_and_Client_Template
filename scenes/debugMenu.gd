extends Control

onready var cb_DBG_DRAW_TANK_ANGLE			: CheckButton = self.find_node("DBG_DRAW_TANK_ANGLE")
onready var cb_DBG_DRAW_TANK_4_VECTORS		: CheckButton = self.find_node("DBG_DRAW_TANK_4_VECTORS")
onready var cb_DBG_NET_PRINT_DEBUG			: CheckButton = self.find_node("DBG_NET_PRINT_DEBUG")
onready var cb_DBG_CW_SRV_DELTA_INB			: CheckButton = self.find_node("DBG_CW_SRV_DELTA_INB")
onready var cb_DBG_CW_WSTATE				: CheckButton = self.find_node("DBG_CW_WSTATE")
onready var cb_DBG_CW_INB					: CheckButton = self.find_node("DBG_CW_INB")
onready var cb_DBG_CW_X_POLATE 				: CheckButton = self.find_node("DBG_CW_X_POLATE")
onready var cb_DBG_NET_SRV_LOST_PACKET_SEND	: OptionButton = self.find_node("DBG_NET_SRV_LOST_PACKET_SEND")
onready var cb_DBG_NET_CLI_LOST_PACKET_SEND	: OptionButton = self.find_node("DBG_NET_CLI_LOST_PACKET_SEND")

func _ready():
	cb_DBG_DRAW_TANK_ANGLE.pressed = gb.DBG_DRAW_TANK_ANGLE
	cb_DBG_DRAW_TANK_4_VECTORS.pressed = gb.DBG_DRAW_TANK_4_VECTORS
	cb_DBG_NET_PRINT_DEBUG.pressed = gb.DBG_NET_PRINT_DEBUG
	cb_DBG_CW_SRV_DELTA_INB.pressed = gb.DBG_CW_SRV_DELTA_INB
	cb_DBG_CW_WSTATE.pressed = gb.DBG_CW_WSTATE
	cb_DBG_CW_INB.pressed = gb.DBG_CW_INB
	cb_DBG_CW_X_POLATE.pressed = gb.DBG_CW_X_POLATE
	cb_DBG_NET_SRV_LOST_PACKET_SEND.selected = cb_DBG_NET_SRV_LOST_PACKET_SEND.get_item_index(gb.DBG_NET_SRV_LOST_PACKET_SEND)
	cb_DBG_NET_CLI_LOST_PACKET_SEND.selected = cb_DBG_NET_CLI_LOST_PACKET_SEND.get_item_index(gb.DBG_NET_CLI_LOST_PACKET_SEND)


func _input(event):
	if Input.is_action_just_pressed("ui_switch_debugmenu_visibility"):
		if is_instance_valid(self) :
			self.visible = !self.visible


func _on_DBG_CW_INB_toggled(button_pressed):
	gb.DBG_CW_INB = button_pressed


func _on_DBG_CW_X_POLATE_toggled(button_pressed):
	gb.DBG_CW_X_POLATE = button_pressed


func _on_DBG_CW_WSTATE_toggled(button_pressed):
	gb.DBG_CW_WSTATE = button_pressed


func _on_DBG_CW_SRV_DELTA_INB_toggled(button_pressed):
	gb.DBG_CW_SRV_DELTA_INB = button_pressed


func _on_DBG_NET_PRINT_DEBUG_toggled(button_pressed):
	gb.DBG_NET_PRINT_DEBUG = button_pressed


func _on_DBG_DRAW_TANK_4_VECTORS_toggled(button_pressed):
	gb.DBG_DRAW_TANK_4_VECTORS = button_pressed


func _on_DBG_DRAW_TANK_ANGLE_toggled(button_pressed):
	gb.DBG_DRAW_TANK_ANGLE = button_pressed


func _on_DBG_NET_SRV_LOST_PACKET_SEND_item_selected(index):
	gb.DBG_NET_SRV_LOST_PACKET_SEND = cb_DBG_NET_SRV_LOST_PACKET_SEND.get_item_id(index)


func _on_DBG_NET_CLI_LOST_PACKET_SEND_item_selected(index):
	gb.DBG_NET_CLI_LOST_PACKET_SEND = cb_DBG_NET_CLI_LOST_PACKET_SEND.get_item_id(index)
