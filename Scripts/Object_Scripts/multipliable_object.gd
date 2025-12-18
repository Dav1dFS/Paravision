extends RigidBody3D

@export var max_multiplications: int = 5
@export var scene_root: Node3D
@onready var interact_label: Label3D = $Label3D

var is_held: bool = false
var player_hand_node: Node3D = null
var original_collision_layer: int
var original_collision_mask: int
var is_clone: bool = false

func _ready():
	if is_clone:
		remove_interactivity()
		return

	interact_label.visible = false
	
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	
	add_to_group("Multiplicable")
	contact_monitor = true
	max_contacts_reported = 4
	gravity_scale = 1.0

func remove_interactivity():
	if interact_label:
		interact_label.queue_free()
		
	remove_from_group("Multiplicable")
	
	# Garante física ativa
	freeze = false
	gravity_scale = 1.0

func show_label():
	if not is_held and not is_clone:
		interact_label.visible = true

func hide_label():
	if interact_label:
		interact_label.visible = false

func pickup(hand_node: Node3D):
	if is_held or is_clone:
		return
		
	is_held = true
	player_hand_node = hand_node
	
	var current_parent = get_parent()
	current_parent.remove_child(self)
	hand_node.add_child(self)
	
	# Reseta a transformação local para ficar na posição correta da mão
	transform = Transform3D.IDENTITY
	position = Vector3.ZERO
	rotation = Vector3.ZERO
	
	# Desabilita física enquanto está na mão
	freeze = true
	collision_layer = 0
	collision_mask = 0
	
	hide_label()

func drop():
	if not is_held:
		return
		
	is_held = false
	
	# Guarda a posição e rotação global ANTES de remover
	var drop_position = global_position
	var drop_rotation = global_rotation
	var drop_basis = global_transform.basis
	
	var hand_parent = get_parent()
	hand_parent.remove_child(self)
	scene_root.add_child(self)
	global_position = drop_position
	global_rotation = drop_rotation
	
	# Reabilita física
	freeze = false
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	gravity_scale = 1.0
	
	# Adiciona um pequeno impulso para frente
	var forward_direction = -drop_basis.z
	apply_central_impulse(forward_direction * 3.0)

func multiply():
	if not is_held:
		return
		
	var clones_count = 0
	for child in scene_root.get_children():
		if child.is_in_group("Multiplicable") or (child is RigidBody3D and child.has_meta("is_multiplicable_clone")):
			clones_count += 1
	
	if clones_count >= max_multiplications:
		return
	
	# Cria um clone SIMPLES sem script
	var clone = duplicate(DUPLICATE_USE_INSTANTIATION)
	clone.is_clone = true
	clone.set_meta("is_multiplicable_clone", true)
	
	var clone_label = clone.get_node_or_null("Label3D")
	if clone_label:
		clone_label.queue_free()
	
	clone.remove_from_group("Multiplicable")
	scene_root.add_child(clone)
	
	# Posiciona o clone próximo à mão do jogador
	var spawn_offset = Vector3(randf_range(-1.0, 1.0), randf_range(0.5, 1.5), randf_range(-1.0, 1.0))
	clone.global_position = player_hand_node.global_position + spawn_offset
	clone.rotation = Vector3(randf_range(0, TAU), randf_range(0, TAU), randf_range(0, TAU))
	
	# Garante que o clone tem física ativa
	clone.freeze = false
	clone.collision_layer = original_collision_layer
	clone.collision_mask = original_collision_mask
	clone.gravity_scale = 1.0

func reset_all_clones():
	var clones_removed = 0

	# Cria uma lista dos clones para remover (evita modificar array durante iteração)
	var clones_to_remove = []
	
	for child in scene_root.get_children():
		if child is RigidBody3D and child != self:
			if child.has_meta("is_multiplicable_clone") or child.get("is_clone"):
				clones_to_remove.append(child)
	
	for clone in clones_to_remove:
		clone.queue_free()
		clones_removed += 1
