extends Area2D

@export var item_id: String = "" 
@export var item_name: String = ""
@export var texture_icon: Texture
@export var chat_event_id: String = "welcome_event"

var player_in_range = false

func _ready():
	# Pastikan node Sprite2D ada dan texture dipasang
	if texture_icon:
		$Sprite2D.texture = texture_icon
	
	$PickupButton.hide()
	
	# Pastikan monitoring aktif
	monitoring = true 
	
	if not self.body_entered.is_connected(_on_body_entered):
		self.body_entered.connect(_on_body_entered)
	print("Trigger ", name, " siap. Menunggu Player...")
		
	if _is_item_already_collected():
		queue_free()
	# Bersihkan koneksi lama dan buat yang baru
	if body_entered.is_connected(_on_body_entered): body_entered.disconnect(_on_body_entered)
	body_entered.connect(_on_body_entered)
	
	if body_exited.is_connected(_on_body_exited): body_exited.disconnect(_on_body_exited)
	body_exited.connect(_on_body_exited)
	
func _is_item_already_collected() -> bool:
	for item in GameData.items:
		if item["id"] == item_id:
			return true
	return false

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("!!! PLAYER TERDETEKSI !!!")
		player_in_range = true
		# Pastikan path node ini benar sesuai hirarki
		if has_node("PickupButton"):
			var btn = $PickupButton
			btn.show()
			btn.z_index = 10 # Paksa Z-Index via script
			print("Label [C] seharusnya muncul sekarang.")
		if get_node_or_null("/root/LiveChat"):
			LiveChat.trigger_chat(chat_event_id, 1.0)
		queue_free()
			
func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false
		$PickupButton.hide()

func _input(event):
	# Hanya eksekusi jika player di dalam area dan tekan tombol interact
	if player_in_range and event.is_action_pressed("interact"):
		collect_item()

#func collect_item():
	## Cari node SurvivalSystem di scene tree
	#var ss = get_tree().current_scene.find_child("Node2D", true, false)
	#if ss and ss.has_method("tambah_item_ke_tas"):
		#if ss.tambah_item_ke_tas(item_id, texture_icon):
			#print("Item ", item_id, " berhasil diambil!")
			#queue_free()
	#else:
		#print("ERROR: Node SurvivalSystem tidak ditemukan!")

func collect_item():
	var ss = get_tree().current_scene.find_child("Node2D", true, false)
	var player = get_tree().get_first_node_in_group("player")
	
	if ss and ss.has_method("tambah_item_ke_tas"):
		var path_gambar = texture_icon.resource_path
		if ss.tambah_item_ke_tas(item_id, path_gambar):
			# JIKA YANG DIAMBIL ADALAH FLASHLIGHT, AKTIFKAN DI PLAYER
			if item_id == "flashlight" and player:
				player.can_use_flashlight = true
				GameData.has_flashlight = true
				print("Senter diaktifkan untuk Player!")
			
			print("Item ", item_id, " berhasil diambil!")
			queue_free()
	else:
		print("ERROR: Node SurvivalSystem tidak ditemukan!")
