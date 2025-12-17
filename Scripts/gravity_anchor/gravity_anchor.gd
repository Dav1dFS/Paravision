extends Node

@export var UI_Parent_Node:Control

@export var Player:CharacterBody3D

@export var up_button:Button

@export var down_button:Button

@export var player_anim_player:AnimationPlayer  

var gravity_toggle:bool

var player_pos: Vector3

var inverted: bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_toggle = false
	
	player_anim_player.play("idle")
	
	


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
up_btn_bool: bool, down_btn_bool: bool, msg: String,anim_name: String, anim_name_2: String, anim_bool: bool) -> void:
	
	#1 - adjust player to make it neat:	
	if inverted == anim_bool:
		player_anim_player.play(anim_name)
		if player_anim_player.is_playing() == false:
				player_anim_player.play(anim_name_2)


	#2 - change gravity
	PhysicsServer3D.area_set_param(get_viewport().find_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY, gravity_vel)
	Player.gravity = gravity_vel
	Player.up_direction = player_dir
	Player.JUMP_VELOCITY = jump_vel
	
	
	#3 - stop people from messing with the gravity further: DONE
	up_button.disabled = up_btn_bool
	down_button.disabled = down_btn_bool
	
	#4 -  return back to gameplay: DONE
	gravity_toggle = false
	print(msg)
	

func _on_up_pressed() -> void:
	inverted = true
	change_gravity(-9.8, Vector3.DOWN, -4.5, true, false, "you want up?", "inverting", "inverted", true)


func _on_down_pressed() -> void:
	inverted = false
	change_gravity(9.8, Vector3.UP, 4.5, false, true, "you goin doooown!", "back_to_idle", "idle", false)

	
