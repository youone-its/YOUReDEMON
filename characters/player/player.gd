extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 150.0

# Current direction (0=down, 1=up, 2=left, 3=right)
var current_direction: int = 0

func _ready():
	# Add the player to the "player" group for easy reference
	add_to_group("player")

func _physics_process(delta):
	# Get input direction
	var input_direction = Vector2.ZERO
	
	# Check WASD keys
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_direction.y -= 1
		current_direction = 1  # Up
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_direction.y += 1
		current_direction = 0  # Down
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_direction.x -= 1
		current_direction = 2  # Left
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_direction.x += 1
		current_direction = 3  # Right
	
	# Normalize diagonal movement so it's not faster
	if input_direction.length() > 0:
		input_direction = input_direction.normalized()
	
	# Set velocity
	velocity = input_direction * speed
	
	# Move the character
	move_and_slide()
	
	# Update animation based on movement
	update_animation(input_direction)

func update_animation(direction: Vector2):
	# Get reference to sprite (you can replace this with AnimatedSprite2D later)
	var sprite = $Sprite2D
	
	if direction.length() > 0:
		# Character is moving
		# When you add animations, you can switch between walk animations here
		# Example: $AnimatedSprite2D.play("walk_" + ["down", "up", "left", "right"][current_direction])
		pass
	else:
		# Character is idle
		# Example: $AnimatedSprite2D.play("idle_" + ["down", "up", "left", "right"][current_direction])
		pass
