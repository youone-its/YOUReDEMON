extends Node2D

# --- Node References ---
var player
var game_ui
var chat_box
var scroll_container

# --- Data untuk Save System ---
var save_path = "user://tutorial_data.save"
var tutorial_stats = {
	"health": 100,
	"mana": 50,
	"progress": "started"
}

var skip_ui_timer: float = 0.0

func _ready():
	# Initialize references safely
	player = get_node_or_null("Player")
	game_ui = get_node_or_null("Node2D")
	
	if has_node("LiveChat/Control/ScrollContainer/ChatBox"):
		chat_box = $LiveChat/Control/ScrollContainer/ChatBox
		scroll_container = $LiveChat/Control/ScrollContainer

	# Memuat data lama jika ada
	if GameData.is_loading_from_save and GameData.player_position != Vector2(-1, -1):
		if player:
			player.global_position = GameData.player_position
		# Reset flag setelah digunakan agar tidak teleport terus saat ganti scene biasa
		GameData.is_loading_from_save = false
	load_game()
	
	# Update Status Bar saat mulai
	update_status_bar()
	
	# Sembunyikan Quit Confirmation bawaan dari instanced scene
	if game_ui and game_ui.has_node("QuitPanel"):
		game_ui.get_node("QuitPanel").hide()
	
	_check_and_play_intro()

func _check_and_play_intro():
	# Cek apakah ini map "node_2dz" yang punya Cutscenes/Intro
	if has_node("Cutscenes/Intro") and not GameData.intro_played and not GameData.is_loading_from_save:
		GameData.intro_played = true # Tandai sudah diputar
		play_intro_sequence()

func play_intro_sequence():
	var video_player = $Cutscenes/Intro
	
	# Hide LiveChat during intro
	var live_chat = get_node_or_null("/root/LiveChat")
	var was_chat_visible = false
	if live_chat:
		was_chat_visible = live_chat.visible
		live_chat.visible = false
		
	var cutscene_layer = CanvasLayer.new()
	# LiveChat is on Layer 1000, so we need to be higher to cover it
	cutscene_layer.layer = 1200 
	add_child(cutscene_layer)
	
	# Background hitam
	var color_rect = ColorRect.new()
	color_rect.color = Color.BLACK
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	cutscene_layer.add_child(color_rect)
	
	# Pindahkan VideoPlayer ke Layer UI DULUAN agar di belakang Label
	video_player.reparent(cutscene_layer)
	video_player.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Pastikan mouse filter ignore agar tidak memblokir input mouse
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	video_player.show()
	
	# Skip Prompt UI (Tambahkan SETELAH VideoPlayer agar di atasnya)
	var skip_label = Label.new()
	skip_label.text = "Hold ENTER to Skip"
	# Mengatur font size agar lebih mudah dibaca
	skip_label.add_theme_font_size_override("font_size", 24)
	
	# Setup anchors untuk pojok kanan bawah
	skip_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	skip_label.anchor_left = 1.0
	skip_label.anchor_top = 1.0
	skip_label.anchor_right = 1.0
	skip_label.anchor_bottom = 1.0
	skip_label.offset_left = -350
	skip_label.offset_top = -80
	skip_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skip_label.modulate.a = 1.0 # Mulai terlihat agar user tahu ada fitur ini
	skip_ui_timer = 5.0 # Tampilkan 5 detik pertama
	cutscene_layer.add_child(skip_label)
	
	# Stop Player
	if player:
		player.speed = 0
		player.set_physics_process(false)
		
	# Play
	# Gunakan Callable untuk signal
	# VIDEO FIX: Gunakan array untuk menyimpan state agar bisa diubah di dalam lambda
	var state = {"finished": false}
	var finish_callback = func(): state.finished = true
	
	if not video_player.finished.is_connected(finish_callback):
		video_player.finished.connect(finish_callback)
	
	video_player.play()
	
	# Wait for finish OR skip
	var skip_progress = 0.0
	var hold_duration = 1.5
	var safety_timer = 60.0 # Safety timeout (e.g. video max length)
	
	# Loop manual agar aman dari glitch is_playing()
	while not state.finished:
		await get_tree().process_frame
		var delta = get_process_delta_time()
		
		# Safety Timeout
		safety_timer -= delta
		if safety_timer <= 0:
			print("Video Intro Timeout - Forcing Skip")
			break
		
		# Logika UI Fade
		if skip_ui_timer > 0:
			skip_ui_timer -= delta
			skip_label.modulate.a = move_toward(skip_label.modulate.a, 1.0, delta * 5)
		else:
			skip_label.modulate.a = move_toward(skip_label.modulate.a, 0.0, delta * 2)
			
		# Check Hold Enter or Space or Click
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_SPACE) or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			skip_progress += delta
			skip_ui_timer = 2.0 # Keep visible upon interaction
			skip_label.text = "Skipping... %d%%" % int((skip_progress / hold_duration) * 100)
			skip_label.modulate.a = 1.0 # Force visible immediately
			
			if skip_progress >= hold_duration:
				print("Intro Skipped by User")
				video_player.stop()
				break
		else:
			skip_progress = 0.0
			skip_label.text = "Hold ENTER to Skip"
	
	# Cleanup Connection
	if video_player.finished.is_connected(finish_callback):
		video_player.finished.disconnect(finish_callback)
	
	# Video selesai -> Layar tetap hitam (video disembunyikan)
	video_player.hide()
	skip_label.hide()
	
	print("Intro Finished - Starting Transition Out")
	
	# Fade Out Black (Transition Open - Black Version)
	var tw = create_tween()
	tw.tween_property(color_rect, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	
	print("Transition Done - Restoring Game State")
	
	# Cleanup
	cutscene_layer.queue_free() # Ini akan menghapus video player juga, hati-hati jika perlu lagi
	# Jika ingin video player kembali ke world, reparent balik. Tapi intro biasanya sekali.
	
	# Restore Live Chat
	if live_chat:
		live_chat.visible = was_chat_visible
	
	# Restore Player
	if player:
		print("Restoring Player Physics")
		player.speed = 100.0 # Restore default speed
		player.run_speed = 150.0
		player.set_physics_process(true)
	else:
		print("PLAYER NOT FOUND during restore!")

# --- Fitur Status Bar ---
func update_status_bar():
	# Asumsi di dalam node UI ada fungsi update_stats atau bar HP/MP
	if game_ui and game_ui.has_method("update_display"):
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
	# Detect user activity to show skip prompt
	if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
		if skip_ui_timer <= 0.0:
			skip_ui_timer = 3.0
			
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

func prepare_save_data():
	# 1. Update Posisi & Scene
	GameData.player_position = player.global_position
	GameData.current_scene_path = get_tree().current_scene.scene_file_path
	
	# 2. Update Status Senter dari Player
	# Kita simpan variabel 'can_use_flashlight' milik player ke GameData
	GameData.has_flashlight = player.can_use_flashlight
	
	# 3. Update Item dari Inventory (init.gd)
	# Karena init.gd biasanya adalah anak dari Root atau di CanvasLayer
	# Pastikan path-nya benar. Jika script init.gd menempel di node 'UI'
	var ui_node = $CanvasLayer/UI # Sesuaikan dengan nama node init.gd mu
	if ui_node:
		# Kita ambil array items dari script init.gd dan pindahkan ke GameData
		GameData.items = ui_node.items_di_tas 
		# Catatan: Pastikan di init.gd kamu punya variabel 'items' yang menampung data
