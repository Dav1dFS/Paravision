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
const RUN_FOV_BONUS: float = 8.0
var fov_bonuses: float = 0.0

@onready var player_collider = $CollisionShape3D
@onready var capsule_shape = $CollisionShape3D.shape
@onready var head = $Head
@onready var hand = $Head/Camera3D/Hand
@onready var camera = $Head/Camera3D
@onready var camcorder_scene = $Head/Camera3D/Camarascene
@onready var raycast = $Head/Camera3D/ObjectDetector
@onready var player_canvas_layer: CanvasLayer = $CanvasLayer
@onready var player_view_night_vision_shader: ColorRect = $CanvasLayer/NightVisionShader
@onready var camcorder_canvas_layer: CanvasLayer = $Head/Camera3D/Camarascene/SubViewport/CanvasLayer
@onready var camcorder_night_vision_shader: ColorRect = $Head/Camera3D/Camarascene/SubViewport/CanvasLayer/NightVisionShader
@onready var cam_overlay: TextureRect = $CanvasLayer/CamOverlay
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var light_nv: OmniLight3D = $Head/Camera3D/OmniLight3D
@onready var night_vision_audio: AudioStreamPlayer3D = $Head/Camera3D/AudioNV
@onready var camera_audio: AudioStreamPlayer3D = $Head/Camera3D/AudioCam

var gravity: float = 9.8
var crouched: bool = false
var current_interactable = null
var is_using_camera: bool = false
var night_vision_on: bool = false
var is_swapping_modes: bool = false
var initial_fov: float
var zoomed_fov: float = 60.0
var night_vision_was_on: bool = false

# Multiply stuff
var held_object: Node3D = null
var can_multiply: bool = false

var inverted: bool
var north: bool
var gravity_toggle: bool
var horizontal_anchor: bool
var x_axis: bool
var z_axis: bool

@export var gravity_anchor_ui: Control
var current_anchor: String

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	initial_fov = camera.fov
	player_canvas_layer.visible = false
	player_view_night_vision_shader.visible = false
	#camcorder_canvas_layer.visible = false
	cam_overlay.visible = false
	camcorder_night_vision_shader.visible = false
	light_nv.visible = false
	
	gravity_toggle = false
	play_animation("idle")
	current_anchor = "down"

	if gravity_anchor_ui:
		gravity_anchor_ui.visible = false
		gravity_anchor_ui.anchor_selected.connect(_on_anchor_selected)

func _on_anchor_selected(anchor: String):
	current_anchor = anchor
	match anchor:
		"down":
			_on_down_pressed()
		"up":
			_on_up_pressed()
		"north":
			_on_north_pressed()
		"south":
			_on_south_pressed()
		"east":
			_on_east_pressed()
		"west":
			_on_west_pressed()

func play_animation(anim_name: String):
	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		var available_anims = animation_player.get_animation_list()
		print("[Animation] Animações disponíveis: %s" % available_anims)
		if animation_player.has_animation("idle"):
			animation_player.play("idle")
		else:
			push_error("Nao tem nenhuma animation")

func _process(_delta: float):
	if Gamestate.has_camera:
		if Input.is_action_just_pressed("use_camera"):
			if animation_player.is_playing():
				return
			is_using_camera = !is_using_camera
			update_camera_view()
	
	if is_using_camera:
		Gamestate.is_using_camera = true
		if Input.is_action_just_pressed("night_vision"):
			night_vision_on = !night_vision_on
			update_night_vision()
		gravity_toggle_func()
	else:
		Gamestate.is_using_camera = false

