extends Camera2D

@export_category("Follow Character")
@export var player: CharacterBody2D

@export_category("Camera Smoothing")
@export var smoothing_enabled: bool = true
@export_range(0.01, 1.0) var smoothing_speed: float = 0.03 # Lower = Slower

func _physics_process(_delta):
	if player:
		var camera_position: Vector2
		
		if smoothing_enabled:
			camera_position = lerp(global_position, player.global_position, smoothing_speed)
		else:
			camera_position = player.global_position
			
		global_position = camera_position.floor()
