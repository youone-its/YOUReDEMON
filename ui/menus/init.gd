extends Control

# --- HUD & SYSTEM ---
@onready var hp_bar = $CanvasLayer/VBoxContainer/HPBar
@onready var demon_bar = $CanvasLayer/VBoxContainer/DemonBar
@onready var quit_confirm_popup = $CanvasLayer/QuitConfirmation

# --- UI INVENTORY BARU ---
@onready var inventory_window = $CanvasLayer/InventoryWindow # Background Tas
@onready var grid_barang = $CanvasLayer/InventoryWindow/GridBarang # GridContainer

func _ready():
	# 1. Inisialisasi Visual
	_update_hud_visuals()
	inventory_window.hide()
	quit_confirm_popup.hide()
	
	# Pastikan script ini tetap berjalan saat game di-Pause (untuk UI)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. Setup LiveChat (Fitur Lamamu)
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").visible = true
		if LiveChat.has_method("reload_history"):
			LiveChat.reload_history()
		
	
	# 3. Koneksi Signal Popup (Fitur Lamamu)
	$CanvasLayer/QuitConfirmation/VBoxContainer/SaveExitBtn.pressed.connect(_on_save_and_exit)
	$CanvasLayer/QuitConfirmation/VBoxContainer/JustExitBtn.pressed.connect(_on_just_exit)
	$CanvasLayer/QuitConfirmation/VBoxContainer/CancelBtn.pressed.connect(_on_cancel_pressed)
	
	if GameData.is_loading_from_save:
		# items di init.gd = items di GameData
		_refresh_inventory_ui()
	if not GameData.quit_requested.is_connected(_show_quit_popup):
		GameData.quit_requested.connect(func(): _show_quit_popup(GameData.hp <= 0 || GameData.demonized_level >= 100))

func _process(_delta):
	_update_hud_visuals()
	
	# Shortcut Angka 1: Menggunakan item yang sedang di-Fokus (WASD)
	if inventory_window.visible and Input.is_action_just_pressed("ui_accept"): # Atau ganti KEY_1
		var fokus = get_viewport().gui_get_focus_owner()
		if fokus and fokus.get_parent() == grid_barang:
			_pakai_item_terpilih(fokus)

func _update_hud_visuals():
	hp_bar.value = GameData.hp
	demon_bar.value = GameData.demonized_level

func _input(event):
	# 1. Shortcut Quit (Q) - Fitur Lamamu
	if GameData.is_quit_pressed(event):
		get_viewport().set_input_as_handled()
		_show_quit_popup()
		return

	# 2. Toggle Inventory (SPACE) - Fitur Baru
	# Fallback manual key check incase input action is missing/borked
	var is_toggle = event.is_action_pressed("toggle_inventory")
	if not is_toggle and event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_I:
			is_toggle = true
			
	if is_toggle:
		if GameData.is_cutscene_playing:
			return
			
		_toggle_inventory()
		get_viewport().set_input_as_handled()
		return

	# 3. Logika Chat (TAB) - Fitur Lamamu
	if event is InputEventKey and event.pressed:
		if event.keycode == GameData.chat_toggle_key:
			if has_node("/root/LiveChat"):
				var chat = get_node("/root/LiveChat")
				
				# Pastikan ini memanggil toggle_chat() sesuai nama baru
				if chat.has_method("toggle_chat"): 
					chat.toggle_chat()
					get_viewport().set_input_as_handled() # Hentikan input di sini
					return # Keluar agar tidak kena check_chat_input lagi di bawah
				
	if has_node("/root/LiveChat"):
		var chat = get_node("/root/LiveChat")
		if chat.has_method("check_chat_input"):
			chat.check_chat_input(event)

# --- LOGIKA INVENTORY ---

func _toggle_inventory():
	print("Toggling Inventory! Current: ", inventory_window.visible)
	inventory_window.visible = !inventory_window.visible
	get_tree().paused = inventory_window.visible # Pause game saat buka tas
	
	if inventory_window.visible:
		_refresh_inventory_ui()
		# Auto-fokus ke item pertama agar WASD langsung jalan
		if grid_barang.get_child_count() > 0:
			grid_barang.get_child(0).grab_focus()

