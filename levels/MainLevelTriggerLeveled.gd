extends Area2D

@export var chat_event_id: String = "welcome_event"
@export var layer: int = 1           # Di layer mana trigger ini berada
@export var is_anchor: bool = false   # Jika true, dia akan menaikkan GameProgress.current_layer

func _ready():
	if not self.body_entered.is_connected(_on_body_entered):
		self.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		# CEK: Apakah layer trigger ini sesuai dengan progress game sekarang?
		if GameProgress.current_layer == layer:
			execute_trigger()

func execute_trigger():
	# 1. Feedback konsol
	print("Trigger ", name, " aktif di Layer ", layer)
	
	# 2. Logika Senter / Ability
	# if body.has_method("enable_flashlight"): body.enable_flashlight()
	
	# 3. Trigger Chat Event
	if get_node_or_null("/root/LiveChat"):
		LiveChat.trigger_chat(chat_event_id, 1.0)
	
	# 4. LOGIKA ANCHOR: Naikkan layer jika ini adalah anchor
	if is_anchor:
		GameProgress.advance_layer()
	
	# 5. Hapus trigger agar tidak double
	queue_free()
