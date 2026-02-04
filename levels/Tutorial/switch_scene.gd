extends Area2D

#@onready var interaction_label = $InteractionLabel # Sesuaikan nama node labelmu
var is_player_inside: bool = false
var target_scene: String = "uid://cpw3bnl47ynj1"

func _ready():
	# Hubungkan sinyal secara internal
	self.body_entered.connect(_on_body_entered)
	self.body_exited.connect(_on_body_exited)
	#interaction_label.hide() # Pastikan tersembunyi saat awal

func _on_body_entered(body):
	if body.is_in_group("player"):
		is_player_inside = true
		#interaction_label.show() # Tampilkan notif "M"
		print("Player bisa berinteraksi (Tekan M)")

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside = false
		#interaction_label.hide() # Sembunyikan notif "M"

func _input(event):
	# Cek apakah player di dalam area dan menekan tombol M
	if is_player_inside and event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			_change_scene()

func _change_scene():
	print("Pindah ke scene baru...")
	# Simpan data sebelum pindah jika diperlukan
	if GameData.has_method("save_game"):
		GameData.save_game()
	
	get_tree().change_scene_to_file(target_scene)
