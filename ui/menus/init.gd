extends Control

@onready var hp_bar = $CanvasLayer/VBoxContainer/HPBar
@onready var demon_bar = $CanvasLayer/VBoxContainer/DemonBar
@onready var quit_confirm_popup = $CanvasLayer/QuitConfirmation

# --- UI INVENTORY ---
@onready var icon_l = $CanvasLayer/InventoryBar/Slot_L/ItemIcon_L
@onready var icon_r = $CanvasLayer/InventoryBar/Slot_R/ItemIcon_R

# Mapping Item ke Gambar (Gunakan .jpeg sesuai filemu)
var item_textures = {
	"flashlight": preload("res://assets/items/flashlight.jpeg"),
	"key": preload("res://assets/items/key.jpeg"),
	"potion": preload("res://assets/items/potion.jpeg"),
	"none": null
}

func _ready():
	# 1. Inisialisasi Visual
	_update_hud_visuals()
	_update_inventory_visuals()
	quit_confirm_popup.hide()
	
	# 2. Setup LiveChat
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").visible = true
		if LiveChat.has_method("reload_history"):
			LiveChat.reload_history()
		if LiveChat.has_method("trigger_chat"):
			LiveChat.trigger_chat("welcome_event")
	
	# 3. Koneksi Signal Popup
	$CanvasLayer/QuitConfirmation/VBoxContainer/SaveExitBtn.pressed.connect(_on_save_and_exit)
	$CanvasLayer/QuitConfirmation/VBoxContainer/JustExitBtn.pressed.connect(_on_just_exit)
	$CanvasLayer/QuitConfirmation/VBoxContainer/CancelBtn.pressed.connect(_on_cancel_pressed)
	
	if not GameData.quit_requested.is_connected(_show_quit_popup):
		GameData.quit_requested.connect(_show_quit_popup)

func _process(_delta):
	_update_hud_visuals()
	_update_inventory_visuals()

func _update_hud_visuals():
	hp_bar.value = GameData.hp
	demon_bar.value = GameData.demonized_level

func _update_inventory_visuals():
	# Update icon berdasarkan string yang tersimpan di GameData
	icon_l.texture = item_textures.get(GameData.item_left, null)
	icon_r.texture = item_textures.get(GameData.item_right, null)

func _input(event):
	# 1. Shortcut Quit (Q)
	if GameData.is_quit_pressed(event):
		get_viewport().set_input_as_handled()
		_show_quit_popup()
	
	# 2. Logika LiveChat & Inventory Shortcut
	if event is InputEventKey and event.pressed:
		# Toggle Chat (TAB)
		if has_node("/root/LiveChat"):
			var chat = get_node("/root/LiveChat")
			if event.keycode == GameData.chat_toggle_key:
				chat.visible = !chat.visible
				get_viewport().set_input_as_handled()
		
		# --- LOGIKA INVENTORY ---
		# Tekan 1: Buang/Gunakan tangan kiri
		if event.keycode == KEY_1:
			_handle_item_interaction("left")
		# Tekan 2: Buang/Gunakan tangan kanan
		elif event.keycode == KEY_2:
			_handle_item_interaction("right")

	# Proses input internal chat
	if has_node("/root/LiveChat"):
		var chat = get_node("/root/LiveChat")
		if chat.has_method("check_chat_input"):
			chat.check_chat_input(event)

# Fungsi untuk menangani apakah item mau dipakai (Potion) atau dibuang
func _handle_item_interaction(side: String):
	var item_name = GameData.item_left if side == "left" else GameData.item_right
	
	if item_name == "none": return
	
	# Jika Potion, maka gunakan (Heal)
	if item_name == "potion":
		if GameData.hp < 100:
			GameData.hp = min(GameData.hp + 30, 100)
			_remove_item(side)
			print("Healed! HP: ", GameData.hp)
	# Jika item lain (Senter/Kunci), maka buang ke lantai
	else:
		_drop_item(side)

func _drop_item(side: String):
	var item_name = GameData.item_left if side == "left" else GameData.item_right
	_spawn_item_on_ground(item_name)
	_remove_item(side)

func _remove_item(side: String):
	if side == "left": GameData.item_left = "none"
	else: GameData.item_right = "none"

func _spawn_item_on_ground(item_name: String):
	var player = get_tree().current_scene.find_child("Player", true, false)
	if player:
		var drop_scene = load("res://scenes/items/ItemDrop.tscn")
		if drop_scene:
			var drop = drop_scene.instantiate()
			drop.item_type = item_name
			# Munculkan di depan player sedikit
			drop.global_position = player.global_position + Vector2(25, 0)
			get_tree().current_scene.add_child(drop)

# --- LOGIKA SYSTEM (SAVE/EXIT) ---

func _show_quit_popup():
	var status_label = $CanvasLayer/QuitConfirmation/StatusLabel
	if GameData.current_slot == -1:
		var empty = GameData.find_empty_slot()
		status_label.text = "Slot Penuh! Timpa Slot 1?" if empty == 0 else "Simpan ke Slot Baru (%d)?" % empty
	else:
		status_label.text = "Simpan progress ke Slot %d?" % GameData.current_slot
	
	get_tree().paused = true
	quit_confirm_popup.show()

func _on_save_and_exit():
	get_tree().paused = false
	await _save_process()
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _on_just_exit():
	get_tree().paused = false
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _save_process():
	var current_scene = get_tree().current_scene
	if current_scene.has_method("sync_to_gamedata"):
		current_scene.sync_to_gamedata()
	
	var player = current_scene.find_child("Player", true, false)
	if player:
		GameData.player_position = player.global_position
		
	await RenderingServer.frame_post_draw
	if GameData.save_game():
		var img = get_viewport().get_texture().get_image()
		var path = GameData.get_thumb_path(GameData.current_slot)
		img.save_png(path)

func _on_cancel_pressed():
	get_tree().paused = false
	quit_confirm_popup.hide()
