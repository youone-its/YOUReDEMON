extends CanvasLayer

@onready var chat_container = $Control/ScrollContainer/ChatBox
@onready var ui_shell = $Control
var current_trigger_task: String = ""
var is_chat_showing: bool = true
var default_x: float = 852.0 # Posisi X awal kamu
var hidden_offset: float = 300.0 # Lebar UI kamu

const COLORS = {
	ChatData.Type.DEVIL: Color.RED,
	ChatData.Type.OBSERVER: Color.WHITE,
	ChatData.Type.TROLL: Color.MEDIUM_PURPLE
}

func _ready():
	# Sembunyikan secara default saat game pertama kali dijalankan
	self.visible = false
	default_x = ui_shell.position.x
	
func trigger_chat(trigger_id: String):
	# Jika ID sudah ada, artinya sudah pernah muncul, jangan buat baru
	if trigger_id in GameData.completed_chats:
		return 

	GameData.completed_chats.append(trigger_id)
	current_trigger_task = trigger_id
	
	if ChatData.MESSAGES.has(trigger_id):
		var messages = ChatData.MESSAGES[trigger_id]
		await get_tree().create_timer(5.0).timeout
		
		if current_trigger_task != trigger_id: return

		for msg in messages:
			# SIMPAN KE HISTORY agar terbawa saat Save/Load
			GameData.chat_history.append(msg)
			create_message_label(msg, true) # Pakai animasi untuk pesan baru
			await get_tree().create_timer(1.5).timeout

# FUNGSI BARU: Dipanggil saat Load Game agar chat lama muncul instan
func reload_history():
	clear_chat()
	for msg in GameData.chat_history:
		create_message_label(msg, false) # Tanpa animasi untuk history

func create_message_label(data: Dictionary, use_animation: bool = true):
	var wrapper = VBoxContainer.new()
	wrapper.custom_minimum_size.x = 280
	
	var is_offer = data.get("is_offer", false)
	
	# 1. Setup Alignment
	wrapper.size_flags_horizontal = Control.SIZE_SHRINK_END if is_offer else Control.SIZE_SHRINK_BEGIN

	# 2. Buat Label Text
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	var color_hex = COLORS[data.type].to_html()
	var align = "[right]" if is_offer else "[left]"
	label.text = "%s[color=#%s][b]%s:[/b] %s[/color]" % [align, color_hex, data.user, data.text]
	wrapper.add_child(label)

	# 3. Buat Tombol Offer
	if is_offer:
		var offer_id = data.get("offer_id", "")
		var btn_row = HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_END
		var btn_accept = Button.new(); btn_accept.text = "Accept"
		var btn_reject = Button.new(); btn_reject.text = "Reject"
		
		# Cek apakah sudah pernah direspond (agar tombol mati saat Load)
		if offer_id in GameData.completed_chats:
			btn_accept.disabled = true
			btn_reject.disabled = true
			wrapper.modulate = Color(0.6, 0.6, 0.6, 0.7) 
		else:
			btn_accept.pressed.connect(_on_offer_responded.bind(offer_id, true, wrapper))
			btn_reject.pressed.connect(_on_offer_responded.bind(offer_id, false, wrapper))
		
		btn_row.add_child(btn_accept)
		btn_row.add_child(btn_reject)
		wrapper.add_child(btn_row)

	chat_container.add_child(wrapper)
	
	# 4. Logika Animasi (Hanya jalan jika use_animation = true)
	if use_animation:
		wrapper.modulate.a = 0
		wrapper.position.x += 100 if is_offer else -100
		var tween = create_tween().set_parallel(true)
		tween.tween_property(wrapper, "position:x", 0.0, 0.5).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		tween.tween_property(wrapper, "modulate:a", 1.0, 0.5)
	
	# Auto-scroll
	await get_tree().process_frame
	var scroll = chat_container.get_parent()
	if scroll is ScrollContainer:
		scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

func _on_offer_responded(id: String, _accepted: bool, node_wrapper: Node):
	node_wrapper.modulate = Color(0.6, 0.6, 0.6, 0.7)
	for child in node_wrapper.get_children():
		if child is HBoxContainer:
			for btn in child.get_children():
				if btn is Button: btn.disabled = true
	if not id in GameData.completed_chats:
		GameData.completed_chats.append(id)

func clear_chat():
	current_trigger_task = ""
	for child in chat_container.get_children():
		child.queue_free()

func _process(_delta):
	var current_scene = get_tree().current_scene
	if is_instance_valid(current_scene):
		# Jika scene sekarang masuk ke grup "hide_chat", sembunyikan
		if current_scene.is_in_group("hide_chat_global"):
			if self.visible: self.visible = false
		else:
			# Aktifkan kembali jika bukan di grup menu
			if not self.visible: self.visible = true

func toggle_chat_ui():
	var tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	if is_chat_showing:
		# MENUTUP: Geser ke kanan sejauh lebar UI (852 + 300 = 1152)
		var target_x = default_x + hidden_offset
		tween.tween_property(ui_shell, "position:x", target_x, 0.4)
		is_chat_showing = false
	else:
		# MEMBUKA: Kembali ke posisi awal (852)
		tween.tween_property(ui_shell, "position:x", default_x, 0.4)
		is_chat_showing = true
		
func check_chat_input(event: InputEvent):
	if event is InputEventKey and event.pressed:
		if event.keycode == GameData.chat_toggle_key:
			toggle_chat_ui()
