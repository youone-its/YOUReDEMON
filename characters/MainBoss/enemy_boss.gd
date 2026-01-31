extends CharacterBody2D

enum State {IDLE, TARGETING, CHARGING, STUNNED}
var current_state = State.IDLE

@export var walk_speed = 100.0
@export var charge_speed = 550.0 # Buat sangat cepat
var target_point = Vector2.ZERO
var target_node = null

@onready var anim = $AnimatedSprite2D

func _physics_process(_delta):
	match current_state:
		State.IDLE:
			_choose_next_action()
		State.TARGETING:
			# Boss diam sebentar melihat target sebelum lari
			pass 
		State.CHARGING:
			_move_to_point(charge_speed)
		State.STUNNED:
			velocity = Vector2.ZERO
			move_and_slide()

func _choose_next_action():
	var active_altars = []
	for altar in get_tree().get_nodes_in_group("altars"):
		if altar.is_active and not altar.get("is_special_altar"):
			active_altars.append(altar)
	
	# Pilih target (Altar atau Player)
	if active_altars.size() > 0 and randf() > 0.5:
		target_node = _get_closest(active_altars)
	else:
		target_node = get_tree().get_first_node_in_group("player")
	
	if target_node:
		current_state = State.TARGETING
		# Kunci posisi target SEKARANG
		target_point = target_node.global_position
		
		# Animasi/Efek sebelum charge (misal diam 0.7 detik)
		await get_tree().create_timer(0.7).timeout
		current_state = State.CHARGING

func _move_to_point(speed):
	var dir = global_position.direction_to(target_point)
	velocity = dir * speed
	_update_animation(velocity)
	move_and_slide()
	
	# Jika sampai di titik target atau menabrak sesuatu
	if global_position.distance_to(target_point) < 20 or get_slide_collision_count() > 0:
		_apply_impact()

func _apply_impact():
	velocity = Vector2.ZERO
	# Cek apakah ada Altar atau Player di dekat titik impact
	# (Bisa menggunakan AttackArea yang sudah kamu buat sebelumnya)
	
	current_state = State.STUNNED
	anim.play("attack") # Play animasi attack saat sampai
	
	# Beri waktu jeda sebelum cari target lagi
	await get_tree().create_timer(1.2).timeout 
	current_state = State.IDLE

func _update_animation(vel):
	if vel.length() < 10: return
	
	if abs(vel.x) > abs(vel.y):
		anim.play("ngejar_right" if vel.x > 0 else "ngejar_left")
	else:
		anim.play("ngejar_down" if vel.y > 0 else "ngejar_up")

func _get_closest(nodes):
	var closest = nodes[0]
	for node in nodes:
		if global_position.distance_to(node.global_position) < global_position.distance_to(closest.global_position):
			closest = node
	return closest

func _on_attack_area_body_entered(body):
	if current_state == State.CHARGING:
		if body.is_in_group("player") and body.has_method("take_damage"):
			body.take_damage(10)
		elif body.is_in_group("altars") and body.has_method("deactivate_altar"):
			if not body.get("is_special_altar"):
				body.deactivate_altar()
