extends Node3D

var mouse_position:Vector3

var textures:Dictionary = {} #only use through LoadTexture
func LoadTexture(name):
	if !textures.has(name):
		var image = Image.new()
		image.load(name)
		textures[name] = ImageTexture.create_from_image(image)
	return textures[name]

class UIElement:
	var name:String
	var texture:ImageTexture
	var draggable:bool = false
	var dragging:bool = false
	var drag_offset:Vector3 = Vector3.ZERO
	var size:Vector2 = Vector2(15,20)
	var mesh_instance:MeshInstance3D
	
	func _init(name, texture:ImageTexture, center, size):
		self.name = name
		self.texture = texture
		self.size = size
		self.mesh_instance = MeshInstance3D.new()
		var mesh = PlaneMesh.new()
		mesh.size = size
		self.mesh_instance.mesh = mesh
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(3, 3, 3) # make it brighter with 3
		material.albedo_texture = texture
		material.transparency = true
		self.mesh_instance.material_override = material
		self.mesh_instance.translate(Vector3(center.x,center.y,-10))
		self.mesh_instance.rotate_x(1.57079632679)
	
	func SetTexture(texture:ImageTexture):
		self.mesh_instance.material_override.albedo_texture = texture
		
	func Enable(value:bool):
		if value:
			self.mesh_instance.material_override.albedo_color = Color(3,3,3,1)
		else:
			self.mesh_instance.material_override.albedo_color = Color(3,3,3,0)

var uielements:Array = []

var cardnames:Array = []
func init_cardnames():
	cardnames.clear()
	cardnames.append("joker")
	var ranks = ["A", "2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K"];
	var suits = ["spades", "hearts", "diamonds", "clubs"];
	for suit in suits:
		for rank in ranks:
			cardnames.append(rank + "_" + suit);
	

var current_cards:Array = [null, null, null, null, null]
var numbers:Array = []
var gamestate = "start"
var game_strings = {
	"start":"Joggers-poggers",
	"firstdeal":"Choose which cards to keep.",
	"finished":"Congrats! Or not."
}


var locked:Array = [false,false,false,false,false]

func deal():
	if gamestate == "start" or gamestate == "finished":
		locked = [false,false,false,false,false]
		numbers.clear()
		for n in cardnames.size():
			numbers.append(n)
		numbers.shuffle()
		for n in current_cards.size():
			current_cards[n] = numbers[n]
			var texname = "res://cards/back.png"
			if current_cards[n] != null:
				texname = "res://cards/" + cardnames[current_cards[n]] + ".png"
			uielements[n].SetTexture(LoadTexture(texname))
		gamestate = "firstdeal"
	elif gamestate == "firstdeal":
		for n in current_cards.size():
			if !locked[n]:
				current_cards[n] = numbers[n+5]
				var texname = "res://cards/back.png"
				if current_cards[n] != null:
					texname = "res://cards/" + cardnames[current_cards[n]] + ".png"
				uielements[n].SetTexture(LoadTexture(texname))
		gamestate = "finished"
	
	
func Pressed(name:String):
	if name == "deal":
		deal()
	
	if gamestate == "firstdeal":
		if name == "card0":
			locked[0] = !locked[0]
		if name == "card1":
			locked[1] = !locked[1]
		if name == "card2":
			locked[2] = !locked[2]
		if name == "card3":
			locked[3] = !locked[3]
		if name == "card4":
			locked[4] = !locked[4]

	for n in locked.size():
		uielements[n+5].Enable(locked[n])
		
	get_child(1).text = game_strings[gamestate] #Label node
		
func _ready():
	init_cardnames()
	
	for n in 5:
		var texname = "res://cards/back.png"
		
		var card:UIElement = UIElement.new(
			"card"+str(n),
			LoadTexture(texname), 
			Vector2(32*(n-2),0),
			Vector2(30,40)
		)
		add_child(card.mesh_instance)
		uielements.append(card)

	for n in 5:
		var texname = "res://cards/kept.png"
		
		var card:UIElement = UIElement.new(
			"kept"+str(n),
			LoadTexture(texname), 
			Vector2(32*(n-2),25),
			Vector2(30,8)
		)
		add_child(card.mesh_instance)
		card.Enable(false)
		uielements.append(card)
	
	var dealButton = UIElement.new(
		"deal",
		LoadTexture("res://cards/deal.png"),
		Vector2(64,-32),
		Vector2(24,8)
	)
	add_child(dealButton.mesh_instance)
	uielements.append(dealButton)

func _input(event):
	for card in uielements:
		if event is InputEventMouseButton:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			if event.button_index == MouseButton.MOUSE_BUTTON_LEFT:
				if event.pressed:
					var meshpos3d = card.mesh_instance.global_transform.origin
					var meshpos2d = Vector2(meshpos3d.x-card.size.x*0.5, meshpos3d.y-card.size.y*0.5)
					
					var currrect:Rect2 = Rect2(meshpos2d, card.size)
					if currrect.has_point(Vector2(mouse_position.x, mouse_position.y)):
						Pressed(card.name)
						if card.draggable:
							card.dragging = true
							card.drag_offset = card.mesh_instance.global_transform.origin - mouse_position
				else:
					card.dragging = false

		elif event is InputEventMouseMotion and card.dragging:
			mouse_position = get_viewport().get_camera_3d().project_ray_origin(event.position)
			card.mesh_instance.global_transform.origin = mouse_position + card.drag_offset

func _process(delta):
	pass
