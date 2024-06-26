extends Node3D

const HAND_SIZE:int = 5
const CARD_SIZE:Vector2 = Vector2(30,40)

const DECK_DEFINITION:Dictionary = {
	"suits": ["spades", "hearts", "diamonds", "clubs"],
	"ranks": ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"],
	"ace_high_straight": true,
	"has_joker": true
}

@onready var Util = get_node("Util")

var mouse_position:Vector3 #current mouse position, updated in _input()

var loaded_textures:Dictionary = {} #only use through LoadTexture
func GetTexture(name) -> CompressedTexture2D:
	if !loaded_textures.has(name):
		loaded_textures[name] = load(name)
	return loaded_textures[name]

var card_texture_names:Array = []
func initialize_card_names():
	card_texture_names.clear()
	for suit in DECK_DEFINITION.suits:
		for rank in DECK_DEFINITION.ranks:
			card_texture_names.append(rank + "_" + suit)

	if DECK_DEFINITION.has_joker:
		card_texture_names.append("joker")

class UIElement:
	var name:String
	var id:int
	var texture:CompressedTexture2D
	var draggable:bool = false
	var dragging:bool = false
	var drag_offset:Vector3 = Vector3.ZERO
	var size:Vector2
	var mesh_instance:MeshInstance3D
	
	func _init(name:String, id:int, texture:CompressedTexture2D, center:Vector2, size:Vector2) -> void:
		self.name = name
		self.id = id
		self.texture = texture
		self.size = size
		self.mesh_instance = MeshInstance3D.new()
		var mesh = PlaneMesh.new()
		mesh.size = size
		self.mesh_instance.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(3, 3, 3, 1) # make it brighter with 3
		material.albedo_texture = texture
		material.transparency = true
		self.mesh_instance.material_override = material
		self.mesh_instance.translate(Vector3(center.x,center.y,-10)) # -10 to make it visible on the z axis
		self.mesh_instance.rotate_x(TAU/4.0)
	
	func SetTexture(texture) -> void:
		self.mesh_instance.material_override.albedo_texture = texture
		
	func SetVisible(value:bool) -> void:
		self.mesh_instance.material_override.albedo_color.a = 1.0 if value else 0.0
			
	func GetRect() -> Rect2:
		var meshpos3d = self.mesh_instance.global_transform.origin
		var meshpos2d = Vector2(meshpos3d.x-self.size.x*0.5, meshpos3d.y-self.size.y*0.5)
		return Rect2(meshpos2d, self.size)
		
var ui_elements:Array = []

class HandManager:
	class CardState:
		var locked:bool = false
		var id = null
		var kept_ui_element = null
		var card_ui_element = null

	var hand_states:Array
	
	func _init():
		for _card_num in HAND_SIZE:
			hand_states.append(CardState.new())
	
	func SetLock(value:bool):
		for state in hand_states:
			state.locked = value
	
	const hand_type_strings = [
		"High Card", 
		"One Pair", 
		"Two Pair", 
		"Three of a Kind", 
		"Straight", 
		"Flush", 
		"Full House", 
		"Four of a Kind", 
		"Straight Flush"
	]
	
	#evaluates the current hand inside the cardstate
	func EvaluateHand(card_texture_names) -> String:
		var ranks:Array = []
		var suits:Array = []
		var joker_count:int = 0

		# Collect ranks and suits, count jokers
		for state in hand_states:
			var card_name = card_texture_names[state.id]
			if card_name == "joker":
				joker_count += 1
			else:
				var parts = card_name.split("_")
				ranks.append(parts[0])
				suits.append(parts[1])

		# Convert rank strings to values and sort
		var rank_values = ranks.map(func(r): return DECK_DEFINITION.ranks.find(r))
		rank_values.sort()

		# Determine the hand type
		var hand_type = "Nothing"
		if joker_count == 0:
			hand_type = determine_hand_type(rank_values, suits)
		else:
			# Try all possible replacements for the joker
			for possible_rank in DECK_DEFINITION.ranks.size():
				for possible_suit in DECK_DEFINITION.suits:
					var test_ranks = rank_values + [possible_rank]
					var test_suits = suits + [possible_suit]
					test_ranks.sort()
					var possible_hand = determine_hand_type(test_ranks, test_suits)
					if hand_rank(possible_hand) > hand_rank(hand_type):
						hand_type = possible_hand

		return hand_type

	func determine_hand_type(ranks, suits):
		var counts:Dictionary = {}
		for rank in ranks:
			counts[rank] = counts.get(rank, 0) + 1

		var values = counts.values()
		var has_flush:bool = true
		for s in suits:
			has_flush = has_flush and (s == suits[0])
		var has_straight = is_straight(ranks)

		if has_flush and has_straight:
			return hand_type_strings[8]
		elif 4 in values:
			return hand_type_strings[7]
		elif 3 in values and 2 in values:
			return hand_type_strings[6]
		elif has_flush:
			return hand_type_strings[5]
		elif has_straight:
			return hand_type_strings[4]
		elif 3 in values:
			return hand_type_strings[3]
		elif values.count(2) == 2:
			return hand_type_strings[2]
		elif 2 in values:
			return hand_type_strings[1]
		return hand_type_strings[0]

	func is_straight(ranks:Array) -> bool:
		var rank_set:Dictionary = Util.make_set(ranks)
		if len(rank_set) != len(ranks):
			return false
		var is_ace_high:bool = DECK_DEFINITION.ace_high_straight
		if is_ace_high:
			is_ace_high = is_ace_high and rank_set.has(0)
			var n_ranks:int = DECK_DEFINITION.ranks.size()
			for rank in range(n_ranks-(HAND_SIZE-1), n_ranks):
				is_ace_high = is_ace_high and rank_set.has(rank)
			
		return Util.list_max(ranks) - Util.list_min(ranks) == 4 or is_ace_high  # Ace high straight

	func hand_rank(hand_type):
		return hand_type_strings.find(hand_type)

