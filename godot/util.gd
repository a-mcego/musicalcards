extends Node

func make_set(list:Array) -> Dictionary:
	var ret:Dictionary = {}
	for elem in list:
		ret[elem] = null
	return ret

func greater_than(a, b):
	return a > b

func less_than(a, b):
	return a < b

func list_best(list:Array, comparison_function:Callable):
	if list.size() == 0:
		return null
		
	var best_elem = list[0]
	for elem in list:
		if comparison_function.call(elem, best_elem):
			best_elem = elem
	return best_elem

func list_max(list:Array):
	return list_best(list, greater_than)

func list_min(list:Array):
	return list_best(list, less_than)
