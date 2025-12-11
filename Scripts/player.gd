extends CharacterBody3D

var speed 	
@export var JUMP_VELOCITY: float = 4.5
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

var gravity: float = 9.8
var crouched: bool = false
var current_interactable = null


#gravity anchor stuff
var inverted: bool
var north: bool

@export var UI_Parent_Node:Control


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
			if inverted == false:
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			elif inverted == true:
				velocity.x = direction.x * speed
				velocity.z = -direction.z * speed	
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
	return collision == {}  # True se não houver colisão acima

func check_hover_collision():
	if raycast.is_colliding():
		var hover_collider = raycast.get_collider()
		if hover_collider and is_instance_valid(hover_collider) and hover_collider.has_method("interact") and hover_collider.has_method("show_label"):
			if current_interactable != hover_collider:
				if current_interactable:
					current_interactable.hide_label()
				current_interactable = hover_collider
				current_interactable.show_label()
		else:
			hide_current_label()
	else:
		hide_current_label()

func hide_current_label():
	if current_interactable:
		current_interactable.hide_label()
		current_interactable = null

func interact():
	var hit = raycast.get_collider()
	if raycast.is_colliding():
		if hit and hit.has_method("interact"):
			hit.interact()


func _on_down_pressed() -> void:
	inverted = false
	north = false
	
	#IDEIA: Começar a partir daqui, receber aqui os sinais de qual âncora tá ativa
	#e depois fazer a função das fisicas tipo a script da gravity anchor para se 
	#adaptar com parametros á anchor escolhida atualmente, meter uma animation tree
	#com animaçoes com o player rodado bem para  cada parede e ancora e transicionar automaticamente
	#começar a partir daqui desta parte
	
	
	#ativar TODOS
	#Desativar down


func _on_up_pressed() -> void:
	inverted = true
	
	#desativar up


func _on_north_pressed() -> void:
	north = true
	#desativar north
	
	
	
