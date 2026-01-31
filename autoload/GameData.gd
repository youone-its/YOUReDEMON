extends Node

# Variabel Global untuk Data Pemain
var hp: int = 100
var demonized_level: int = 0
var items: Array = []
var player_position: Vector2 = Vector2(-1, -1)
var quit_shortcut_key: int = KEY_Q # Defaultnya tombol Q
var chat_toggle_key: int = KEY_TAB
var current_slot: int = -1 
var current_scene_path: String = ""
# --- DATA LIVE CHAT ---
var completed_chats: Array = [] # Menyimpan ID trigger/offer yang sudah selesai
var chat_history: Array = []    # Menyimpan isi pesan (teks & tipe) yang sudah muncul
var altars_status: Array = [false, false, false, false] # Simpan status 4 altar
signal quit_requested
var is_loading_from_save: bool = false

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
	completed_chats = []
	chat_history = [] # Reset history saat New Game agar bersih
	current_slot = -1
	altars_status = [false, false, false, false] # Reset saat New Game
	current_scene_path = ""
	is_loading_from_save = false

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
			"completed_chats": completed_chats,
			"chat_history": chat_history,
			"scene_path": current_scene_path, # TAMBAHKAN INI
			"altars_status": altars_status
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
		completed_chats = data.get("completed_chats", []) 
		chat_history = data.get("chat_history", []) # Ambil data history
		current_scene_path = data.get("scene_path", "")
		altars_status = data.get("altars_status", [false, false, false, false])
		
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
