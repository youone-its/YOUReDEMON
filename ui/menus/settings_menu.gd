extends Control

@onready var back_btn = $BackButtonMargin/BackButton
@onready var edit_save_btn = $CenterContainer/VBoxContainer/EditSaveBtn
@onready var quit_trigger_btn = $CenterContainer/VBoxContainer/HBoxContainer/TriggerBtn
@onready var chat_trigger_btn = $CenterContainer/VBoxContainer/HBoxContainer2/ChatTriggerBtn # Pastikan path ini benar

var is_editing: bool = false
var selected_command: String = ""

func _ready():
	GameData.load_settings()
	_update_ui()
	
	back_btn.pressed.connect(_on_back_pressed)
	edit_save_btn.pressed.connect(_on_edit_save_pressed)
	quit_trigger_btn.pressed.connect(_on_trigger_pressed.bind("quit"))
	chat_trigger_btn.pressed.connect(_on_trigger_pressed.bind("toggle_chat"))

func _update_ui():
	quit_trigger_btn.text = OS.get_keycode_string(GameData.quit_shortcut_key)
	chat_trigger_btn.text = OS.get_keycode_string(GameData.chat_toggle_key)
	quit_trigger_btn.disabled = true
	chat_trigger_btn.disabled = true
	edit_save_btn.text = "Edit"
	is_editing = false
	selected_command = ""

func _on_edit_save_pressed():
	GameData.play_click_sound()
	if not is_editing:
		is_editing = true
		edit_save_btn.text = "Save"
		quit_trigger_btn.disabled = false
		chat_trigger_btn.disabled = false
	else:
		# Proses Save
		GameData.save_settings()
		_update_ui() # Reset status editing dan teks tombol
		
func _on_trigger_pressed(command_name: String):
	GameData.play_click_sound()
	if is_editing:
		selected_command = command_name
		# Hanya tombol yang diklik yang berubah jadi ???
		if command_name == "quit":
			quit_trigger_btn.text = "???"
		elif command_name == "toggle_chat":
			chat_trigger_btn.text = "???"
			
func _input(event):
	if is_editing and selected_command != "":
		if event is InputEventKey and event.pressed:
			# Masukkan key baru ke GameData
			if selected_command == "quit":
				GameData.quit_shortcut_key = event.keycode
				quit_trigger_btn.text = OS.get_keycode_string(event.keycode)
			elif selected_command == "toggle_chat":
				GameData.chat_toggle_key = event.keycode
				chat_trigger_btn.text = OS.get_keycode_string(event.keycode)
			
			# PENTING: Reset selected_command agar tidak menimpa saat tekan key lain
			selected_command = "" 
			# JANGAN panggil _update_ui() di sini agar tombol Save tidak berubah jadi Edit sebelum diklik
	else:
		GameData.check_quit_input(event)
		if has_node("/root/LiveChat"):
			get_node("/root/LiveChat").check_chat_input(event)
			
func _on_back_pressed():
	GameData.play_click_sound()
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")