func tambah_item_ke_tas(item_id: String, icon_path: String) -> bool:
	if GameData.items.size() >= 12: # Misal max 12 slot
		print("Tas Penuh!")
		return false
	
	GameData.items.append({"id": item_id, "path": icon_path})
	print("Berhasil mengambil: ", item_id)
	return true

func _refresh_inventory_ui():
	# Bersihkan visual grid lama
	for n in grid_barang.get_children():
		n.queue_free()
	
	# Buat button baru untuk tiap item di GameData
	for data in GameData.items:
		var btn = Button.new()
		btn.icon = load(data["path"])
		btn.expand_icon = true
		btn.custom_minimum_size = Vector2(80, 80)
		btn.focus_mode = Control.FOCUS_ALL # Penting untuk WASD
		
		btn.set_meta("item_id", data["id"])
		btn.pressed.connect(func(): _pakai_item_terpilih(btn))
		
		grid_barang.add_child(btn)

func _pakai_item_terpilih(btn_node: Button):
	GameData.play_click_sound()
	var id = btn_node.get_meta("item_id")
	print("Menggunakan: ", id)
	var player = get_tree().get_first_node_in_group("player")
	
	if id == "flashlight":
		if player:
			player.toggle_flashlight()
	
	# Contoh Logika Potion
	if id == "potion":
		if GameData.hp < 100:
			GameData.hp = min(GameData.hp + 30, 100)
			GameData.items.remove_at(btn_node.get_index())
			_refresh_inventory_ui()
	
	# Jika item masih ada, kembalikan fokus agar WASD tidak hilang
	if grid_barang.get_child_count() > 0:
		grid_barang.get_child(0).grab_focus()

# --- LOGIKA SYSTEM (SAVE/EXIT) - Fitur Lamamu ---

func _show_quit_popup(is_death: bool = false):
	get_tree().paused = true
	quit_confirm_popup.show()
	
	if is_death:
		$CanvasLayer.layer = 1200 # Pastikan di atas Death Layer (1100)
		if has_node("CanvasLayer/VBoxContainer"): # Hide HUD
			$CanvasLayer/VBoxContainer.hide()
			
		$CanvasLayer/QuitConfirmation/StatusLabel.text = "YOU ARE DEAD"
		$CanvasLayer/QuitConfirmation/VBoxContainer/CancelBtn.hide()
	else:
		$CanvasLayer/QuitConfirmation/StatusLabel.text = "Pause Game"
		$CanvasLayer/QuitConfirmation/VBoxContainer/CancelBtn.show()

func _on_save_and_exit():
	GameData.play_click_sound()
	# 1. Cari Root Node untuk sinkronisasi posisi terakhir
	var root = get_tree().current_scene
	if root.has_method("prepare_save_data"):
		root.prepare_save_data()
	
	# 2. Ambil screenshot thumbnail (opsional tapi keren buat Load Menu)
	await _take_screenshot()
	
	# 3. Eksekusi Save Game yang sebenarnya ke file .dat
	if GameData.save_game():
		print("Save Berhasil!")
		get_tree().paused = false
		get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _on_just_exit():
	GameData.play_click_sound()
	get_tree().paused = false
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _on_cancel_pressed():
	GameData.play_click_sound()
	get_tree().paused = false
	quit_confirm_popup.hide()

func _take_screenshot():
	# Menunggu frame selesai digambar agar screenshot tidak hitam
	await RenderingServer.frame_post_draw
	
	# Mengambil gambar dari viewport
	var img = get_viewport().get_texture().get_image()
	
	# Mengambil path slot dari GameData
	var path = GameData.get_thumb_path(GameData.current_slot)
	
	# Simpan sebagai PNG
	img.save_png(path)
	print("Thumbnail tersimpan di: ", path)
