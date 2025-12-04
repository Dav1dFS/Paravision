extends Node

var invis_toggle:bool

#the objects material
@export var invis_mat:StandardMaterial3D

#the object itself
@export var obj:CSGBox3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Invis_Toggle"):
		invis_toggle = !invis_toggle
		
		#makes object invisible and deactivates colisions
		if invis_toggle == true:
			print("invisible bitch")
			invis_mat.albedo_color = "ff00ff00"
			obj.use_collision = false
			
		#makes object visible again and activates colisions
		if invis_toggle == false:
			print("visible bitch")
			invis_mat.albedo_color = "ff00ff"
			obj.use_collision = true
	pass
