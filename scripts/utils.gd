extends Node

static func array_slice_to_string (array : Array, from : int, to : int, separator : String) -> String: 
	var result = ""
	for i in range (from, to):
		result += str (array [i]) + separator
	return result
