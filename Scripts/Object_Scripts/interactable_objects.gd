extends Area3D

@onready var interact_label: Label3D = $Label3D

func pickup_camcorder():
	queue_free()
	Gamestate.has_camera = true
	
func interact():
	print("Picked up item")
	queue_free()

func show_label():
	interact_label.visible = true

func hide_label():
	interact_label.visible = false
