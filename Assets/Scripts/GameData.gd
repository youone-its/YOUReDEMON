extends Node

# Variabel Global untuk Data Pemain
var hp: int = 100
var demonized_level: int = 0
var items: Array = []
var player_position: Vector2 = Vector2(0, 0)
var quit_shortcut_key: int = KEY_Q # Defaultnya tombol Q
var chat_toggle_key: int = KEY_TAB
var current_slot: int = 1 

# --- DATA LIVE CHAT ---
var completed_chats: Array = [] # Menyimpan ID trigger/offer yang sudah selesai
var chat_history: Array = []    # Menyimpan isi pesan (teks & tipe) yang sudah muncul

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
	player_position = Vector2(0, 0)
	completed_chats = []
	chat_history = [] # Reset history saat New Game agar bersih

func save_game():
	var file = FileAccess.open(get_save_path(current_slot), FileAccess.WRITE)
	if file:
		var data = {
			"hp": hp,
			"demonized_level": demonized_level,
			"items": items,
			"pos_x": player_position.x,
			"pos_y": player_position.y,
			"completed_chats": completed_chats,
			"chat_history": chat_history # Simpan history ke file save
		}
		file.store_var(data)
		file.close()
		print("Game saved to slot: ", current_slot)

func load_data_from_slot(slot: int):
	var path = get_save_path(slot)
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var data = file.get_var()
		
		hp = data["hp"]
		demonized_level = data["demonized_level"]
		items = data["items"]
		player_position = Vector2(data["pos_x"], data["pos_y"])
		completed_chats = data.get("completed_chats", []) 
		chat_history = data.get("chat_history", []) # Ambil data history
		
		current_slot = slot 
		file.close()
		
		# Pemicu agar LiveChat menampilkan kembali history setelah loading
		if has_node("/root/LiveChat"):
			get_node("/root/LiveChat").reload_history()
			
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
			if get_tree().current_scene.name == "MainScene":
				get_tree().quit()
			else:
				get_tree().change_scene_to_file("uid://cnw4e8w572xwd")
