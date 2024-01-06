extends Node3D

@onready var plane_end = $PlaneEnd
@onready var spot_light = $BackSpotLight
@onready var omni_light = $OmniLight3D

var black_with_white_emission_material = null
var random = RandomNumberGenerator.new()

func _ready():
	black_with_white_emission_material = plane_end.material_override

	while (true):
		black_with_white_emission_material.emission_energy_multiplier = 6
		spot_light.light_energy = 8
		omni_light.light_energy = 2
		await get_tree().create_timer(random.randf_range(2, 10)).timeout

		black_with_white_emission_material.emission_energy_multiplier = 0
		spot_light.light_energy = 0
		omni_light.light_energy = 0
		await get_tree().create_timer(random.randf_range(0.15, 0.3)).timeout
