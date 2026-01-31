extends TextureRect

@export var move_amount := 25.0  # Seberapa jauh gambar bergeser
@export var lerp_speed := 2.0    # Kehalusan gerakan

@onready var initial_pos = position

func _process(delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport_rect().size
	
	# Menghitung persentase posisi mouse dari tengah layar (-0.5 sampai 0.5)
	var target_offset_x = (mouse_pos.x / screen_size.x) - 0.5
	var target_offset_y = (mouse_pos.y / screen_size.y) - 0.5
	
	# Inversi: mouse kiri -> target kanan (dikali -1)
	var target_pos = initial_pos + Vector2(-target_offset_x, -target_offset_y) * move_amount
	
	# Supaya gerakannya mulus (smooth)
	position = position.lerp(target_pos, delta * lerp_speed)
