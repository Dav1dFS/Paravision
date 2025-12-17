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
@onready var camcorder_scene = $Head/Camera3D/Camarascene
@onready var raycast = $Head/Camera3D/ObjectDetector
@onready var player_canvas_layer: CanvasLayer = $CanvasLayer
@onready var player_view_night_vision_shader: ColorRect = $CanvasLayer/NightVisionShader
@onready var camcorder_canvas_layer: CanvasLayer = $Head/Camera3D/Camarascene/SubViewport/CanvasLayer
@onready var camcorder_night_vision_shader: ColorRect = $Head/Camera3D/Camarascene/SubViewport/CanvasLayer/NightVisionShader
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var cubo_scene: PackedScene  
@export var spawn_area: Node3D  

var gravity: float = 9.8
var crouched: bool = false
var current_interactable = null
var is_using_camera: bool = false
var night_vision_on: bool = false
var is_swapping_modes: bool = false
var initial_fov: float
var zoomed_fov: float = 60.0
var night_vision_was_on: bool = false


#gravity anchor stuff
var inverted: bool
var north: bool

var gravity_toggle: bool

var horizontal_anchor: bool

var x_axis: bool

var z_axis: bool

@export var UI_Parent_Node:Control

@export var player_anim_player:AnimationPlayer  

@export var up_btn:Button

@export var down_btn:Button

@export var e_btn:Button

@export var w_btn:Button

@export var s_btn:Button

@export var n_btn:Button

var current_anchor: String


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	initial_fov = camera.fov
	player_canvas_layer.visible = false
	player_view_night_vision_shader.visible = false
	camcorder_canvas_layer.visible = false
	camcorder_night_vision_shader.visible = false
	
	down_btn.disabled = true
	
	gravity_toggle = false
	
	player_anim_player.play("idle")

func _process(delta: float) -> void:
	gravity_toggle_func()
	
	
	

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta):
	if Input.is_action_just_pressed("use_camera"):
		if animation_player.is_playing():
			return
		is_using_camera = !is_using_camera
		update_camera_view()
	
	if is_using_camera:
		if Input.is_action_just_pressed("night_vision"):
			night_vision_on = !night_vision_on
			update_night_vision()
		
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
		
		#does gravity acording to selected anchor
		match horizontal_anchor:
			false:
				gravity_calc(delta, inverted, 0, 0, gravity)
			true:
				gravity_calc(delta, x_axis,gravity, 0, 0)
				gravity_calc(delta, z_axis, 0, gravity, 0)
	
	#does jumping acording to selected anchor
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		match horizontal_anchor:
			false:
				jump_calc (inverted, JUMP_VELOCITY, velocity.x, velocity.z)
			true:
				jump_calc (x_axis, velocity.y, JUMP_VELOCITY, velocity.z)
				jump_calc (z_axis, velocity.y, velocity.x, JUMP_VELOCITY)

	#input
	var input_dir := Input.get_vector("left", "right", "forward", "back")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()


	#does horizontal movement acording to selected anchor
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

	if !is_using_camera and !is_swapping_modes:
		var normal_target = BASE_FOV + FOV_CHANGE * velocity_clamped + fov_bonuses
		camera.fov = lerp(camera.fov, normal_target, delta * 8.0)

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
	if raycast.is_colliding():
		var hit = raycast.get_collider()
		if hit == null:
			return
		
		var root_node = hit
		while root_node.get_parent() != null and not root_node.is_in_group("cubo_original"):
			root_node = root_node.get_parent()
		
		if root_node.is_in_group("cubo_original"):
			spawn_cubo_na_area()
		elif hit.has_method("interact"):
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
		if player_view_night_vision_shader.visible == true:
			player_view_night_vision_shader.visible = false
			night_vision_was_on = true
		else:
			player_view_night_vision_shader.visible = false
			night_vision_was_on = false
	
func update_night_vision():
	if night_vision_on:
		player_canvas_layer.visible = true
		player_view_night_vision_shader.visible = true
		camcorder_canvas_layer.visible = true
		camcorder_night_vision_shader.visible = true
	else:
		player_canvas_layer.visible = false
		player_view_night_vision_shader.visible = false
		camcorder_canvas_layer.visible = false
		camcorder_night_vision_shader.visible = false
	
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if !is_swapping_modes:
		return
		
	camcorder_scene.visible = false
	if is_using_camera:
		camera.fov = zoomed_fov
		if night_vision_was_on == true:
			player_view_night_vision_shader.visible = true
	else:
		camera.fov = initial_fov
	is_swapping_modes = false
	
func random_position_in_area() -> Vector3:
	if spawn_area == null:
		print("ERRO: spawn_area não definido!")
		return global_transform.origin
	
	var shape = spawn_area.get_node("CollisionShape3D").shape
	if shape == null:
		return spawn_area.global_transform.origin
	
	var extents = shape.extents
	var random_offset = Vector3(
		randf_range(-extents.x, extents.x),
		randf_range(-extents.y, extents.y),
		randf_range(-extents.z, extents.z)
	)
	return spawn_area.global_transform.origin + random_offset

func spawn_cubo_na_area():
	if cubo_scene == null or spawn_area == null:
		print("ERRO: cubo_scene ou spawn_area não definidos!")
		return
	
	var novo_cubo = cubo_scene.instantiate()
	novo_cubo.global_transform.origin = random_position_in_area()
	novo_cubo.add_to_group("clones")
	get_tree().current_scene.add_child(novo_cubo)

func apagar_clones():
	var clones = get_tree().get_nodes_in_group("clones")
	for c in clones:
		if is_instance_valid(c):
			c.queue_free()
	print("Clones apagados. Agora:", get_tree().get_nodes_in_group("clones").size())

