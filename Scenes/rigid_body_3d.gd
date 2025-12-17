extends RigidBody3D
@export var is_clone: bool = false

func _ready():
	if not is_clone:
		add_to_group("cubo_original")
	else:
		add_to_group("clones")

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
