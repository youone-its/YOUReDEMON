extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 100.0
@export var run_speed: float = 150.0

# Stamina system
@export var max_stamina: float = 5.0  # 5 seconds of running
var current_stamina: float = 5.0
var stamina_drain_rate: float = 1.0  # Drains 1 per second
var stamina_recharge_rate: float = 0.5  # Recharges 0.5 per second
var is_running: bool = false

# Current direction for animations
var current_direction: String = "down"
var is_moving: bool = false

# Stamina bar UI (ProgressBars)
var stamina_bar_left: ProgressBar = null
var stamina_bar_right: ProgressBar = null

# Flashlight
var flashlight: PointLight2D = null
var flashlight_enabled: bool = false
var f_key_was_pressed: bool = false
@export var flashlight_rotation_speed: float = 10.0

func _ready():
	# Add the player to the "player" group for easy reference
	add_to_group("player")
	
	# Setup raycast for interactions
	setup_raycast()
	
	# Get existing stamina bars
	get_stamina_bars()
	
	# Setup flashlight
	setup_flashlight()

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

func get_stamina_bars():
	# Get the existing ProgressBar nodes inside CanvasLayer
	if has_node("StaminaUI/StaminaBarLeft"):
		stamina_bar_left = $StaminaUI/StaminaBarLeft
		stamina_bar_left.max_value = max_stamina
		stamina_bar_left.value = current_stamina
	
	if has_node("StaminaUI/StaminaBarRight"):
		stamina_bar_right = $StaminaUI/StaminaBarRight
		stamina_bar_right.max_value = max_stamina
		stamina_bar_right.value = current_stamina

func setup_flashlight():
	# Get the PointLight2D2 node
	if has_node("PointLight2D2"):
		flashlight = $PointLight2D2
		print("Flashlight found at position: ", flashlight.position)
		# Reset position to be at player center
		flashlight.position = Vector2(0, 10)
		# Start with flashlight disabled
		flashlight.visible = false
		flashlight_enabled = false
	else:
		print("ERROR: PointLight2D2 not found!")

func _physics_process(delta):
	# Toggle flashlight with F key (detect single press)
	if Input.is_key_pressed(KEY_F):
		if not f_key_was_pressed:
			toggle_flashlight()
			f_key_was_pressed = true
	else:
		f_key_was_pressed = false
	
	# Update flashlight rotation to follow mouse
	update_flashlight_rotation(delta)
	
	# Check if player wants to run (Shift key)
	var want_to_run = Input.is_key_pressed(KEY_SHIFT)
	
	# Get input direction
	var input_direction = Vector2.ZERO
	
	# Check WASD keys
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_direction.y += 1
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_direction.x += 1
	
	# Determine direction based on input (8 directions)
	if input_direction.length() > 0:
		is_moving = true
		
		# Normalize for consistent speed
		input_direction = input_direction.normalized()
		
		# Determine 8-directional facing
		var angle = rad_to_deg(input_direction.angle())
		
		if angle >= -22.5 and angle < 22.5:
			current_direction = "right"
		elif angle >= 22.5 and angle < 67.5:
			current_direction = "downright"
		elif angle >= 67.5 and angle < 112.5:
			current_direction = "down"
		elif angle >= 112.5 and angle < 157.5:
			current_direction = "downleft"
		elif angle >= 157.5 or angle < -157.5:
			current_direction = "left"
		elif angle >= -157.5 and angle < -112.5:
			current_direction = "topleft"
		elif angle >= -112.5 and angle < -67.5:
			current_direction = "up"
		elif angle >= -67.5 and angle < -22.5:
			current_direction = "topright"
	else:
		is_moving = false
	
	# Determine actual speed based on running and stamina
	var actual_speed = speed
	is_running = false
	
	if want_to_run and is_moving and current_stamina > 0:
		actual_speed = run_speed
		is_running = true
		# Drain stamina
		current_stamina -= stamina_drain_rate * delta
		if current_stamina < 0:
			current_stamina = 0
		# No stamina regeneration while running
	else:
		# Recharge stamina only when not running
		if not is_running and current_stamina < max_stamina:
			current_stamina += stamina_recharge_rate * delta
			if current_stamina > max_stamina:
				current_stamina = max_stamina
	
	# Update stamina bar
	update_stamina_bar()
	
	# Set velocity
	velocity = input_direction * actual_speed
	
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
		
		# Speed up animation when running
		if is_running:
			anim_sprite.speed_scale = 1.5  # 10 FPS (base 6.6 * 1.5 ≈ 10)
		else:
			anim_sprite.speed_scale = 1.0  # Normal speed
	else:
		# Play idle animation for current direction
		anim_sprite.play("idle_" + current_direction)
		anim_sprite.speed_scale = 1.0  # Reset to normal

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
	
	# Update raycast direction based on player facing (8 directions)
	match current_direction:
		"down":
			raycast.target_position = Vector2(0, raycast_length)
		"up":
			raycast.target_position = Vector2(0, -raycast_length)
		"left":
			raycast.target_position = Vector2(-raycast_length, 0)
		"right":
			raycast.target_position = Vector2(raycast_length, 0)
		"downright":
			raycast.target_position = Vector2(raycast_length, raycast_length).normalized() * raycast_length
		"downleft":
			raycast.target_position = Vector2(-raycast_length, raycast_length).normalized() * raycast_length
		"topright":
			raycast.target_position = Vector2(raycast_length, -raycast_length).normalized() * raycast_length
		"topleft":
			raycast.target_position = Vector2(-raycast_length, -raycast_length).normalized() * raycast_length

func update_stamina_bar():
	if not stamina_bar_left or not stamina_bar_right:
		return
	
	var stamina_percent = current_stamina / max_stamina
	
	# Hide bars if stamina is full
	if stamina_percent >= 1.0:
		stamina_bar_left.visible = false
		stamina_bar_right.visible = false
	else:
		stamina_bar_left.visible = true
		stamina_bar_right.visible = true
	
	# Update both progress bars
	stamina_bar_left.value = current_stamina
	stamina_bar_right.value = current_stamina

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

func toggle_flashlight():
	if not flashlight:
		return
	
	flashlight_enabled = !flashlight_enabled
	flashlight.visible = flashlight_enabled
	print("Flashlight: ", "ON" if flashlight_enabled else "OFF")

func update_flashlight_rotation(delta):
	if not flashlight or not flashlight_enabled:
		return
	
	# Get mouse position in global coordinates
	var mouse_pos = get_global_mouse_position()
	
	# Calculate direction from flashlight's global position to mouse
	var direction = (mouse_pos - flashlight.global_position).normalized()
	
	# Calculate angle in radians (subtract PI/2 to correct for default orientation)
	var target_angle = direction.angle() - PI / 2
	
	# Smoothly interpolate the flashlight rotation
	flashlight.rotation = lerp_angle(flashlight.rotation, target_angle, flashlight_rotation_speed * delta)
