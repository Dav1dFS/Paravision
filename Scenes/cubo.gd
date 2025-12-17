extends RigidBody3D

@export var is_clone: bool = false

func _ready():
	if is_clone:
		# Clones têm física normal
		freeze = false
		gravity_scale = 1.0
		add_to_group("clones")
	else:
		# Original fica parado no ar
		freeze = true
		gravity_scale = 0.0
		add_to_group("cubo_original")


# Função para verificar se pode ser clonado
func can_be_cloned() -> bool:
	return not is_clone

# Opcional: função para mostrar/esconder label de interação
func show_label():
	# Se tiver um label de UI, mostrar aqui
	pass

func hide_label():
	# Se tiver um label de UI, esconder aqui
	pass
	
func get_spawn_height() -> float:
	return global_position.y