var hand_manager:HandManager = HandManager.new()

var shuffled_card_indices:Array = []
var game_state = "start"
var game_strings = {
	"start":"Joggers-poggers",
	"firstdeal":"Choose which cards to keep.",
	"finished":"Congrats! Or not."
}

func Deal():
	if game_state == "start" or game_state == "finished":
		hand_manager.SetLock(false)
		shuffled_card_indices.clear()
		for n in card_texture_names.size():
			shuffled_card_indices.append(n)
		shuffled_card_indices.shuffle()
		for n in hand_manager.hand_states.size():
			var state = hand_manager.hand_states[n]
			state.id = shuffled_card_indices[n]
			var texture_path = "res://cards/" + card_texture_names[state.id] + ".png"
			state.card_ui_element.SetTexture(GetTexture(texture_path))
		game_state = "firstdeal"
	elif game_state == "firstdeal":
		var unused_card_id:int = HAND_SIZE
		
		# replace the non-locked cards
		for state in hand_manager.hand_states:
			if !state.locked:
				state.id = shuffled_card_indices[unused_card_id]
				unused_card_id += 1
				var texture_path = "res://cards/" + card_texture_names[state.id] + ".png"
				state.card_ui_element.SetTexture(GetTexture(texture_path))
		
		var hand_type:String = hand_manager.EvaluateHand(card_texture_names)
		
		game_state = "finished"
		game_strings[game_state] = hand_type
	
func EventPressed(name:String, id:int):
	if name == "deal":
		Deal()
	elif name == "card":
		if game_state == "firstdeal":
			hand_manager.hand_states[id].locked = !hand_manager.hand_states[id].locked 

	# Update visuals
	for state in hand_manager.hand_states:
		state.kept_ui_element.SetVisible(state.locked)
	get_child(1).text = game_strings[game_state] #Label node
		
func _ready():
	initialize_card_names()
	
	#init UI elements
	for n in HAND_SIZE:
		var center_position:Vector2 = Vector2(CARD_SIZE.x*(n-(HAND_SIZE-1)*0.5),0)
		var card_ui_element:UIElement = UIElement.new(
			"card",
			n,
			GetTexture("res://cards/back.png"), 
			center_position,
			CARD_SIZE
		)
		var kept_ui_element:UIElement = UIElement.new(
			"kept",
			n,
			GetTexture("res://cards/kept.png"), 
			Vector2(center_position.x, center_position.y + CARD_SIZE.y*0.625),
			Vector2(CARD_SIZE.x,CARD_SIZE.y/5)
		)
		kept_ui_element.SetVisible(false)

		add_child(card_ui_element.mesh_instance)
		add_child(kept_ui_element.mesh_instance)

		ui_elements.append(card_ui_element)
		ui_elements.append(kept_ui_element)

		hand_manager.hand_states[n].card_ui_element = card_ui_element
		hand_manager.hand_states[n].kept_ui_element = kept_ui_element
	
	var dealButton = UIElement.new(
		"deal",
		0,
		GetTexture("res://cards/deal.png"),
		Vector2(64,-32),
		Vector2(24,8)
	)
	add_child(dealButton.mesh_instance)
	ui_elements.append(dealButton)

func _input(event):
	for ui_element in ui_elements:
		if event is InputEventMouseButton:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				if event.pressed:
					var currrect:Rect2 = ui_element.GetRect()
					if currrect.has_point(Vector2(mouse_position.x, mouse_position.y)):
						EventPressed(ui_element.name, ui_element.id)
						if ui_element.draggable:
							ui_element.dragging = true
							ui_element.drag_offset = ui_element.mesh_instance.global_transform.origin - mouse_position
				else:
					ui_element.dragging = false

		elif event is InputEventMouseMotion and ui_element.dragging:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			ui_element.mesh_instance.global_transform.origin = mouse_position + ui_element.drag_offset
