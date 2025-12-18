extends Control

signal anchor_selected(anchor_name: String)

func _ready():
	visible = false

func open():
	visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close():
	visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_up_pressed():
	print("cliqueiup")
	anchor_selected.emit("up")
	close()

func _on_down_pressed():
	anchor_selected.emit("down")
	close()

func _on_north_pressed():
	anchor_selected.emit("north")
	close()

func _on_south_pressed():
	anchor_selected.emit("south")
	close()

func _on_east_pressed():
	anchor_selected.emit("east")
	close()

func _on_west_pressed():
	anchor_selected.emit("west")
	close()
