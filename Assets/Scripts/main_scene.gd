extends Control

# Pastikan path ini sesuai dengan VBoxContainer tempat tombol-tombol kamu berada
@onready var buttons_container = $MarginContainer/VBoxContainer
@onready var slot_full_dialog = $SlotFullDialog

func _ready():
	# Inisialisasi setiap tombol di dalam container
	for btn in buttons_container.get_children():
		if btn is Button:
			# Signal untuk navigasi klik
			btn.pressed.connect(_on_button_pressed.bind(btn.name))
			
			# Signal untuk animasi hover (geser ke kanan)
			btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").visible = false

# --- SISTEM ANIMASI HOVER ---
func _on_button_hover(btn: Button, is_hover: bool):
	# Jika hover geser ke kanan 20 pixel, jika tidak kembali ke 0
	var target_pos = 20.0 if is_hover else 0.0
	var tween = create_tween()
	
	# Animasi perpindahan posisi X tombol secara halus
	tween.tween_property(btn, "position:x", target_pos, 0.2)\
		.set_trans(Tween.TRANS_QUART)\
		.set_ease(Tween.EASE_OUT)

# --- SISTEM NAVIGASI ---
func _on_button_pressed(button_name: String):
	match button_name:
		"NewGameBtn":
			if GameData.find_empty_slot() > 0:
				GameData.reset_data()
				get_tree().change_scene_to_file("uid://bae2wiyqxmjrm")
			else:
				slot_full_dialog.popup_centered()
		
		"LoadGameBtn":
			# Pindah ke scene Load Game
			get_tree().change_scene_to_file("uid://v1s6jea7hlcr")
		
		"OptionsBtn":
			# Pindah ke scene Settings
			get_tree().change_scene_to_file("res://settings.tscn")
		
		"QuitBtn":
			# Keluar dari game
			get_tree().quit()

# --- INPUT SHORTCUT GLOBAL ---
func _input(event):
	# Menjalankan pengecekan tombol Q (Quit) dari GameData
	# Karena ini di Main Menu, GameData akan memicu get_tree().quit()
	GameData.check_quit_input(event)
