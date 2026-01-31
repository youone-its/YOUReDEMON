extends Control

@onready var hp_bar = $CanvasLayer/VBoxContainer/HPBar
@onready var demon_bar = $CanvasLayer/VBoxContainer/DemonBar
@onready var quit_confirm_popup = $CanvasLayer/QuitConfirmation

func _ready():
	# 1. Inisialisasi Visual
	_update_hud_visuals()
	quit_confirm_popup.hide()
	
	# 2. Setup LiveChat
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").visible = true
		if LiveChat.has_method("reload_history"):
			LiveChat.reload_history()
		
		# Trigger chat pembuka jika diperlukan (opsional)
		if LiveChat.has_method("trigger_chat"):
			LiveChat.trigger_chat("welcome_event")
	
	# 3. Koneksi Signal
	$CanvasLayer/QuitConfirmation/VBoxContainer/SaveExitBtn.pressed.connect(_on_save_and_exit)
	$CanvasLayer/QuitConfirmation/VBoxContainer/JustExitBtn.pressed.connect(_on_just_exit)
	$CanvasLayer/QuitConfirmation/VBoxContainer/CancelBtn.pressed.connect(_on_cancel_pressed)
	
	if not GameData.quit_requested.is_connected(_show_quit_popup):
		GameData.quit_requested.connect(_show_quit_popup)

func _process(_delta):
	_update_hud_visuals()

func _update_hud_visuals():
	hp_bar.value = GameData.hp
	demon_bar.value = GameData.demonized_level

func _show_quit_popup():
	var status_label = $CanvasLayer/QuitConfirmation/StatusLabel
	if GameData.current_slot == -1:
		var empty = GameData.find_empty_slot()
		status_label.text = "Slot Penuh! Timpa Slot 1?" if empty == 0 else "Simpan ke Slot Baru (%d)?" % empty
	else:
		status_label.text = "Simpan progress ke Slot %d?" % GameData.current_slot
	
	# PAUSE GAME saat popup muncul
	get_tree().paused = true
	quit_confirm_popup.show()

func _on_save_and_exit():
	get_tree().paused = false
	# Hapus baris sync_to_gamedata di sini, biar diurus di _save_process saja
	await _save_process()
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _on_just_exit():
	get_tree().paused = false
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _save_process():
	var current_scene = get_tree().current_scene
	
	if current_scene.has_method("sync_to_gamedata"):
		current_scene.sync_to_gamedata()
	
	# 2. Ambil posisi player TERBARU
	var player = current_scene.find_child("Player", true, false)
	if player:
		GameData.player_position = player.global_position
		
	await RenderingServer.frame_post_draw
	if GameData.save_game():
		var img = get_viewport().get_texture().get_image()
		var path = GameData.get_thumb_path(GameData.current_slot)
		img.save_png(path)

func _input(event):
	# 1. Shortcut Quit (Q)
	if GameData.is_quit_pressed(event):
		get_viewport().set_input_as_handled()
		_show_quit_popup()
	
	# 2. Logika LiveChat
	if has_node("/root/LiveChat"):
		var chat = get_node("/root/LiveChat")
		
		# Toggle Visibility (TAB)
		if event is InputEventKey and event.pressed:
			if event.keycode == GameData.chat_toggle_key:
				chat.visible = !chat.visible
				get_viewport().set_input_as_handled()
		
		# PROSES INPUT INTERNAL CHAT (Penting agar chat muncul/jalan)
		if chat.has_method("check_chat_input"):
			chat.check_chat_input(event)

func _on_cancel_pressed():
	# UNPAUSE GAME saat kembali bermain
	get_tree().paused = false
	quit_confirm_popup.hide()
