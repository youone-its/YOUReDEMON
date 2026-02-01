extends Area2D

@export var chat_event_id: String = "welcome_event"

func _ready():
	# Cek apakah signal sudah terhubung
	if not self.body_entered.is_connected(_on_body_entered):
		self.body_entered.connect(_on_body_entered)
	print("Trigger ", name, " siap. Menunggu Player...")

func _on_body_entered(body: Node2D):
	# DEBUG: Cetak nama objek apa saja yang masuk ke area
	print("Ada objek masuk: ", body.name, " (Group: ", body.get_groups(), ")")

	# Kita buat pengecekan lebih fleksibel
	if body.name == "Player" or body.is_in_group("player"):
		print("Player terdeteksi! Mengirim chat: ", chat_event_id)
		
		if get_node_or_null("/root/LiveChat"):
			LiveChat.trigger_chat(chat_event_id, 1.0)
		else:
			print("ERROR: Singleton 'LiveChat' tidak ditemukan!")
		
		# Hapus setelah jalan
		queue_free()
