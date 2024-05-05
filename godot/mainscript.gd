extends Node3D

var mouse_position:Vector3 #current mouse position, updated in _input()

var loaded_textures:Dictionary = {} #only use through LoadTexture
func GetTexture(name) -> CompressedTexture2D:
	if !loaded_textures.has(name):
		loaded_textures[name] = load(name)
	return loaded_textures[name]

var card_names:Array = []
func initialize_card_names():
	card_names.clear()
	card_names.append("joker")
	var ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
	var suits = ["spades", "hearts", "diamonds", "clubs"];
	for suit in suits:
		for rank in ranks:
			card_names.append(rank + "_" + suit);

class UIElement:
	var name:String
	var id:int
	var texture:CompressedTexture2D
	var draggable:bool = false
	var dragging:bool = false
	var drag_offset:Vector3 = Vector3.ZERO
	var size:Vector2 = Vector2(15,20)
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
		self.mesh_instance.translate(Vector3(center.x,center.y,-10))
		self.mesh_instance.rotate_x(1.57079632679)
	
	func SetTexture(texture) -> void:
		self.mesh_instance.material_override.albedo_texture = texture
		
	func SetVisible(value:bool) -> void:
		self.mesh_instance.material_override.albedo_color.a = 1.0 if value else 0.0
			
	func GetRect() -> Rect2:
		var meshpos3d = self.mesh_instance.global_transform.origin
		var meshpos2d = Vector2(meshpos3d.x-self.size.x*0.5, meshpos3d.y-self.size.y*0.5)
		return Rect2(meshpos2d, self.size)
		
var ui_elements:Array = []

class CardManager:
	class CardState:
		var locked:bool = false
		var id = null
		var kept_ui_element = null
		var card_ui_element = null

	var states = [CardState.new(), CardState.new(), CardState.new(), CardState.new(), CardState.new()]
	
	func SetLock(value:bool):
		for state in states:
			state.locked = value
	
var card_manager = CardManager.new()

var card_indices:Array = []
var game_state = "start"
var game_strings = {
	"start":"Joggers-poggers",
	"firstdeal":"Choose which cards to keep.",
	"finished":"Congrats! Or not."
}

func deal():
	if game_state == "start" or game_state == "finished":
		card_manager.SetLock(false)
		card_indices.clear()
		for n in card_names.size():
			card_indices.append(n)
		card_indices.shuffle()
		for n in card_manager.states.size():
			var state = card_manager.states[n]
			state.id = card_indices[n]
			var texname = "res://cards/" + card_names[state.id] + ".png"
			state.card_ui_element.SetTexture(GetTexture(texname))
		game_state = "firstdeal"
	elif game_state == "firstdeal":
		var unused_card_id:int = 5
		for state in card_manager.states:
			if !state.locked:
				state.id = card_indices[unused_card_id]
				unused_card_id += 1
				var texname = "res://cards/" + card_names[state.id] + ".png"
				state.card_ui_element.SetTexture(GetTexture(texname))
		game_state = "finished"
	
func Pressed(name:String, id:int):
	if name == "deal":
		deal()
	
	if game_state == "firstdeal":
		if name == "card":
			card_manager.states[id].locked = !card_manager.states[id].locked 

	for n in card_manager.states.size():
		card_manager.states[n].kept_ui_element.SetVisible(card_manager.states[n].locked)
		
	get_child(1).text = game_strings[game_state] #Label node
		
func _ready():
	initialize_card_names()
	
	for n in 5:
		var texname = "res://cards/back.png"
		var ui_element:UIElement = UIElement.new(
			"card",
			n,
			GetTexture(texname), 
			Vector2(32*(n-2),0),
			Vector2(30,40)
		)
		add_child(ui_element.mesh_instance)
		card_manager.states[n].card_ui_element = ui_element
		ui_elements.append(ui_element)

	for n in 5:
		var texname = "res://cards/kept.png"
		var ui_element:UIElement = UIElement.new(
			"kept",
			n,
			GetTexture(texname), 
			Vector2(32*(n-2),25),
			Vector2(30,8)
		)
		add_child(ui_element.mesh_instance)
		ui_element.SetVisible(false)
		ui_elements.append(ui_element)
		card_manager.states[n].kept_ui_element = ui_element
	
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
						Pressed(ui_element.name, ui_element.id)
						if ui_element.draggable:
							ui_element.dragging = true
							ui_element.drag_offset = ui_element.mesh_instance.global_transform.origin - mouse_position
				else:
					ui_element.dragging = false

		elif event is InputEventMouseMotion and ui_element.dragging:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			ui_element.mesh_instance.global_transform.origin = mouse_position + ui_element.drag_offset
