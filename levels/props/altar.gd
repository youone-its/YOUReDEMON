extends CharacterBody2D

signal ritual_finished

var is_player_near: bool = false
var is_active: bool = false

@onready var ui = $InteractionUI 
@onready var label = $InteractionUI/PromptLabel
@onready var timer = $HoldTimer 
@onready var light = $PointLight2D 
@export var is_special_altar: bool = false

func _ready():
	ui.hide()
	# Hubungkan signal Area2D ke fungsi deteksi
	$InteractionArea.body_entered.connect(_on_body_entered)
	$InteractionArea.body_exited.connect(_on_body_exited)
	# Hubungkan signal Timer
	timer.timeout.connect(_on_hold_timer_timeout)

func _on_body_entered(body):
	# Pastikan node Player kamu namanya "Player" di scene tree
	if body.name == "Player" and not is_active:
		is_player_near = true
		ui.show()
		label.text = "Tahan [SPACE]"

func _on_body_exited(body):
	if body.name == "Player":
		is_player_near = false
		ui.hide()
		_stop_ritual()
		# Kembalikan kontrol jalan player jika dia keluar saat menahan
		body.set_physics_process(true)

func _process(_delta):
	if is_player_near and not is_active:
		if Input.is_action_pressed("ui_accept"): # Tombol Space
			if timer.is_stopped():
				timer.start()
			
			label.text = "Ritual: %.1f" % timer.time_left
			
			# OPSIONAL: Hentikan gerak player saat ritual
			var player = get_tree().current_scene.find_child("Player", true, false)
			if player: player.velocity = Vector2.ZERO
		else:
			_stop_ritual()

func _stop_ritual():
	timer.stop()
	if is_player_near:
		label.text = "Tahan [SPACE]"

func _on_hold_timer_timeout():
	_complete_ritual()


func get_save_data():
	return {
		"is_active": is_active
	}

func load_save_data(data):
	if data.has("is_active") and data["is_active"]:
		_complete_ritual() # Jalankan ritual selesai tanpa perlu player menahan tombol lagi

func _complete_ritual():
	is_active = true
	is_player_near = false # Tambahkan ini agar deteksi input berhenti
	ui.hide() 
	timer.stop() 
	light.color = Color.RED 
	light.energy = 2.0
	$AnimatedSprite2D.self_modulate = Color(2, 0.5, 0.5)
	
	# Matikan InteractionArea agar tidak bisa dipicu lagi
	var area = $InteractionArea # Sesuaikan path jika berbeda
	if area:
		area.monitoring = false
		area.monitorable = false
		
	ritual_finished.emit()

func deactivate_altar():
	is_active = false
	is_player_near = false
	ui.hide()
	
	# Kembalikan visual ke biru (default)
	light.color = Color.BLUE
	light.energy = 1.0
	$AnimatedSprite2D.self_modulate = Color(1, 1, 1) # Normal
	
	$InteractionArea.monitoring = true
	$InteractionArea.monitorable = true
	
	# Kabari boss.gd bahwa jumlah ritual berkurang
	ritual_finished.emit()
