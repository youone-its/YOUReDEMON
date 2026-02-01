extends Node2D

# --- Node References ---
@onready var player = $Player
@onready var game_ui = $Node2D  # Ini adalah node hijau (Instanced Scene UI)
@onready var chat_box = $Node2D/LiveChat/Control/ScrollContainer/ChatBox # Sesuaikan path-nya
@onready var scroll_container = $Node2D/LiveChat/Control/ScrollContainer

# --- Data untuk Save System ---
var save_path = "user://tutorial_data.save"
var tutorial_stats = {
	"health": 100,
	"mana": 50,
	"progress": "started"
}

func _ready():
	# Memuat data lama jika ada
	load_game()
	
	# Update Status Bar saat mulai
	update_status_bar()
	
	# Sembunyikan Quit Confirmation bawaan dari instanced scene
	if game_ui.has_node("QuitPanel"):
		game_ui.get_node("QuitPanel").hide()

# --- Fitur Status Bar ---
func update_status_bar():
	# Asumsi di dalam node UI ada fungsi update_stats atau bar HP/MP
	if game_ui.has_method("update_display"):
		game_ui.update_display(tutorial_stats.health, tutorial_stats.mana)

# --- Fitur Save & Load (Format JSON) ---
func save_game():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(tutorial_stats)
		file.store_line(json_string)
		file.close()
		print("Tutorial Progress Saved!")

func load_game():
	if not FileAccess.file_exists(save_path):
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var data = JSON.parse_string(json_string)
		if data:
			tutorial_stats = data
			print("Tutorial Progress Loaded!")

# --- Fitur LiveChat (Tutorial Style) ---
func add_tutorial_msg(text: String):
	var msg_label = Label.new()
	msg_label.text = text
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	msg_label.custom_minimum_size.x = 200 # Batas lebar teks agar tidak meluber
	
	chat_box.add_child(msg_label)
	
	# Auto-scroll ke pesan terbaru
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

# --- Fitur Quit Confirmation (Input handling) ---
func _input(event):
	if event.is_action_pressed("ui_cancel"): # Biasanya tombol ESC
		show_quit_menu()

func show_quit_menu():
	# Panggil fungsi quit yang ada di dalam node UI hijau
	if game_ui.has_method("toggle_quit_confirm"):
		game_ui.toggle_quit_confirm()
	else:
		# Jika tidak ada fungsi di dalam, kita paksa show node-nya
		var quit_node = game_ui.find_child("Quit*", true, false)
		if quit_node: quit_node.show()
