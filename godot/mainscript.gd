extends Node3D

var mouse_position:Vector3

var textures:Dictionary = {} #only use through LoadTexture
func LoadTexture(name) -> CompressedTexture2D:
	if !textures.has(name):
		textures[name] = load(name)
	return textures[name]

var cardnames:Array = []
func init_cardnames():
	cardnames.clear()
	cardnames.append("joker")
	var ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
	var suits = ["spades", "hearts", "diamonds", "clubs"];
	for suit in suits:
		for rank in ranks:
			cardnames.append(rank + "_" + suit);

class UIElement:
	var name:String
	var id:int
	var texture
	var draggable:bool = false
	var dragging:bool = false
	var drag_offset:Vector3 = Vector3.ZERO
	var size:Vector2 = Vector2(15,20)
	var mesh_instance:MeshInstance3D
	
	func _init(name:String, id:int, texture, center:Vector2, size:Vector2) -> void:
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
		
	func Enable(value:bool) -> void:
		self.mesh_instance.material_override.albedo_color.a = 1.0 if value else 0.0
			
	func GetRect() -> Rect2:
		var meshpos3d = self.mesh_instance.global_transform.origin
		var meshpos2d = Vector2(meshpos3d.x-self.size.x*0.5, meshpos3d.y-self.size.y*0.5)
		return Rect2(meshpos2d, self.size)
		
var uielements:Array = []

class CardStates:
	class CardState:
		var locked:bool = false
		var id = null

	var states = [CardState.new(), CardState.new(), CardState.new(), CardState.new(), CardState.new()]
	
	func SetLock(value:bool):
		for state in states:
			state.locked = value
	
var card_states = CardStates.new()

var numbers:Array = []
var gamestate = "start"
var game_strings = {
	"start":"Joggers-poggers",
	"firstdeal":"Choose which cards to keep.",
	"finished":"Congrats! Or not."
}

func deal():
	if gamestate == "start" or gamestate == "finished":
		card_states.SetLock(false)
		numbers.clear()
		for n in cardnames.size():
			numbers.append(n)
		numbers.shuffle()
		for n in card_states.states.size():
			card_states.states[n].id = numbers[n]
			var texname = "res://cards/" + cardnames[card_states.states[n].id] + ".png"
			uielements[n].SetTexture(LoadTexture(texname))
		gamestate = "firstdeal"
	elif gamestate == "firstdeal":
		for n in card_states.states.size():
			if !card_states.states[n].locked:
				card_states.states[n].id = numbers[n+5]
				var texname = "res://cards/" + cardnames[card_states.states[n].id] + ".png"
				uielements[n].SetTexture(LoadTexture(texname))
		gamestate = "finished"
	
func Pressed(name:String, id:int):
	if name == "deal":
		deal()
	
	if gamestate == "firstdeal":
		if name == "card":
			card_states.states[id].locked = !card_states.states[id].locked 

	for n in card_states.states.size():
		uielements[n+5].Enable(card_states.states[n].locked)
		
	get_child(1).text = game_strings[gamestate] #Label node
		
func _ready():
	init_cardnames()
	
	for n in 5:
		var texname = "res://cards/back.png"
		var card:UIElement = UIElement.new(
			"card",
			n,
			LoadTexture(texname), 
			Vector2(32*(n-2),0),
			Vector2(30,40)
		)
		add_child(card.mesh_instance)
		uielements.append(card)

	for n in 5:
		var texname = "res://cards/kept.png"
		var card:UIElement = UIElement.new(
			"kept",
			n,
			LoadTexture(texname), 
			Vector2(32*(n-2),25),
			Vector2(30,8)
		)
		add_child(card.mesh_instance)
		card.Enable(false)
		uielements.append(card)
	
	var dealButton = UIElement.new(
		"deal",
		0,
		LoadTexture("res://cards/deal.png"),
		Vector2(64,-32),
		Vector2(24,8)
	)
	add_child(dealButton.mesh_instance)
	uielements.append(dealButton)

func _input(event):
	for uielement in uielements:
		if event is InputEventMouseButton:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				if event.pressed:
					var currrect:Rect2 = uielement.GetRect()
					if currrect.has_point(Vector2(mouse_position.x, mouse_position.y)):
						Pressed(uielement.name, uielement.id)
						if uielement.draggable:
							uielement.dragging = true
							uielement.drag_offset = uielement.mesh_instance.global_transform.origin - mouse_position
				else:
					uielement.dragging = false

		elif event is InputEventMouseMotion and uielement.dragging:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			uielement.mesh_instance.global_transform.origin = mouse_position + uielement.drag_offset
