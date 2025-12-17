extends CharacterBody3D

var speed 	
const JUMP_VELOCITY: float = 4.5
const WALK_SPEED: float = 4.5
const SPRINT_SPEED: float = 8.0
const CROUCH_SPEED: float = 2.0
const SENSITIVITY: float = 0.003

var crouch_height: float = 0.5
var standing_height: float = 2.0
var is_crouching: bool = false
var is_sprinting: bool = false
var target_height: float = 2.0

const BOB_FREQUENCY: float = 2.4
const BOB_AMPLITUDE: float = 0.50
var T_BOB: float = 0.0

const BASE_FOV: float = 75.0
const FOV_CHANGE: float = 1.5
const RUN_FOV_BONUS: float = 6.0
var fov_bonuses: float = 0.0

@onready var player_collider = $CollisionShape3D
@onready var capsule_shape = $CollisionShape3D.shape
@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var raycast = $Head/Camera3D/ObjectDetector

@export var cubo_scene: RigidBody3D
@export var spawn_area: Node3D    
@export var cubo_original: Node3D

var gravity: float = 9.8
var crouched: bool = false
var current_interactable = null

# Número máximo de clones permitidos
var max_clones: int = 5

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	if Input.is_action_just_pressed("interact"):
		interact()
	
	if Input.is_action_just_pressed("reset_clones"):
		apagar_clones()
	
	if Input.is_action_just_pressed("crouch_stand") and is_on_floor():
		if is_crouching:
			if can_stand():
				is_crouching = false
		else:
			is_crouching = true

	if is_crouching:
		target_height = crouch_height
		speed = CROUCH_SPEED
		is_sprinting = false
	else:
		target_height = standing_height
		speed = SPRINT_SPEED if Input.is_action_pressed("run") else WALK_SPEED
		is_sprinting = Input.is_action_pressed("run")

	capsule_shape.height = lerp(capsule_shape.height, target_height, delta * 6.0)

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	T_BOB += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(T_BOB)

	var horizontal_speed = Vector3(velocity.x, 0, velocity.z).length()
	var velocity_clamped = clamp(horizontal_speed, 0.0, SPRINT_SPEED * 2)
	if is_sprinting and is_on_floor():
		fov_bonuses = RUN_FOV_BONUS
	elif is_crouching:
		fov_bonuses = -10.0
	else:
		fov_bonuses = 0.0

	camera.fov = lerp(camera.fov, BASE_FOV + FOV_CHANGE * velocity_clamped + fov_bonuses, delta * 8.0)

	move_and_slide()
	check_hover_collision()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	return pos

func can_stand() -> bool:
	var head_position = global_transform.origin + Vector3(0, capsule_shape.height * 0.5, 0)
	var stand_target_point = head_position + Vector3.UP * (standing_height - capsule_shape.height + 0.05)

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = head_position
	ray_params.to = stand_target_point
	ray_params.exclude = [self]

	var collision = get_world_3d().direct_space_state.intersect_ray(ray_params)
	return collision == {}

func check_hover_collision():
	if raycast.is_colliding():
		var hover_collider = raycast.get_collider()
		if hover_collider and is_instance_valid(hover_collider):
			var cubo_node = find_cubo_parent(hover_collider)
			
			if cubo_node and cubo_node.has_method("show_label"):
				if current_interactable != cubo_node:
					if current_interactable:
						current_interactable.hide_label()
					current_interactable = cubo_node
					current_interactable.show_label()
			elif hover_collider.has_method("show_label"):
				if current_interactable != hover_collider:
					if current_interactable:
						current_interactable.hide_label()
					current_interactable = hover_collider
					current_interactable.show_label()
			else:
				hide_current_label()
		else:
			hide_current_label()
	else:
		hide_current_label()

func hide_current_label():
	if current_interactable:
		current_interactable.hide_label()
		current_interactable = null

func find_cubo_parent(node: Node) -> Node:
	var current = node
	var depth = 0
	while current != null and depth < 10:
		# PRIMEIRO verifica se tem a variável is_clone (é o Node3D do cubo)
		if "is_clone" in current:
			return current
		
		current = current.get_parent()
		depth += 1
	
	return null

func interact():
	if not raycast.is_colliding():
		return
	
	var hit = raycast.get_collider()
	if hit == null:
		return
	
	# Procura o nó raiz do cubo (Node3D com is_clone)
	var cubo_node = find_cubo_parent(hit)
	
	if cubo_node:
		# Verifica se tem a variável is_clone
		if "is_clone" in cubo_node:
			if not cubo_node.is_clone:
				# É o cubo ORIGINAL - pode clonar
				spawn_cubo_na_area()
			else:
				# É um CLONE - não pode clonar
				print("Este é um CLONE! Apenas o cubo original pode gerar novos cubos.")
	else:
		# Não é um cubo, tenta interagir normalmente
		if hit.has_method("interact"):
			hit.interact()

func random_position_in_area() -> Vector3:
	if spawn_area == null:
		return global_position
	
	var shape = spawn_area.get_node("CollisionShape3D").shape
	var extents = shape.extents
	
	var x = randf_range(-extents.x, extents.x)
	var z = randf_range(-extents.z, extents.z)
	
	var pos = spawn_area.global_position + Vector3(x, 0, z)
	
	# 🔒 FORÇAR ALTURA DO CUBO ORIGINAL
	if cubo_original:
		pos.y = cubo_original.global_position.y
	
	return pos


func spawn_cubo_na_area():
	if cubo_scene == null or spawn_area == null:
		print("ERRO: cubo_scene ou spawn_area não definidos!")
		return

	# Contar clones existentes
	var num_clones = get_tree().get_nodes_in_group("clones").size()

	if num_clones >= max_clones:
		print("Limite de clones atingido! Máximo: " + str(max_clones))
		return

	# Instanciar o cubo clone
	var novo_cubo = cubo_scene.instantiate()
	novo_cubo.global_position = random_position_in_area()
	

# GARANTIR escala limpa
	novo_cubo.scale = Vector3.ONE

	
	# IMPORTANTE: Marcar como clone ANTES de adicionar à cena
	if "is_clone" in novo_cubo:
		novo_cubo.is_clone = true
	
	# Adicionar à cena
	get_tree().current_scene.add_child(novo_cubo)
	
	
	print("Clone criado! Total de clones: " + str(num_clones + 1))

func apagar_clones():
	var clones = get_tree().get_nodes_in_group("clones")
	var count = clones.size()
	for c in clones:
		if is_instance_valid(c):
			c.queue_free()
	print("Clones apagados! Total removido: " + str(count))
