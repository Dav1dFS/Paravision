extends Node

var invis_toggle:bool

@export var static_obj:StaticBody3D

#the objects material
@export var invis_mat:StandardMaterial3D

var og_color:Color

#the colision object itself
#@export var colision_shape:CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	invis_toggle = true
	
	#save original color
	og_color = invis_mat.albedo_color
	
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Invis_Toggle"):
		invis_toggle = !invis_toggle
		
		#makes object invisible and deactivates colisions
		if invis_toggle == true:
			print("invis_toggle ON")
			invis_mat.albedo_color = og_color
			#colision_shape.set_deferred("disabled", true)
			
		#makes object visible again and activates colisions
		if invis_toggle == false:
			print("invis_toggle OFF")
			invis_mat.albedo_color = "ff00ff"
			#colision_shape.set_deferred("disabled", false)
			
	
	pass
