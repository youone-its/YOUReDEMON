extends Area2D

var is_player_inside: bool = false
var target_scene: String = "uid://cpw3bnl47ynj1"
var is_processing_teleport: bool = false # Mencegah spam tombol saat delay

func _ready():
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	# Pastikan tombol sembunyi saat awal
	if has_node("Button"):
		$Button.hide()

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_inside = true
		if has_node("Button"):
			$Button.text = "[M]" # Reset ke default
			$Button.show()
		print("Player bisa berinteraksi (Tekan M)")

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside = false
		if has_node("Button"):
			$Button.hide()

func _input(event):
	# Tambahkan cek is_processing_teleport agar tidak bentrok saat sedang delay
	if is_player_inside and not is_processing_teleport and event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			_check_requirement_and_teleport()

func _check_requirement_and_teleport():
	# 1. Daftar kunci yang dibutuhkan
	var required_keys = ["key1", "key2", "key3", "key4", "key5"]
	var has_all_keys = true
	
	# 2. Ambil daftar ID item dari GameData.items
	# Menggunakan map untuk mengambil ID saja agar pengecekan lebih mudah
	var current_item_ids = GameData.items.map(func(item): return item["id"])
	
	for key in required_keys:
		if not key in current_item_ids:
			has_all_keys = false
			break
	
	is_processing_teleport = true
	
	if has_all_keys:
		# LOGIKA BERHASIL
		if has_node("Button"):
			$Button.text = "Good Luck My Lord"
		
		print("Syarat terpenuhi. Menunggu 1 detik...")
		await get_tree().create_timer(1.0).timeout
		_change_scene()
	else:
		# LOGIKA GAGAL
		if has_node("Button"):
			$Button.text = "I demand you 5 keys to be present first"
		
		print("Syarat tidak terpenuhi.")
		await get_tree().create_timer(1.0).timeout
		
		# Kembalikan ke teks default jika player masih di dalam area
		if is_player_inside and has_node("Button"):
			$Button.text = "[M]"
		
		is_processing_teleport = false

func _change_scene():
	print("Pindah ke scene baru...")
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.trigger_teleport_sequence("scene", target_scene)
	else:
		get_tree().change_scene_to_file(target_scene)
