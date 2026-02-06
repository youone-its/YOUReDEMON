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
var can_use_flashlight: bool = false
var footstep_player: AudioStreamPlayer2D = null
var flashlight_sfx_player: AudioStreamPlayer2D = null
var demon_vignette: ColorRect = null
var transition_vignette: ColorRect = null
var vignette_layer: CanvasLayer = null

@export_range(0.0, 1.0) var vignette_max_depth: float = 0.5 # 0.5 = Moderate fog at max level
@export var death_texture: Texture2D
var is_dying: bool = false

func _ready():
	# Add the player to the "player" group for easy reference
	add_to_group("player")
	
	# Setup raycast for interactions
	setup_raycast()
	
	# Get existing stamina bars
	get_stamina_bars()
	
	# Setup flashlight
	setup_flashlight()
	can_use_flashlight = GameData.has_flashlight
	if can_use_flashlight:
		print("Senter dipulihkan dari Save Data")
	
	setup_audio()
	setup_demon_vignette()
	
	if GameData.needs_transition_entry:
		GameData.needs_transition_entry = false
		play_transition_open()

func setup_demon_vignette():
	# Create a dedicated CanvasLayer for the vignette
	vignette_layer = CanvasLayer.new()
	vignette_layer.name = "VignetteLayer"
	vignette_layer.layer = 0 
	add_child(vignette_layer)
	
	# Create ColorRect for Demon Vignette (Permanent)
	demon_vignette = ColorRect.new()
	demon_vignette.name = "DemonVignette"
	demon_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	demon_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	var shader = load("res://shader/demon_vignette.gdshader")
	var vignette_mat = ShaderMaterial.new()
	vignette_mat.shader = shader
	demon_vignette.material = vignette_mat
	vignette_layer.add_child(demon_vignette)
	
	# Create separate CanvasLayer for Transition (Highest Priority)
	var transition_layer = CanvasLayer.new()
	transition_layer.name = "TransitionLayer"
	transition_layer.layer = 127 # Covers UI and everything else
	add_child(transition_layer)
	
	# Create ColorRect for Transition Vignette
	# Reuse the same shader because it looks cool like "fog closing in"
	transition_vignette = ColorRect.new()
	transition_vignette.name = "TransitionVignette"
	transition_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var trans_mat = ShaderMaterial.new()
	trans_mat.shader = shader
	transition_vignette.material = trans_mat
	transition_layer.add_child(transition_vignette)
	
	# Initialize transition state (Invisible)
	trans_mat.set_shader_parameter("intensity", 0.0) 
	
	update_demon_vignette()

