extends Node2D

@onready var save_btn = $save
@onready var back_btn = $back
@onready var label = $Label # Tambahkan ini agar debug muncul

func _ready():
	# Munculkan chat lama yang tersimpan di memori save (tanpa animasi)
	if LiveChat.has_method("reload_history"):
		LiveChat.reload_history()
	
	save_btn.pressed.connect(_on_save_pressed)
	back_btn.pressed.connect(_on_back_pressed)
	
	_update_debug_label()
	
	# Trigger chat baru HANYA jika ID-nya belum pernah ada
	if LiveChat.has_method("trigger_chat"):
		LiveChat.trigger_chat("welcome_event")

func _update_debug_label():
	# Menampilkan data sesuai permintaanmu
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
	GameData.check_quit_input(event)
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").check_chat_input(event)
