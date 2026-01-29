extends Control

@onready var back_btn = $BackButtonMargin/BackButton
@onready var edit_save_btn = $CenterContainer/VBoxContainer/EditSaveBtn
@onready var quit_trigger_btn = $CenterContainer/VBoxContainer/HBoxContainer/TriggerBtn

var is_editing: bool = false
var selected_command: String = ""

func _ready():
	GameData.load_settings()
	_update_ui()
	
	back_btn.pressed.connect(_on_back_pressed)
	edit_save_btn.pressed.connect(_on_edit_save_pressed)
	quit_trigger_btn.pressed.connect(_on_trigger_pressed.bind("quit"))

func _update_ui():
	quit_trigger_btn.text = OS.get_keycode_string(GameData.quit_shortcut_key)
	quit_trigger_btn.disabled = true
	edit_save_btn.text = "Edit"
	is_editing = false
	selected_command = ""

func _on_edit_save_pressed():
	if not is_editing:
		is_editing = true
		edit_save_btn.text = "Save"
		quit_trigger_btn.disabled = false
	else:
		GameData.save_settings()
		_update_ui()

func _on_trigger_pressed(command_name: String):
	if is_editing:
		selected_command = command_name
		quit_trigger_btn.text = "???"

func _input(event):
	# Prioritaskan remapping jika sedang mode edit
	if is_editing and selected_command != "":
		if event is InputEventKey and event.pressed:
			if selected_command == "quit":
				GameData.quit_shortcut_key = event.keycode
				quit_trigger_btn.text = OS.get_keycode_string(event.keycode)
				selected_command = "" 
	else:
		# Jika tidak sedang edit, jalankan fungsi shortcut normal
		GameData.check_quit_input(event)

func _on_back_pressed():
	get_tree().change_scene_to_file("uid://cnw4e8w572xwd")