# --- TRANSITION SYSTEM ---
func trigger_teleport_sequence(target_type: String, target_value: Variant):
	# Block player input
	speed = 0
	run_speed = 0
	set_physics_process(false)
	
	# 1. Close the fog (Transition In)
	var tw = create_tween()
	var mat = transition_vignette.material as ShaderMaterial
	# Intensity 2.5 ensures full screen coverage based on our shader logic
	tw.tween_method(func(val): mat.set_shader_parameter("intensity", val), 0.0, 2.5, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tw.finished
	
	# 2. Perform Action (Move or Change Scene)
	if target_type == "position":
		global_position = target_value
		
		# Snap Camera immediately (no waiting)
		var camera = get_viewport().get_camera_2d()
		if camera:
			camera.global_position = global_position
			camera.reset_smoothing()
			
		# Open fog
		play_transition_open()
		
	elif target_type == "scene":
		GameData.needs_transition_entry = true
		get_tree().change_scene_to_file(target_value)
		# Note: The rest of this function won't run because node is destroyed
		return

func play_transition_open():
	if not transition_vignette: return
	
	# Ensure blocked initially (if coming from scene change)
	speed = 0 
	set_physics_process(false)
	
	var mat = transition_vignette.material as ShaderMaterial
	mat.set_shader_parameter("intensity", 2.5) # Ensure closed
	
	var tw = create_tween()
	tw.tween_method(func(val): mat.set_shader_parameter("intensity", val), 2.5, 0.0, 1.5)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	await tw.finished
	
	# Restore Movement
	# Restore default values (Make sure these match your export defaults)
	speed = 100.0 
	run_speed = 150.0
	set_physics_process(true)

func update_demon_vignette():
	if not demon_vignette or not demon_vignette.material:
		return
	
	# Current Demon Level (0.0 to 1.0)
	var raw_level = float(GameData.demonized_level) / 100.0
	
	# Pass Intensity to Shader
	# We scale the raw level by max_depth.
	# If max_depth is 0.5, then "intensity" sent to shader is 0.5 at level 100.
	# The shader handles logic scaling based on this intensity.
	var final_intensity = raw_level * vignette_max_depth
	
	var mat = demon_vignette.material as ShaderMaterial
	mat.set_shader_parameter("intensity", final_intensity)

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
	update_audio_playback()
	update_demon_vignette()

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

#func take_damage(amount: int):
	#GameData.hp -= amount
	#print("Player kena hit! HP sisa: ", GameData.hp)
	#
	## Tambahkan efek visual (opsional)
	#var tw = create_tween()
	#tw.tween_property($Sprite2D, "modulate", Color.RED, 0.1)
	#tw.tween_property($Sprite2D, "modulate", Color.WHITE, 0.1)
	#
	#if GameData.hp <= 0:
		#die()

func take_damage(amount: int):
	GameData.hp -= amount
	print("Player kena hit! HP sisa: ", GameData.hp)
	
	# Efek visual - Pastikan namanya sesuai dengan node di Player kamu
	var tw = create_tween()
	# Ganti $Sprite2D menjadi $AnimatedSprite2D
	if has_node("AnimatedSprite2D"):
		tw.tween_property($AnimatedSprite2D, "modulate", Color.RED, 0.1)
		tw.tween_property($AnimatedSprite2D, "modulate", Color.WHITE, 0.1)
	
	if GameData.hp <= 0:
		die()

func heal(amount: int):
	GameData.hp += amount
	if GameData.hp > 100:
		GameData.hp = 100

func demonized(amount: int):
	# GANTI -= MENJADI +=
	GameData.demonized_level += amount
	
	# Tambahkan print untuk memastikan nilainya masuk di konsol
	print("LOG: Demonized Level bertambah! Sekarang: ", GameData.demonized_level)
	
	# Batasi maksimal 100
	if GameData.demonized_level >= 100:
		GameData.demonized_level = 100
		die()

func undemonized(amount: int):
	GameData.demonized_level += amount
	if GameData.demonized_level < 0:
		GameData.demonized_level = 0
		
func die():
	if is_dying: return
	is_dying = true
	print("Player Mati!")
	
	# Stop movement and input
	speed = 0
	run_speed = 0
	set_physics_process(false)
	
	# 1. Bloody Transition In (Cover Screen)
	if transition_vignette and transition_vignette.material:
		var mat = transition_vignette.material as ShaderMaterial
		var tw = create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS) # Run even if paused
		# Intensity 2.5 ensures full redness
		tw.tween_method(func(val): mat.set_shader_parameter("intensity", val), 0.0, 2.5, 2.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await tw.finished

	# 2. Show Death Sprite
	var death_layer = CanvasLayer.new()
	death_layer.name = "DeathLayer"
	# Layer 1100 to be above LiveChat (1000) but below Menu UI (which we will bump to 1200)
	death_layer.layer = 1100 
	add_child(death_layer)
	
	# Hide Stamina UI if it exists
	if has_node("StaminaUI"):
		get_node("StaminaUI").visible = false
	
	var tex_rect = TextureRect.new()
	if death_texture:
		tex_rect.texture = death_texture
	else:
		# Fallback if no texture assigned
		tex_rect.modulate = Color(0, 0, 0) # Black screen
	
	tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Ensure it covers everything
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	death_layer.add_child(tex_rect)

	# 3. Show UI (Pause Game + Quit Buttons)
	# This will show generic "YOU ARE DEAD" popup from init.gd
	GameData.quit_requested.emit()
	
	# 4. Transition Out (Reveal Death Sprite + UI)
	if transition_vignette and transition_vignette.material:
		var mat = transition_vignette.material as ShaderMaterial
		var tw = create_tween()
		tw.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_method(func(val): mat.set_shader_parameter("intensity", val), 2.5, 0.0, 1.0)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func toggle_flashlight():
	if not flashlight:
		return
	
	# CEK: Jika belum kena trigger, jangan biarkan menyala
	if not can_use_flashlight:
		print("Flashlight belum ditemukan/diaktifkan!")
		return
	
	flashlight_enabled = !flashlight_enabled
	flashlight.visible = flashlight_enabled
	
	if flashlight_sfx_player:
		if flashlight_enabled:
			flashlight_sfx_player.stream = load("res://assets/Sound/item/Flashlight_on.ogg")
		else:
			flashlight_sfx_player.stream = load("res://assets/Sound/item/Flashlight_off.ogg")
		flashlight_sfx_player.play()
	
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

func ambil_item(tipe, jumlah, icon_path):
	# Pastikan node target namanya "SurvivalSystem" di Scene Tree
	var ss = get_tree().current_scene.find_child("SurvivalSystem", true, false)
	if ss and ss.has_method("tambah_item_ke_tas"):
		return ss.tambah_item_ke_tas(tipe, jumlah, icon_path)
	
	print("Error: SurvivalSystem tidak ditemukan!")
	return false

func setup_audio():
	footstep_player = AudioStreamPlayer2D.new()
	footstep_player.stream = load("res://assets/Sound/footstep/Footsteps Loop 1 (Rpg).wav")
	footstep_player.volume_db = 5.0
	add_child(footstep_player)
	
	flashlight_sfx_player = AudioStreamPlayer2D.new()
	add_child(flashlight_sfx_player)

func update_audio_playback():
	if not footstep_player:
		return
		
	if is_moving:
		if not footstep_player.playing:
			footstep_player.play()
		
		# Faster playback when running
		if is_running:
			footstep_player.pitch_scale = 1.5
		else:
			footstep_player.pitch_scale = 1.0
	else:
		if footstep_player.playing:
			footstep_player.stop()
