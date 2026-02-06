extends CanvasLayer

@onready var points_container = $Control/Panel/MapContainer/PointsContainer
@onready var map_container = $Control/Panel/MapContainer

# Adjust these to match your actual game world size
# If your map is 0 to 7000 pixels wide and 0 to 2000 pixels tall:
const WORLD_WIDTH = 8000.0
const WORLD_HEIGHT = 4000.0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS 
	refresh_locations()

func refresh_locations():
	# Clear existing children
	for child in points_container.get_children():
		child.queue_free()
	
	var points = GameData.visited_save_points
	if points.is_empty():
		return

	# Wait for layout to calculate size
	await get_tree().process_frame
	var map_size = map_container.size
	
	for point_id in points:
		var data = points[point_id]
		var world_pos = data["position"]
		
		# Map World Pos -> UI Pos (0.0 to 1.0)
		var norm_x = clamp(world_pos.x / WORLD_WIDTH, 0.0, 1.0)
		var norm_y = clamp(world_pos.y / WORLD_HEIGHT, 0.0, 1.0)
		
		var btn = Button.new()
		# make it a small dot or icon
		btn.text = "" 
		btn.tooltip_text = data["name"] # Hover to see name
		btn.custom_minimum_size = Vector2(20, 20)
		btn.flat = false
		
		# Center the button on the point
		var ui_x = norm_x * map_size.x - 10
		var ui_y = norm_y * map_size.y - 10
		btn.position = Vector2(ui_x, ui_y)
		
		# Color based on whether it is the current one (optional)
		btn.modulate = Color.GREEN
		
		btn.pressed.connect(func(): _on_location_selected(data))
		points_container.add_child(btn)
		
		# Label below dot
		var lbl = Label.new()
		lbl.text = data["name"]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.position = Vector2(ui_x - 40, ui_y + 20)
		lbl.size = Vector2(100, 20)
		lbl.add_theme_font_size_override("font_size", 10)
		points_container.add_child(lbl)

func _on_location_selected(data):
	print("Fast Traveling to: ", data["name"])
	
	# Close the menu first
	queue_free()
	
	# Resume game if it was paused (optional, depending on your pause logic)
	get_tree().paused = false
	
	# Trigger Teleport
	# Need to find player. If scene changes, player might be different.
	# But wait, if we change scene, the current player instance is destroyed.
	# trigger_teleport_sequence handles scene changes too.
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		# If player not found (rare), just force load
		if data.has("scene_path") and data["scene_path"] != "":
			get_tree().change_scene_to_file(data["scene_path"])
		return
		
	# Check if we are in the same scene
	var current_scene = get_tree().current_scene.scene_file_path
	var target_scene = data.get("scene_path", "")
	var target_pos = data.get("position", Vector2.ZERO)
	
	if target_scene == current_scene or target_scene == "":
		# Same scene teleport
		player.trigger_teleport_sequence("position", target_pos)
	else:
		# Different scene teleport
		# Note: We need a way to set position AFTER loading the scene.
		# trigger_teleport_sequence with "scene" just changes scene.
		# We need to store the target position in GameData so the NEW scene can move the player.
		GameData.player_position = target_pos # Update global pos for save/load
		
		# We can use a global variable to tell the next scene where to spawn
		GameData.player_position = target_pos # Override the standard save pos
		# Ideally we'd have a 'target_spawn_position' variable, but player_position works if init uses it.
		
		player.trigger_teleport_sequence("scene", target_scene)

func _on_close_pressed():
	get_tree().paused = false
	queue_free()