func _on_down_pressed() -> void:
	
	current_anchor = "down"
	
	#velocity = Vector3.ZERO
	player_anim_player.play("idle")
	inverted = false
	gravity = 9.8
	n_btn.disabled = false
	down_btn.disabled = false
	up_btn.disabled = false
	up_direction = Vector3.UP
	JUMP_VELOCITY = 4.5
	horizontal_anchor = false
	s_btn.disabled = false
	w_btn.disabled = false
	e_btn.disabled = false
	
	UI_Parent_Node.visible = false

func _on_up_pressed() -> void:
	
	current_anchor = "up"
	
	#velocity = Vector3.ZERO
	player_anim_player.play("inverted")
	inverted = true
	gravity = -9.8
	up_btn.disabled = true
	down_btn.disabled = false
	n_btn.disabled = false
	up_direction = Vector3.DOWN
	JUMP_VELOCITY = -4.5
	horizontal_anchor = false
	s_btn.disabled = false
	w_btn.disabled = false
	e_btn.disabled = false
	
	UI_Parent_Node.visible = false


func _on_north_pressed() -> void:
	
	current_anchor = "north"
	
	#velocity.y = 0
	horizontal_anchor = true
	player_anim_player.play("north")
	inverted = true
	gravity = 9.8
	JUMP_VELOCITY = 4.5
	up_direction = Vector3.RIGHT
	x_axis = false
	n_btn.disabled = true
	up_btn.disabled = false
	down_btn.disabled = false
	s_btn.disabled = false
	e_btn.disabled = false
	
	UI_Parent_Node.visible = false

func _on_south_pressed() -> void:
	
	current_anchor = "south"
	
	horizontal_anchor = true
	player_anim_player.play("south")
	gravity = -9.8
	JUMP_VELOCITY = -4.5
	up_direction = Vector3.LEFT
	x_axis = true
	n_btn.disabled = false
	s_btn.disabled = true
	up_btn.disabled = false
	down_btn.disabled = false
	w_btn.disabled = false
	e_btn.disabled = false
	
	UI_Parent_Node.visible = false
	
	
func _on_east_pressed() -> void:
	
	current_anchor = "east"
	
	horizontal_anchor = true
	player_anim_player.play("east")
	gravity = 9.8
	JUMP_VELOCITY = 4.5
	up_direction = Vector3.BACK
	z_axis = false
	n_btn.disabled = false
	s_btn.disabled = false
	up_btn.disabled = false
	down_btn.disabled = false
	e_btn.disabled = true
	w_btn.disabled = false
	
	UI_Parent_Node.visible = false
	

func _on_west_pressed() -> void:
	current_anchor = "west"
	horizontal_anchor = true
	player_anim_player.play("west")
	gravity = -9.8
	JUMP_VELOCITY = -4.5
	up_direction = Vector3.FORWARD
	z_axis = true
	n_btn.disabled = false
	s_btn.disabled = false
	up_btn.disabled = false
	down_btn.disabled = false
	e_btn.disabled = false
	w_btn.disabled = true
	
	
func gravity_toggle_func() -> void:
	if Input.is_action_just_pressed("gravity_toggle"):
		gravity_toggle = !gravity_toggle
		print(gravity_toggle)
		
	if gravity_toggle == true:
		UI_Parent_Node.visible = true	
		Input.mouse_mode =Input.MOUSE_MODE_VISIBLE
	elif gravity_toggle == false:
		UI_Parent_Node.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func vertical_grav_floor_movement(inv_bool: bool, direction, z_float: float):
	if inverted == inv_bool:
			velocity.x = direction.x * speed
			velocity.z = z_float * direction.z * speed
			
func hori_grav_floor_movement_X(axis_bool: bool, axis_bool_state: bool, y_float:float ,  direction_2, z_float:float ,  direction_3, current_anchor_value: String):
		if axis_bool == axis_bool_state && current_anchor == current_anchor_value:
			velocity.y = y_float * direction_2 * speed
			velocity.z = z_float * direction_3 * speed
			
func hori_grav_floor_movement_Z(axis_bool: bool, axis_bool_state: bool, x_float: float, direction_1, y_float:float ,  direction_2, current_anchor_value: String):
		if axis_bool == axis_bool_state && current_anchor == current_anchor_value:
			velocity.x = x_float * direction_1 * speed
			velocity.y = y_float * direction_2 * speed
			
func gravity_calc(delta, anchor_bool: bool, grav_float: float, grav_float_2: float, grav_float_3: float):

	if anchor_bool == true || anchor_bool == false:
		#horizontal axis
		velocity.x -= grav_float * delta
		velocity.z -= grav_float_2 * delta
		
		#vertical axis
		velocity.y -= grav_float_3 * delta
		

func jump_calc(anchor_bool: bool, value_1: float, value_2: float, value_3: float):
	if anchor_bool == true || anchor_bool == false:
		#vertical axis
		velocity.y = value_1
	
		#horizontal axis
		velocity.x = value_2
		velocity.z = value_3

func lerp_after_mov_X (direction, delta, anchor_bool :bool, final_value: float, current_anchor_value: String):
	
	if anchor_bool == true || anchor_bool == false && current_anchor == current_anchor_value:
		velocity.y = lerp(velocity.y, direction.y * speed, delta * final_value)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * final_value)
		

func lerp_after_mov_Z (direction, delta, anchor_bool :bool, final_value: float, current_anchor_value: String):
	
	if anchor_bool == true || anchor_bool == false && current_anchor == current_anchor_value:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * final_value)
		velocity.y = lerp(velocity.y, direction.y * speed, delta * final_value)
