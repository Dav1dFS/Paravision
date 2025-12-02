extends Node

var invis_toggle:bool


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Invis_Toggle"):
		invis_toggle = !invis_toggle
		
		if invis_toggle == true:
			print("invisible bitch")
			
			
		if invis_toggle == false:
			print("visible bitch")
	pass
