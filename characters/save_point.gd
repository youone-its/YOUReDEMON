extends StaticBody2D

@export var location_name: String = "Save Point"

var is_player_inside: bool = false
var interaction_area: Area2D
var btn_label: Label

func _ready():
	# 1. Setup Interaction Area dynamically
	interaction_area = Area2D.new()
	interaction_area.name = "InteractionArea"
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 60 # Check radius
	shape.shape = circle
	interaction_area.add_child(shape)
	
	# Ensure the Area detects the Player (Masks are bitwise)
	# Assuming Player is on Layer 1 or 2. We scan broadly.
	interaction_area.collision_layer = 0   # Area itself doesn't need to be detected by others
	interaction_area.collision_mask = 0b11 # Detect Layer 1 and 2
	
	add_child(interaction_area)
	
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	
	# 2. Register to GameData ONLY if already known (loaded from save)
	# New discoveries happen in _on_body_entered
	var id = get_location_id()
	if GameData.visited_save_points.has(id):
		# Update latest position/scene in case it changed (optional)
		register_location()
	
	# 3. Create Interaction Label
	btn_label = Label.new()
	btn_label.text = "[M]"
	btn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_label.visible = false
	btn_label.position = Vector2(-20, -60)
	btn_label.z_index = 10
	add_child(btn_label)

func get_location_id() -> String:
	# Use location_name as unique key
	# If name is generic, append coordinates to allow distinction
	var id = location_name
	if id == "Save Point":
		id = "SavePoint_" + str(global_position.x)
	return id

func register_location():
	var id = get_location_id()
	var scene_path = get_tree().current_scene.scene_file_path
	
	GameData.visited_save_points[id] = {
		"name": location_name,
		"scene_path": scene_path,
		"position": global_position
	}
	print("Location Registered: ", location_name)

func _on_body_entered(body):
	print("SavePoint: Body Entered -> ", body.name)
	if body.is_in_group("player"):
		is_player_inside = true
		
		# Register DISCOVERY here
		var id = get_location_id()
		if not GameData.visited_save_points.has(id):
			register_location()
			print("SavePoint: New location discovered and saved!")
			
		btn_label.show()
		print("SavePoint: Player entered interaction zone")

func _on_body_exited(body):
	print("SavePoint: Body Exited -> ", body.name)
	if body.is_in_group("player"):
		is_player_inside = false
		btn_label.hide()

func _input(event):
	if is_player_inside and event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			open_fast_travel()

func open_fast_travel():
	# Pause game process but keep Menu process active
	get_tree().paused = true
	var menu_res = load("res://ui/menus/fast_travel_menu.tscn")
	if menu_res:
		var menu = menu_res.instantiate()
		get_tree().root.add_child(menu)
	else:
		print("Error: Fast Travel Menu not found!")
