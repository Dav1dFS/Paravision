extends Node

var invis_toggle:bool

#the objects material
@export var visible_mat:StandardMaterial3D

var og_color:Color

#the object itself
@export var colision_shape:CollisionShape3D

func _ready() -> void:
	invis_toggle = true
	#saves original color
	og_color = visible_mat.albedo_color

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Invis_Toggle") and Gamestate.is_using_camera:
		invis_toggle = !invis_toggle
		#makes object visible again and activates colisions
		if invis_toggle == true:
			visible_mat.albedo_color = og_color
			colision_shape.set_deferred("disabled", false)
			
		#makes object invisible and deactivates colisions
		if invis_toggle == false:
			visible_mat.albedo_color = "00000000"
			colision_shape.set_deferred("disabled", true)
