extends Node

var invis_toggle:bool

@export var area_obj:Area3D

#the objects material
@export var invis_mat:StandardMaterial3D

@export var respawn_point:CSGBox3D

@export var player:CharacterBody3D

@export var light:OmniLight3D

var respawn_coords:Vector3

var og_color:Color

#the colision object itself
#@export var colision_shape:CollisionShape3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	invis_toggle = true
	
	light.visible = false
	
	#save original color
	og_color = invis_mat.albedo_color
	
	respawn_coords = respawn_point.transform.origin
	
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Invis_Toggle") and Gamestate.is_using_camera:
		invis_toggle = !invis_toggle
		
		#makes object invisible and deactivates colisions
		if invis_toggle == true:
			print("invis_toggle ON")
			invis_mat.albedo_color = og_color
			light.visible = false
			#colision_shape.set_deferred("disabled", true)
			
		#makes object visible again and activates colisions
		if invis_toggle == false:
			print("invis_toggle OFF")
			invis_mat.albedo_color = "ff00ff"
			light.visible = true
			#colision_shape.set_deferred("disabled", false)
	pass


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
			print("you died!")
			player.transform.origin = respawn_coords + Vector3.UP * 1.0
