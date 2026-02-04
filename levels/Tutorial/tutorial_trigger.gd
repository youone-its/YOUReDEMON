extends Area2D

@export var chat_event_id: String = "welcome_event"

func _ready():
	# Cek apakah signal sudah terhubung
	if not self.body_entered.is_connected(_on_body_entered):
		self.body_entered.connect(_on_body_entered)
	print("Trigger ", name, " siap. Menunggu Player...")

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		# 1. Aktifkan kemampuan senter di script player
		#body.can_use_flashlight = true
		
		# 2. Beri feedback di konsol
		print("Senter Terbuka! Sekarang Player bisa menekan F.")
		
		# 3. Trigger Chat Event jika ada
		if get_node_or_null("/root/LiveChat"):
			LiveChat.trigger_chat(chat_event_id, 1.0)
			
		# 4. Hapus trigger agar tidak terjadi double event
		queue_free()
