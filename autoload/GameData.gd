extends Node

# Variabel Global untuk Data Pemain
var hp: int = 100
var demonized_level: int = 0
var items: Array = []
var player_position: Vector2 = Vector2(-1, -1)
var boss_position: Vector2 = Vector2(-1, -1)
var quit_shortcut_key: int = KEY_Q # Defaultnya tombol Q
var chat_toggle_key: int = KEY_TAB
var current_slot: int = -1 
var current_scene_path: String = ""
# --- DATA LIVE CHAT ---
var completed_chats: Array = [] # Menyimpan ID trigger/offer yang sudah selesai
var chat_history: Array = []    # Menyimpan isi pesan (teks & tipe) yang sudah muncul
var altars_status: Array = [false, false, false, false] # Simpan status 4 altar
signal quit_requested
signal stats_changed
var is_loading_from_save: bool = false
var item_left: String = "none"
var item_right: String = "none"
var has_flashlight: bool = false # Simpan status kepemilikan senter
var last_scene: String = ""      # Opsional: Untuk fitur "Continue"
var current_map_state: String = "tutorial" # "tutorial", "main", "boss"
var needs_transition_entry: bool = false # For scene transitions

var defeated_enemy_names: Array = []
var visited_save_points: Dictionary = {}
var intro_played: bool = false

func find_empty_slot() -> int:
	for i in range(1, 4):
		if not FileAccess.file_exists(get_save_path(i)):
			return i
	return 0 # Penuh
	
# --- FUNGSI PATH DINAMIS ---
func get_save_path(slot: int) -> String:
	return "user://save_game_%d.dat" % slot

func get_thumb_path(slot: int) -> String:
	return "user://save_thumb_%d.png" % slot

# --- LOGIKA DATA ---
func reset_data():
	hp = 100
	demonized_level = 0
	items = []
	player_position = Vector2(3159, 1772)
	boss_position = Vector2(3159, 1700)
	completed_chats = []
	chat_history = [] # Reset history saat New Game agar bersih
	current_slot = -1
	intro_played = false
	visited_save_points = {}
	
func play_click_sound():
	var sfx = AudioStreamPlayer.new()
	sfx.stream = load("res://assets/Sound/click/Menu_Select_00.mp3")
	# Add to root to ensure it plays even if scene changes
	get_tree().root.add_child(sfx)
	sfx.play()
	# Clean up after playing
	sfx.finished.connect(sfx.queue_free)
	altars_status = [false, false, false, false] # Reset saat New Game
	current_scene_path = ""
	is_loading_from_save = false
	defeated_enemy_names = []

func save_game():
	if current_slot == -1:
		var empty_slot = find_empty_slot()
		if empty_slot > 0:
			current_slot = empty_slot
		else:
			# Jika penuh, kita override slot 1 atau beri notifikasi
			current_slot = 1 
			
	var file = FileAccess.open(get_save_path(current_slot), FileAccess.WRITE)

	if file:
		var data = {
			"hp": hp,
			"demonized_level": demonized_level,
			"items": items,
			"pos_x": player_position.x,
			"pos_y": player_position.y,
			"pos_y_boss": boss_position.y,
			"pos_x_boss": boss_position.x,
			"completed_chats": completed_chats,
			"chat_history": chat_history,
			"scene_path": current_scene_path,
			"has_flashlight": has_flashlight, # TAMBAHKAN INI
			"altars_status": altars_status,
			"defeated_enemy_names": defeated_enemy_names,
			"visited_save_points": visited_save_points,
		}
		file.store_var(data)
		file.close()
		return true
	return false
	
func delete_save_slot(slot: int):
	var save_path = get_save_path(slot)
	var thumb_path = get_thumb_path(slot)
	
	# Hapus file data jika ada
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		
	# Hapus file thumbnail jika ada
	if FileAccess.file_exists(thumb_path):
		DirAccess.remove_absolute(thumb_path)
	
	print("Slot %d berhasil dihapus." % slot)
	
func load_data_from_slot(slot: int):
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = file.get_var()
		
		hp = data["hp"]
		demonized_level = data["demonized_level"]
		items = data["items"]
		player_position = Vector2(data["pos_x"], data["pos_y"])
		boss_position = Vector2(data["pos_x_boss"], data["pos_y_boss"])
		completed_chats = data.get("completed_chats", []) 
		chat_history = data.get("chat_history", []) # Ambil data history
		current_scene_path = data.get("scene_path", "")
		has_flashlight = data.get("has_flashlight", false)
		altars_status = data.get("altars_status", [false, false, false, false])
		defeated_enemy_names = data.get("defeated_enemy_names", [])
		visited_save_points = data.get("visited_save_points", {})
		
		current_slot = slot 
		file.close()
		
		# Pemicu agar LiveChat menampilkan kembali history setelah loading
		if has_node("/root/LiveChat"):
			get_node("/root/LiveChat").reload_history()
		
		is_loading_from_save = true
		return data
	return null

func delete_slot(slot: int):
	var s_path = get_save_path(slot)
	var t_path = get_thumb_path(slot)
	if FileAccess.file_exists(s_path): DirAccess.remove_absolute(s_path)
	if FileAccess.file_exists(t_path): DirAccess.remove_absolute(t_path)

func save_settings():
	var file = FileAccess.open("user://settings.dat", FileAccess.WRITE)
	if file:
		file.store_var({
			"quit_key": quit_shortcut_key,
			"chat_key": chat_toggle_key # Tambahkan ini
		})
		file.close()

func load_settings():
	if FileAccess.file_exists("user://settings.dat"):
		var file = FileAccess.open("user://settings.dat", FileAccess.READ)
		var data = file.get_var()
		quit_shortcut_key = data.get("quit_key", KEY_Q)
		chat_toggle_key = data.get("chat_key", KEY_TAB)
		file.close()
		
func check_quit_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == quit_shortcut_key:
			var scene_name = get_tree().current_scene.name
			if scene_name == "Init": 
				quit_requested.emit()
			elif scene_name == "MainMenu" or scene_name == "Control": 
				get_tree().quit()
			else:
				get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func is_quit_pressed(event: InputEvent) -> bool:
	if event is InputEventKey and event.pressed:
		if event.keycode == quit_shortcut_key:
			return true
	return false

func execute_offer_effect(offer_id: String):
	match offer_id:
		"soul_trade_01":
			var scene_tree = get_tree().current_scene
			var player = get_tree().current_scene.find_child("Player", true, false)
			var canvas_mod = scene_tree.find_child("CanvasModulate", true, false)
			
			if player:
				player.demonized(10)
				print("Efek dieksekusi ke Player")
			if canvas_mod:
				# RGBA(0, 0, 0, 255) di Godot dibaca sebagai Color(0, 0, 0, 1)
				canvas_mod.color = Color(0, 0, 0, 1) 
				print("Layar menjadi hitam")
		"TROLL_1":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.take_damage(10)
		"TROLL_2":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.take_damage(5)
		"TROLL_M_1":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.demonized(5)
		"TROLL_M_1":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.take_damage(5)
		"TROLL_BC_1":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.take_damage(5)
				player.demonized(5)
		"DEVIL_BC_1":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.take_damage(15)
				player.demonized(15)
				
func execute_offer_effect_rejection(offer_id: String):
	match offer_id:
		"soul_trade_01":
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player:
				player.take_damage(100) # Memanggil fungsi di player.gd
				print("Efek dieksekusi ke Player")
