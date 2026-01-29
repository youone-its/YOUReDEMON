extends Control

# Hubungkan sesuai hierarki PanelContent kamu
@onready var save_list = $MainHBox/LeftPanel/PanelContent/MarginContainer2/SaveList
@onready var back_btn = $MainHBox/LeftPanel/PanelContent/MarginContainer/BackButton

# Detail Panel Kanan
@onready var data_label = $MainHBox/RightPanel/RightMargin/ContentLayout/DataLabel
@onready var thumbnail = $MainHBox/RightPanel/RightMargin/ContentLayout/Thumbnail
@onready var confirm_btn = $MainHBox/RightPanel/RightMargin/ContentLayout/MarginContainer/ConfirmLoadBtn

func _ready():
	# Inisialisasi tampilan
	confirm_btn.visible = false # Sembunyikan tombol Select di awal
	data_label.text = "Pilih Slot untuk Melihat Detail"
	thumbnail.texture = null
	
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
	
	# Cek Slot 1 sampai 5 (bisa ditambah sesuai kebutuhan)
	for i in range(1, 6):
		if FileAccess.file_exists(GameData.get_save_path(i)):
			_create_slot_button(i)
			found_any = true
	
	if not found_any:
		var empty_label = Label.new()
		empty_label.text = "Tidak ada data simpanan."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		save_list.add_child(empty_label)

func _create_slot_button(slot_num: int):
	var btn = Button.new()
	btn.text = "Save Slot %d" % slot_num
	btn.custom_minimum_size.y = 80
	# Gunakan bind untuk mengirim nomor slot saat ditekan
	btn.pressed.connect(_show_preview.bind(slot_num))
	save_list.add_child(btn)

func _show_preview(slot_num: int):
	# Ambil data tanpa mengubah scene dulu
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
		
		# Munculkan tombol Select
		confirm_btn.visible = true
		confirm_btn.grab_focus()

func _on_confirm_load_btn_pressed():
	# GameData.current_slot sudah ter-update di _show_preview
	get_tree().change_scene_to_file("uid://bae2wiyqxmjrm")

func _on_back_btn_pressed():
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")



















func _input(event):
	GameData.check_quit_input(event)
