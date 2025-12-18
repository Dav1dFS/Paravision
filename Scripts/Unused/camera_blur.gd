extends Camera3D

@onready var object_detector: RayCast3D = $ObjectDetector

@export var blur_far_max: int = 100
@export var blur_far_min: int = 2
@export var blur_range: int = -2

var lerp_speed: float = 10.0

func _ready():
	attributes.dof_blur_near_enabled = false

func _physics_process(delta: float) -> void:
	object_detector.target_position.z = blur_range
	
	if object_detector.is_colliding():	
		var origin = object_detector.global_transform.origin
		var collision_point = object_detector.get_collision_point()
		var distance = origin.distance_to(collision_point)
		
		attributes.dof_blur_far_distance = lerpf(
			attributes.dof_blur_far_distance, 
			blur_far_min * distance, 
			delta * lerp_speed
		)
	else:
		attributes.dof_blur_far_distance = lerpf(
			attributes.dof_blur_far_distance,
			blur_far_max, 
			delta * 2.0
		)
