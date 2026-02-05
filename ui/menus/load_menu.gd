extends Control

# Hubungkan sesuai hierarki PanelContent kamu
@onready var save_list = $MainHBox/LeftPanel/PanelContent/MarginContainer2/SaveList
@onready var back_btn = $MainHBox/LeftPanel/PanelContent/MarginContainer/BackButton

# Detail Panel Kanan
@onready var data_label = $MainHBox/RightPanel/RightMargin/ContentLayout/DataLabel
@onready var thumbnail = $MainHBox/RightPanel/RightMargin/ContentLayout/Thumbnail
@onready var confirm_btn = $MainHBox/RightPanel/RightMargin/ContentLayout/MarginContainer/VBoxContainer/ConfirmLoadBtn
@onready var delete_btn = $MainHBox/RightPanel/RightMargin/ContentLayout/MarginContainer/VBoxContainer/DeleteSlotBtn

# Variabel untuk melacak slot yang sedang dilihat
var selected_slot: int = 0

func _ready():
	# Inisialisasi tampilan
	confirm_btn.visible = false 
	data_label.text = "Pilih Slot untuk Melihat Detail"
	thumbnail.texture = null
	
	# Sembunyikan tombol delete di awal
	delete_btn.hide()
	delete_btn.pressed.connect(_on_delete_pressed)
	
	# Connect Button Statis
	confirm_btn.pressed.connect(_on_confirm_load_btn_pressed)
	if back_btn:
		back_btn.pressed.connect(_on_back_btn_pressed)
	
	refresh_save_list()

func refresh_save_list():
	# Bersihkan daftar lama
	save_list.add_theme_constant_override("separation", 5)
	for child in save_list.get_children():
		child.queue_free()
	
	var found_any = false
	
	# Cek Slot 1 sampai 3 (Sesuai batas maksimal 3 slot)
	for i in range(1, 4):
		if FileAccess.file_exists(GameData.get_save_path(i)):
			_create_slot_button(i)
			found_any = true
	
	if not found_any:
		var empty_label = Label.new()
		empty_label.text = "Tidak ada data simpanan."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_list.add_child(empty_label)
		# Sembunyikan UI detail jika tidak ada data sama sekali
		_reset_preview_ui()

func _create_slot_button(slot_num: int):
	var btn = Button.new()
	btn.text = "Save Slot %d" % slot_num
	btn.custom_minimum_size.y = 80
	btn.pressed.connect(_show_preview.bind(slot_num))
	save_list.add_child(btn)

func _show_preview(slot_num: int):
	GameData.play_click_sound()
	selected_slot = slot_num
	var data = GameData.load_data_from_slot(slot_num)
	
	if data:
		# Update Teks
		var txt = "--- DATA SLOT %d ---\n\n" % slot_num
		txt += "❤️ HP: %d\n" % data.hp
		txt += "🔥 Level: %d\n" % data.demonized_level
		txt += "📍 Posisi: %d, %d" % [data.pos_x, data.pos_y]
		data_label.text = txt
		
		# Update Thumbnail
		var t_path = GameData.get_thumb_path(slot_num)
		if FileAccess.file_exists(t_path):
			var img = Image.load_from_file(t_path)
			thumbnail.texture = ImageTexture.create_from_image(img)
		else:
			thumbnail.texture = null
		
		# Munculkan tombol navigasi dan hapus
		confirm_btn.visible = true
		delete_btn.show()
		confirm_btn.grab_focus()

func _on_confirm_load_btn_pressed():
	GameData.play_click_sound()
	if selected_slot > 0:
		# Panggil ulang load untuk memastikan is_loading_from_save = true
		GameData.load_data_from_slot(selected_slot)
		
		if GameData.current_scene_path != "":
			get_tree().change_scene_to_file(GameData.current_scene_path)
		else:
			# Scene fallback
			get_tree().change_scene_to_file("uid://bae2wiyqxmjrm")

func _on_delete_pressed():
	GameData.play_click_sound()
	if selected_slot > 0:
		# Jalankan penghapusan file
		GameData.delete_save_slot(selected_slot)
		
		# Reset pilihan dan refresh UI
		selected_slot = 0
		_reset_preview_ui()
		refresh_save_list()

func _reset_preview_ui():
	data_label.text = "Pilih Slot untuk Melihat Detail"
	thumbnail.texture = null
	confirm_btn.visible = false
	delete_btn.hide()

func _on_back_btn_pressed():
	GameData.play_click_sound()
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")

func _input(event):
	GameData.check_quit_input(event)
