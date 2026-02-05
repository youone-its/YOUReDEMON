extends CharacterBody2D

# States
enum State { ROAMING, CHASING, SEARCHING, STUNNED }
enum EnemyTier { LOW, MID, HIGH }
var current_state: State = State.ROAMING
var previous_state: State = State.ROAMING

# Movement
@export var roam_speed: float = 50.0
@export var chase_speed: float = 100.0
@export var roam_radius: float = 200.0
@export var tier: EnemyTier = EnemyTier.LOW
var has_attacked: bool = false

# Detection
@export var light_rotation_speed: float = 45.0  # Degrees per second
@export var search_duration: float = 3.0  # How long to search after losing player

# References
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var detection_area: Area2D = $"Flashlight area"
@onready var light: PointLight2D = $PointLight2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# State variables
var spawn_position: Vector2
var player: Node2D = null
var last_known_player_pos: Vector2
var target_light_angle: float = 0.0
var current_light_angle: float = 0.0
var search_timer: float = 0.0
var roam_wait_timer: float = 0.0
var roam_wait_duration: float = 2.0
var is_stunned: bool = false
var player_flashlight_area: Area2D = null
var footstep_player: AudioStreamPlayer2D = null

func _ready():
	spawn_position = global_position
	current_light_angle = 0.0  # Light points down at 0 degrees
	target_light_angle = current_light_angle
	
	# Connect detection area
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)
	
	# Debug
	print("Enemy initialized at: ", global_position)
	
	# Start roaming
	_set_random_roam_target()
	
	# Find player's flashlight area
	await get_tree().process_frame
	_find_player_flashlight()
	call_deferred("_setup_navigation")
	if name in GameData.defeated_enemy_names:
		queue_free()
		return
	
	setup_audio()

func _setup_navigation():
	if nav_agent:
		nav_agent.path_desired_distance = 4.0
		nav_agent.target_desired_distance = 4.0

func _physics_process(delta):
	# Check if stunned by player's flashlight
	_check_flashlight_stun()
	
	match current_state:
		State.ROAMING:
			_process_roaming(delta)
		State.CHASING:
			_process_chasing(delta)
		State.SEARCHING:
			_process_searching(delta)
		State.STUNNED:
			_process_stunned(delta)
	
	# Smooth light rotation
	_update_light_rotation(delta)
	
	# Move based on navigation (skip if stunned)
	if current_state != State.STUNNED:
		_move_toward_target(delta)
	
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision.get_collider().is_in_group("player"):
			_apply_possession_effect(collision.get_collider())
			
	update_audio_playback()

func setup_audio():
	footstep_player = AudioStreamPlayer2D.new()
	# Use a different footstep sound for the enemy to differentiate
	footstep_player.stream = load("res://assets/Sound/footstep/Footsteps Loop 2 (Rpg).wav")
	footstep_player.volume_db = 10
	footstep_player.max_distance = 500 # Spatial audio - only hear when close
	add_child(footstep_player)

func update_audio_playback():
	if not footstep_player:
		return
		
	# Check if moving (velocity > 0) and not stunned
	if velocity.length() > 0 and current_state != State.STUNNED:
		if not footstep_player.playing:
			footstep_player.play()
		
		# Faster pitch when chasing
		if current_state == State.CHASING:
			footstep_player.pitch_scale = 1.5
		else:
			footstep_player.pitch_scale = 1.0
	else:
		if footstep_player.playing:
			footstep_player.stop()

func _apply_possession_effect(player_node):
	if has_attacked: return
	has_attacked = true # Kunci agar tidak terkena berkali-kali dalam 1 frame
	
	print("Enemy merasuki player! Tier: ", tier)
	
	match tier:
		EnemyTier.LOW:
			player_node.demonized(10)
			player_node.take_damage(5)
		EnemyTier.MID:
			player_node.demonized(10)
			player_node.take_damage(15)
		EnemyTier.HIGH:
			player_node.demonized(20)
			player_node.take_damage(15)
			
	# Efek suara atau partikel bisa ditambah di sini sebelum queue_free
	queue_free() # Enemy menghilang (ceritanya merasuki)
	
