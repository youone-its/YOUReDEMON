extends Node2D

@onready var save_btn = $save
@onready var back_btn = $back
@onready var label = $Label # Tambahkan ini agar debug muncul
@onready var quit_confirm_popup = $QuitConfirmation

func _ready():
	# Munculkan chat lama yang tersimpan di memori save (tanpa animasi)
	if LiveChat.has_method("reload_history"):
		LiveChat.reload_history()
	
	save_btn.pressed.connect(_on_save_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	GameData.quit_requested.connect(_show_quit_popup)
	$QuitConfirmation/VBoxContainer/SaveExitBtn.pressed.connect(_on_save_and_exit)
	$QuitConfirmation/VBoxContainer/JustExitBtn.pressed.connect(_on_just_exit)
	$QuitConfirmation/VBoxContainer/CancelBtn.pressed.connect(func(): quit_confirm_popup.hide())
	
	_update_debug_label()
	
	# Trigger chat baru HANYA jika ID-nya belum pernah ada
	if LiveChat.has_method("trigger_chat"):
		LiveChat.trigger_chat("welcome_event")

func _show_quit_popup():
	# Cek jika slot masih -1 (New Game)
	if GameData.current_slot == -1:
		var empty = GameData.find_empty_slot()
		if empty == 0:
			$QuitConfirmation/StatusLabel.text = "Slot Penuh! Timpa Slot 1?"
		else:
			$QuitConfirmation/StatusLabel.text = "Simpan ke Slot Baru (%d)?" % empty
	else:
		$QuitConfirmation/StatusLabel.text = "Simpan perubahan ke Slot %d?" % GameData.current_slot
	
	quit_confirm_popup.show()

func _on_save_and_exit():
	# Jika penuh dan ini New Game, kita paksa ke slot 1 (atau buat logic lain)
	if GameData.current_slot == -1 and GameData.find_empty_slot() == 0:
		GameData.current_slot = 1
		
	await _save_process()
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _on_just_exit():
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _save_process():
	await RenderingServer.frame_post_draw
	# Jalankan save data dulu untuk nentuin slot
	if GameData.save_game():
		var img = get_viewport().get_texture().get_image()
		var path = GameData.get_thumb_path(GameData.current_slot)
		img.save_png(path)
		print("Tersimpan di slot: ", GameData.current_slot)

func _update_debug_label():
	# Menampilkan data sesuai permintaanmu
	var slot_info = "NEW" if GameData.current_slot == -1 else str(GameData.current_slot)
	label.text = "SLOT: %s | HP: %d | Ritual: %d" % [slot_info, GameData.hp, GameData.demonized_level]
	label.text = "Scene: INIT\n"
	label.text += "Demonized Level: %d\n" % GameData.demonized_level
	label.text += "HP: %d\n" % GameData.hp
	label.text += "Items: %s\n" % str(GameData.items)
	label.text += "Posisi: (%d, %d)" % [GameData.player_position.x, GameData.player_position.y]

func _on_save_pressed():
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	
	# Mengambil path sesuai slot aktif
	var current_thumb_path = GameData.get_thumb_path(GameData.current_slot)
	img.save_png(current_thumb_path)
	
	GameData.save_game()
	_update_debug_label() # Update teks setelah save
	print("Berhasil simpan ke Slot: ", GameData.current_slot)

# PASTIKAN FUNGSI INI ADA DAN NAMANYA SAMA PERSIS
func _on_back_pressed():
	# Gunakan UID atau path res://
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _input(event):
	# 1. Cek apakah tombol shortcut quit ditekan
	if GameData.is_quit_pressed(event):
		# Pastikan input tidak diteruskan ke sistem lain
		get_viewport().set_input_as_handled()
		
		# 2. Munculkan panel konfirmasi, jangan langsung quit
		if has_node("QuitConfirmation"):
			$QuitConfirmation.show()
			# Jika kamu punya animasi atau suara saat panel muncul, taruh di sini
	
	# Input untuk live chat tetap jalan
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").check_chat_input(event)
