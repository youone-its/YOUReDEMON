extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 150.0

# Current direction for animations
var current_direction: String = "down"
var is_moving: bool = false

func _ready():
	# Add the player to the "player" group for easy reference
	add_to_group("player")
	
	# Setup raycast for interactions
	setup_raycast()

func setup_raycast():
	# Check if raycast exists, if not skip
	if not has_node("CollisionShape2D/RayCast2D"):
		if not has_node("RayCast2D"):
			return
	
	var raycast = null
	if has_node("CollisionShape2D/RayCast2D"):
		raycast = $CollisionShape2D/RayCast2D
	elif has_node("RayCast2D"):
		raycast = $RayCast2D
	
	if raycast:
		# Enable the raycast
		raycast.enabled = true
		# Set to only detect layer 3 (interactions)
		raycast.collision_mask = 4  # Layer 3 = bit 2 = 2^2 = 4
		# Set initial target position
		raycast.target_position = Vector2(0, 30)

func _physics_process(delta):
	# Get input direction
	var input_direction = Vector2.ZERO
	
	# Check WASD keys
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_direction.y -= 1
		current_direction = "up"
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_direction.y += 1
		current_direction = "down"
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_direction.x -= 1
		current_direction = "left"
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_direction.x += 1
		current_direction = "right"
	
	# Normalize diagonal movement so it's not faster
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
		is_moving = true
	else:
		is_moving = false
	
	# Set velocity
	velocity = input_direction * speed
	
	# Move the character
	move_and_slide()
	
	# Update animation and raycast
	update_animation()
	update_raycast()

func update_animation():
	var anim_sprite = $AnimatedSprite2D
	
	if is_moving:
		# Play walk animation for current direction
		anim_sprite.play("walk_" + current_direction)
	else:
		# Play idle animation for current direction
		anim_sprite.play("idle_" + current_direction)

func update_raycast():
	# Try to find the raycast node
	var raycast = null
	if has_node("CollisionShape2D/RayCast2D"):
		raycast = $CollisionShape2D/RayCast2D
	elif has_node("RayCast2D"):
		raycast = $RayCast2D
	
	# If raycast doesn't exist, skip
	if not raycast:
		return
	
	var raycast_length = 30  # Distance the raycast extends
	
	# Update raycast direction based on player facing
	match current_direction:
		"down":
			raycast.target_position = Vector2(0, raycast_length)
		"up":
			raycast.target_position = Vector2(0, -raycast_length)
		"left":
			raycast.target_position = Vector2(-raycast_length, 0)
		"right":
			raycast.target_position = Vector2(raycast_length, 0)

func take_damage(amount: int):
	GameData.hp -= amount
	print("Player kena hit! HP sisa: ", GameData.hp)
	
	# Tambahkan efek visual (opsional)
	var tw = create_tween()
	tw.tween_property($Sprite2D, "modulate", Color.RED, 0.1)
	tw.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
	
	if GameData.hp <= 0:
		die()

func heal(amount: int):
	GameData.hp += amount
	if GameData.hp > 100:
		GameData.hp = 100

func demonized(amount: int):
	# Mengurangi HP di GameData secara langsung
	GameData.demonized_level -= amount
	
	# Pastikan HP tidak minus
	if GameData.demonized_level > 100:
		GameData.demonized_level = 100
		die()

func undemonized(amount: int):
	GameData.demonized_level += amount
	if GameData.demonized_level < 0:
		GameData.demonized_level = 0
		
func die():
	print("Player Mati!")
	# Logika mati bisa memunculkan popup quit atau restart
	GameData.quit_requested.emit()