func _unhandled_input(event):
	if gravity_toggle:
		return
		
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(60))

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
		match horizontal_anchor:
			false:
				gravity_calc(delta, inverted, 0, 0, gravity)
			true:
				gravity_calc(delta, x_axis, gravity, 0, 0)
				gravity_calc(delta, z_axis, 0, gravity, 0)
	
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		match horizontal_anchor:
			false:
				jump_calc(inverted, JUMP_VELOCITY, velocity.x, velocity.z)
			true:
				jump_calc(x_axis, velocity.y, JUMP_VELOCITY, velocity.z)
				jump_calc(z_axis, velocity.y, velocity.x, JUMP_VELOCITY)

	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if is_on_floor():
		if direction:
			match horizontal_anchor:
				false:
					vertical_grav_floor_movement(false, direction, 1)
					vertical_grav_floor_movement(true, direction, -1)
				true:
					hori_grav_floor_movement_X(x_axis, false, -1, direction.x, 1, direction.z, "north")
					hori_grav_floor_movement_X(x_axis, true, 1, direction.x, 1, direction.z, "south")
					hori_grav_floor_movement_Z(z_axis, false, 1, direction.x, -1, direction.z, "east")
					hori_grav_floor_movement_Z(z_axis, true, 1, direction.x, 1, direction.z, "west")
		else:
			if horizontal_anchor == false:
				velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
				velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
			elif horizontal_anchor == true:
				lerp_after_mov_X(direction, delta, x_axis, 7.0, "north")
				lerp_after_mov_X(direction, delta, x_axis, 7.0, "south")
				lerp_after_mov_Z(direction, delta, z_axis, 7.0, "east")
				lerp_after_mov_Z(direction, delta, z_axis, 7.0, "west")
	else:
		if horizontal_anchor == false:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)
		elif horizontal_anchor == true:
			lerp_after_mov_X(direction, delta, x_axis, 3.0, "north") 
			lerp_after_mov_X(direction, delta, x_axis, 3.0, "south")
			lerp_after_mov_Z(direction, delta, z_axis, 3.0, "east")
			lerp_after_mov_Z(direction, delta, z_axis, 3.0, "west")

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

	if !is_using_camera:
		var normal_target = BASE_FOV + FOV_CHANGE * velocity_clamped + fov_bonuses
		camera.fov = lerp(camera.fov, normal_target, delta * 8.0)
	
	if held_object and is_using_camera and Gamestate.is_using_camera:
		if Input.is_action_just_pressed("multiply"):
			held_object.multiply()
		
		if Input.is_action_just_pressed("reset_clones"):
			held_object.reset_all_clones()

	if held_object and Input.is_action_just_pressed("drop"):
		held_object.drop()
		held_object = null
		
	move_and_slide()
	check_hover_collision()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.x = cos(time * BOB_FREQUENCY / 2) * BOB_AMPLITUDE
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMPLITUDE
	return pos

func can_stand() -> bool:
	
	var up = up_direction.normalized()
	var head_position = global_transform.origin + up * (capsule_shape.height * 0.5)
	var stand_target_point = head_position + up * (standing_height - capsule_shape.height + 0.05)

	var ray_params = PhysicsRayQueryParameters3D.new()
	ray_params.from = head_position
	ray_params.to = stand_target_point
	ray_params.exclude = [self]

	var collision = get_world_3d().direct_space_state.intersect_ray(ray_params)
	return collision == {}

func check_hover_collision():
	if !raycast.is_colliding():
		hide_current_label()
		return
		
	var hover_collider = raycast.get_collider()
	
	if hover_collider is RigidBody3D:
		if hover_collider.is_in_group("Multiplicable"):
			if hover_collider.has_meta("is_multiplicable_clone") or hover_collider.get("is_clone"):
				hide_current_label()
				return
			
			if !hover_collider.has_method("show_label"):
				hide_current_label()
				return
			
			if current_interactable == hover_collider:
				return
			
			hide_current_label()
			current_interactable = hover_collider
			current_interactable.show_label()
			return
	
	if !hover_collider or !is_instance_valid(hover_collider) or !hover_collider.has_method("show_label"):
		hide_current_label()
		return
	
	if current_interactable == hover_collider:
		return
		
	hide_current_label()
	current_interactable = hover_collider
	current_interactable.show_label()
	
func hide_current_label():
	if current_interactable:
		current_interactable.hide_label()
		current_interactable = null

func interact():
	if not raycast.is_colliding():
		return
	
	var hit = raycast.get_collider()
	if hit:
		if hit.is_in_group("Camcorder"):
			hit.pickup_camcorder()
		elif hit.is_in_group("Multiplicable"):
			if hit.has_meta("is_multiplicable_clone") or hit.is_clone:
				return
			
			if held_object:
				held_object.drop()
				held_object = null
			else:
				hit.pickup(hand)
				held_object = hit
		elif hit.is_in_group("Interactable"):
			hit.interact()
			
func update_camera_view():
	is_swapping_modes = true
	if is_using_camera:
		animation_player.play("Raise_Camera")
		camcorder_scene.visible = true
	else:
		animation_player.play_backwards("Raise_Camera")
		camera.fov = initial_fov
		camcorder_scene.visible = true
		cam_overlay.visible = false
		if player_view_night_vision_shader.visible == true:
			player_view_night_vision_shader.visible = false
			night_vision_was_on = true
		else:
			player_view_night_vision_shader.visible = false
			night_vision_was_on = false

