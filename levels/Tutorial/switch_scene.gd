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
		if has_node("Button"):
			var btn = $Button
			btn.show()
			btn.z_index = 10 # Paksa Z-Index via script
			print("Label [M] seharusnya muncul sekarang.")
		print("Player bisa berinteraksi (Tekan M)")

func _on_body_exited(body):
	if body.is_in_group("player"):
		is_player_inside = false
		if has_node("Button"):
			$Button.hide()
		#interaction_label.hide() # Sembunyikan notif "M"

func _input(event):
	# Cek apakah player di dalam area dan menekan tombol M
	if is_player_inside and event is InputEventKey and event.pressed:
		if event.keycode == KEY_M:
			_change_scene()

func _change_scene():
	print("Pindah ke scene baru...")
	# Cari pemain di dalam group "player"
	var player = get_tree().get_first_node_in_group("player")
	if player:
		print("Teleporting player ke posisi baru...")
		# Ubah posisi global pemain ke koordinat yang kamu inginkan
		player.trigger_teleport_sequence("position", Vector2(5987.0, 474.0))
	else:
		print("Error: Player tidak ditemukan!")
