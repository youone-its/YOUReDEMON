extends CharacterBody2D

# Movement speed in pixels per second
@export var speed: float = 150.0

# Current direction for animations
var current_direction: String = "down"
var is_moving: bool = false

func _ready():
	# Add the player to the "player" group for easy reference
	add_to_group("player")

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
	
	# Update animation
	update_animation()

func update_animation():
	var anim_sprite = $AnimatedSprite2D
	
	if is_moving:
		# Play walk animation for current direction
		anim_sprite.play("walk_" + current_direction)
	else:
		# Play idle animation for current direction
		anim_sprite.play("idle_" + current_direction)
