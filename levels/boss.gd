extends Node2D

# Variabel untuk melacak jumlah ritual
var ritual_count: int = 0
var total_altars: int = 4
var is_loading: bool = false

# Variabel untuk Save Log (bisa diakses script lain)
var boss_save_log: Dictionary = {
	"scene": "Boss Room",
	"altars_activated": 0,
	"is_boss_spawned": false,
	"details": []
}

func _ready():
	var altars = get_tree().get_nodes_in_group("altars")
	for i in range(altars.size()):
		altars[i].ritual_finished.connect(_on_altar_activated.bind(i + 1))

	await get_tree().process_frame
	
	if GameData.is_loading_from_save:
		# 1. Gunakan koordinat yang baru saja di-load dari file
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = GameData.player_position
		
		# 2. Jalankan loading altar
		load_game({"altars_status": GameData.altars_status})
		
		# 3. Matikan flag agar tidak teleport lagi saat pindah map
		GameData.is_loading_from_save = false
	

func _on_altar_activated(altar_index: int):
	# Jika sedang loading, kita tetap tambah ritual_count tapi jangan trigger event di sini
	ritual_count += 1
	print("Altar %d activated. Total: %d" % [altar_index, ritual_count])
	
	# Trigger event hanya jika TIDAK sedang loading
	if not is_loading and ritual_count >= total_altars:
		_trigger_boss_event()

func _trigger_boss_event():
	boss_save_log["is_boss_spawned"] = true
	print("LOG: Semua altar aktif. Memulai Boss Event!")
	
	# Efek Visual: Seluruh map jadi merah redup
	if has_node("CanvasModulate"):
		$CanvasModulate.color = Color(0.4, 0.1, 0.1)
	
	# Munculkan pesan di LiveChat jika ada
	if has_node("/root/LiveChat"):
		get_node("/root/LiveChat").trigger_chat("boss_arrival")

# Fungsi ini dipanggil saat kamu menekan tombol SAVE di Menu
func get_full_save_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	
	# Menambahkan posisi player dan info scene ke log
	boss_save_log["player_pos_x"] = player.global_position.x
	boss_save_log["player_pos_y"] = player.global_position.y
	boss_save_log["current_scene"] = get_tree().current_scene.scene_file_path
	
	# Data Altar (yang sudah kita buat tadi)
	var altar_status = []
	for altar in get_tree().get_nodes_in_group("altars"):
		altar_status.append(altar.is_active)
	boss_save_log["altars_status"] = altar_status
	
	return boss_save_log

func load_game(data: Dictionary):
	is_loading = true # Kunci agar signal tidak dihitung
	
	if data.has("altars_status"):
		var altars = get_tree().get_nodes_in_group("altars")
		var status_list = data["altars_status"]
		
		ritual_count = 0 # Reset hitungan awal
		for i in range(min(altars.size(), status_list.size())):
			if status_list[i] == true:
				altars[i]._complete_ritual()
				# Jangan tambah ritual_count di sini, biarkan signal yang bekerja
	
	is_loading = false # Buka kunci setelah selesai loading
	
	# Cek total akhir setelah semua signal selesai diproses
	if ritual_count >= total_altars:
		_trigger_boss_event()

func sync_to_gamedata():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		GameData.player_position = player.global_position
	
	var current_status = []
	# Mengambil status 'is_active' dari setiap altar di group
	for altar in get_tree().get_nodes_in_group("altars"):
		current_status.append(altar.is_active)
	
	GameData.altars_status = current_status
	GameData.current_scene_path = get_tree().current_scene.scene_file_path
