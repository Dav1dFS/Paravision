extends Node

@export var UI_Parent_Node:Control

@export var Player:CharacterBody3D

@export var up_button:Button

@export var down_button:Button

var gravity_toggle:bool

var player_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_toggle = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gravity_toggle_func()
	
	player_pos = Player.transform.origin
	

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

func change_gravity(gravity_vel: float, player_dir: Vector3, jump_vel: float,
 pos_offset: float, rot_angle: float, up_btn_bool: bool, down_btn_bool: bool, msg: String, rot_x: bool, rot_y: bool) -> void:
	
	#1 - adjust player to make it neat: Mouse Input PROBLEMS and rotation Problems
	Player.position = Vector3 (Player.position.x, Player.position.y + pos_offset, Player.position.z)
	Player.rotate(Vector3(1, 0 ,0), Player.rotation.x + rot_angle)
	Player.rotation.z = 0
	#Player.invert_camera_x_axis = rot_x
	#Player.invert_camera_x_axis = rot_ys
	
	
	
	#2 - changes gravity : DONE
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity_vel)
	Player.gravity = gravity_vel
	Player.up_direction = player_dir
	Player.jump_velocity = jump_vel
	
	
	
	#3 - stops people from messing with the gravity further: DONE
	up_button.disabled = up_btn_bool
	down_button.disabled = down_btn_bool
	
	#4 -  returns back to gameplay: DONE
	gravity_toggle = false
	print(msg)
	

func _on_up_pressed() -> void:
	change_gravity(-9.8, Vector3.DOWN, -4.5, 1, 180, true, false, "you want up?", true, true)


func _on_down_pressed() -> void:
	change_gravity(9.8, Vector3.UP, 4.5, -1, -180, false, true, "you goin doooown!", false, false)