func _process_roaming(delta):
	# Slowly rotate light while roaming
	if roam_wait_timer > 0:
		roam_wait_timer -= delta
		# Rotate light while waiting
		target_light_angle += light_rotation_speed * delta
	else:
		# Check if reached destination
		if nav_agent.is_navigation_finished():
			roam_wait_timer = roam_wait_duration
			# Pick new rotation angle
			target_light_angle = randf_range(0, 360)
		else:
			# Rotate light while moving
			target_light_angle += light_rotation_speed * 0.5 * delta

func _process_chasing(delta):
	if player and is_instance_valid(player):
		# Check both detection area and line of sight
		if _is_player_in_light():
			last_known_player_pos = player.global_position
			nav_agent.target_position = player.global_position
			
			# Point light toward player (light naturally points down at rotation 0)
			var direction_to_player = (player.global_position - global_position).normalized()
			target_light_angle = rad_to_deg(direction_to_player.angle()) - 90
			
			# Fast tracking during chase - apply rotation immediately
			current_light_angle = target_light_angle
		else:
			# Lost sight of player (blocked by obstacle or out of light)
			print("Lost line of sight to player!")
			_enter_search_state()
	else:
		_enter_search_state()

func _process_searching(delta):
	search_timer -= delta
	
	# Rotate light to search
	target_light_angle += light_rotation_speed * delta
	
	# Check if reached last known position
	if nav_agent.is_navigation_finished():
		# Stand and search
		pass
	
	# Timeout - return to roaming
	if search_timer <= 0:
		_enter_roaming_state()

func _move_toward_target(delta):
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		# Stop or play idle animation when not moving
		if sprite:
			if sprite.animation.begins_with("walk_"):
				var direction = sprite.animation.replace("walk_", "")
				if sprite.sprite_frames.has_animation("idle_" + direction):
					sprite.play("idle_" + direction)
				else:
					# Just stop on first frame if no idle animation
					sprite.stop()
		
		# Set new target if in roaming state and wait is over
		if current_state == State.ROAMING and roam_wait_timer <= 0:
			_set_random_roam_target()
		return
	
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	var speed = chase_speed if current_state == State.CHASING else roam_speed
	velocity = direction * speed
	move_and_slide()
	
	# Update animation based on movement direction
	if sprite and velocity.length() > 0:
		_update_movement_animation(direction)

func _update_light_rotation(delta):
	# Normalize angles to 0-360
	target_light_angle = fmod(target_light_angle, 360.0)
	if target_light_angle < 0:
		target_light_angle += 360.0
	
	current_light_angle = fmod(current_light_angle, 360.0)
	if current_light_angle < 0:
		current_light_angle += 360.0
	
	# Calculate shortest rotation direction
	var angle_diff = target_light_angle - current_light_angle
	
	# Normalize to -180 to 180
	if angle_diff > 180:
		angle_diff -= 360
	elif angle_diff < -180:
		angle_diff += 360
	
	# Smoothly interpolate
	var rotation_step = light_rotation_speed * 2.0 * delta
	if abs(angle_diff) < rotation_step:
		current_light_angle = target_light_angle
	else:
		current_light_angle += sign(angle_diff) * rotation_step
	
	# Apply rotation to light and detection area
	var rotation_rad = deg_to_rad(current_light_angle)
	light.rotation = rotation_rad
	detection_area.rotation = rotation_rad

func _set_random_roam_target():
	var random_offset = Vector2(
		randf_range(-roam_radius, roam_radius),
		randf_range(-roam_radius, roam_radius)
	)
	var target = spawn_position + random_offset
	
	# Clamp to roam area
	if target.distance_to(spawn_position) > roam_radius:
		target = spawn_position + (target - spawn_position).normalized() * roam_radius
	
	nav_agent.target_position = target

func _is_player_in_light() -> bool:
	if not player or not is_instance_valid(player):
		return false
	
	# Check if player is in the detection area
	var overlapping_bodies = detection_area.get_overlapping_bodies()
	if not (player in overlapping_bodies):
		return false
	
	# Check line of sight - raycast to player
	return _has_line_of_sight_to_player()