func update_night_vision():
	if night_vision_on:
		#light_nv.visible = true
		#player_canvas_layer.visible = true
		night_vision_audio.play()
		player_view_night_vision_shader.visible = true
		camcorder_canvas_layer.visible = true
		camcorder_night_vision_shader.visible = true
	else:
		night_vision_audio.stop()
		#player_canvas_layer.visible = false
		player_view_night_vision_shader.visible = false
		#camcorder_canvas_layer.visible = false
		camcorder_night_vision_shader.visible = false
		light_nv.visible = false

func _on_animation_player_animation_finished(_anim_name: StringName):
	if !is_swapping_modes:
		return
		
	camcorder_scene.visible = false
	if is_using_camera:
		camera_audio.play()
		player_canvas_layer.visible = true
		cam_overlay.visible = true
		camera.fov = zoomed_fov
		if night_vision_was_on:
			player_view_night_vision_shader.visible = true
	else:
		camera_audio.stop()
		return
		#camera.fov = initial_fov
	is_swapping_modes = false

# Gravity Anchors
func _on_down_pressed():
	current_anchor = "down"
	play_animation("idle")
	inverted = false
	gravity = 9.8
	up_direction = Vector3.UP
	JUMP_VELOCITY = 4.5
	horizontal_anchor = false

func _on_up_pressed():
	current_anchor = "up"
	play_animation("inverted")
	inverted = true
	gravity = -9.8
	up_direction = Vector3.DOWN
	JUMP_VELOCITY = -4.5
	horizontal_anchor = false

func _on_north_pressed():
	current_anchor = "north"
	horizontal_anchor = true
	play_animation("north")
	inverted = true
	gravity = 9.8
	JUMP_VELOCITY = 4.5
	up_direction = Vector3.RIGHT
	x_axis = false

func _on_south_pressed():
	current_anchor = "south"
	horizontal_anchor = true
	play_animation("south")
	gravity = -9.8
	JUMP_VELOCITY = -4.5
	up_direction = Vector3.LEFT
	x_axis = true

func _on_east_pressed():
	current_anchor = "east"
	horizontal_anchor = true
	play_animation("east")
	gravity = 9.8
	JUMP_VELOCITY = 4.5
	up_direction = Vector3.BACK
	z_axis = false

func _on_west_pressed():
	current_anchor = "west"
	horizontal_anchor = true
	play_animation("west")
	gravity = -9.8
	JUMP_VELOCITY = -4.5
	up_direction = Vector3.FORWARD
	z_axis = true

func gravity_toggle_func():
	if Input.is_action_just_pressed("gravity_toggle"):
		gravity_toggle = !gravity_toggle
		
	if gravity_toggle:
		gravity_anchor_ui.visible = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		gravity_anchor_ui.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func vertical_grav_floor_movement(inv_bool: bool, direction, z_float: float):
	if inverted == inv_bool:
		velocity.x = direction.x * speed
		velocity.z = z_float * direction.z * speed
			
func hori_grav_floor_movement_X(axis_bool: bool, axis_bool_state: bool, y_float: float, direction_2, z_float: float, direction_3, current_anchor_value: String):
	if axis_bool == axis_bool_state and current_anchor == current_anchor_value:
		velocity.y = y_float * direction_2 * speed
		velocity.z = z_float * direction_3 * speed
			
func hori_grav_floor_movement_Z(axis_bool: bool, axis_bool_state: bool, x_float: float, direction_1, y_float: float, direction_2, current_anchor_value: String):
	if axis_bool == axis_bool_state and current_anchor == current_anchor_value:
		velocity.x = x_float * direction_1 * speed
		velocity.y = y_float * direction_2 * speed
			
func gravity_calc(delta, anchor_bool: bool, grav_float: float, grav_float_2: float, grav_float_3: float):
	if anchor_bool == true or anchor_bool == false:
		velocity.x -= grav_float * delta
		velocity.z -= grav_float_2 * delta
		velocity.y -= grav_float_3 * delta

func jump_calc(anchor_bool: bool, value_1: float, value_2: float, value_3: float):
	if anchor_bool == true or anchor_bool == false:
		velocity.y = value_1
		velocity.x = value_2
		velocity.z = value_3

func lerp_after_mov_X(direction, delta, anchor_bool: bool, final_value: float, current_anchor_value: String):
	if (anchor_bool == true or anchor_bool == false) and current_anchor == current_anchor_value:
		velocity.y = lerp(velocity.y, direction.y * speed, delta * final_value)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * final_value)

func lerp_after_mov_Z(direction, delta, anchor_bool: bool, final_value: float, current_anchor_value: String):
	if (anchor_bool == true or anchor_bool == false) and current_anchor == current_anchor_value:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * final_value)
		velocity.y = lerp(velocity.y, direction.y * speed, delta * final_value)
