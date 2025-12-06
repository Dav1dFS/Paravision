extends Node

@export var UI_Parent_Node:Control

var gravity_toggle:bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	gravity_toggle = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	gravity_toggle_func()
	
		
	

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