func _has_line_of_sight_to_player() -> bool:
	if not player or not is_instance_valid(player):
		return false
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, player.global_position)
	
	# Check collision with walls and obstacles
	# Layer 1 = bit 0 = 1 (Environment/Walls), Layer 2 = bit 1 = 2 (Player layer)
	# We want to detect walls (layer 1) that would block line of sight
	query.collision_mask = 1  # Only check layer 1 (walls/environment)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	# If ray hit nothing, we have clear line of sight
	# If ray hit something, there's an obstacle blocking the view
	if result.is_empty():
		return true
	else:
		# Check if collision point is beyond the player (means player is closer)
		var collision_distance = global_position.distance_to(result.position)
		var player_distance = global_position.distance_to(player.global_position)
		# If the obstacle is further than the player, we can see the player
		return collision_distance > player_distance

func _on_detection_area_body_entered(body: Node2D):
	print("Body entered detection: ", body.name, " in group player: ", body.is_in_group("player"))
	if body.is_in_group("player"):
		player = body
		print("Player detected! Current state: ", current_state)
		if current_state == State.ROAMING or current_state == State.SEARCHING:
			_enter_chase_state()

func _on_detection_area_body_exited(body: Node2D):
	if body == player:
		if current_state == State.CHASING:
			_enter_search_state()

func _enter_chase_state():
	current_state = State.CHASING
	last_known_player_pos = player.global_position
	print("Enemy: Chasing player!")

func _enter_search_state():
	current_state = State.SEARCHING
	search_timer = search_duration
	nav_agent.target_position = last_known_player_pos
	print("Enemy: Searching for player...")

func _enter_roaming_state():
	current_state = State.ROAMING
	player = null
	_set_random_roam_target()
	roam_wait_timer = 0
	print("Enemy: Back to roaming")

func _find_player_flashlight():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player_node = players[0]
		player = player_node  # Store player reference
		if player_node.has_node("PointLight2D2/Flashlight area"):
			player_flashlight_area = player_node.get_node("PointLight2D2/Flashlight area")
			print("Found player flashlight area")
		else:
			print("ERROR: Player flashlight area not found!")

func _check_flashlight_stun():
	if not player_flashlight_area or not player:
		return
	
	# Check if this enemy is overlapping with the player's flashlight area
	var overlapping_bodies = player_flashlight_area.get_overlapping_bodies()
	var is_in_light = self in overlapping_bodies
	
	# If in light, also check line of sight to player
	if is_in_light:
		is_in_light = _has_line_of_sight_to_player()
	
	if is_in_light and not is_stunned:
		print("Enemy detected in flashlight with line of sight!")
		_enter_stunned_state()
	elif not is_in_light and is_stunned:
		print("Enemy left flashlight or lost line of sight")
		_exit_stunned_state()

func _process_stunned(delta):
	# Stand still - don't move, force velocity to zero
	velocity = Vector2.ZERO
	move_and_slide()
	
	# Stop animation or play idle when stunned
	if sprite and sprite.animation.begins_with("walk_"):
		var direction = sprite.animation.replace("walk_", "")
		if sprite.sprite_frames.has_animation("idle_" + direction):
			sprite.play("idle_" + direction)
		else:
			sprite.stop()

func _enter_stunned_state():
	previous_state = current_state
	current_state = State.STUNNED
	is_stunned = true
	print("Enemy: Stunned by flashlight!")

func _exit_stunned_state():
	current_state = previous_state
	is_stunned = false
	print("Enemy: Recovered from stun")

func _update_movement_animation(direction: Vector2):
	if not sprite:
		return
	
	# Determine animation based on movement direction (4 directions)
	var angle = rad_to_deg(direction.angle())
	
	var anim_name = "walk_down"
	
	if angle >= -45 and angle < 45:
		anim_name = "walk_right"
	elif angle >= 45 and angle < 135:
		anim_name = "walk_down"
	elif angle >= -135 and angle < -45:
		anim_name = "walk_up"
	else:
		anim_name = "walk_left"
	
	# Only change animation if it's different from current
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
