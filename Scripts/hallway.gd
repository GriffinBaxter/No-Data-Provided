extends Node3D

@onready var plane_end = $PlaneEnd
@onready var top_triangle = $PlaneTopTriangle
@onready var bottom_triangle = $PlaneBottomTriangle
@onready var left_triangle = $PlaneLeftTriangle
@onready var right_triangle = $PlaneRightTriangle
@onready var spot_light = $BackSpotLight
@onready var omni_light = $OmniLight3D

var random = RandomNumberGenerator.new()

func _ready():
	var materials = [
		plane_end.material_override,
		top_triangle.material_override,
		bottom_triangle.material_override,
		left_triangle.material_override,
		right_triangle.material_override,
	]

	while (true):
		for material in materials:
			material.emission_energy_multiplier = 6
		spot_light.light_energy = 8
		omni_light.light_energy = 2
		await get_tree().create_timer(random.randf_range(2, 10)).timeout

		var material_index_1 = random.randi_range(0, 4)
		var material_index_2 = null
		if random.randi_range(0, 1):
			material_index_2 = random.randi_range(0, 4)
		materials[material_index_1].emission_energy_multiplier = 0
		if material_index_2:
			materials[material_index_2].emission_energy_multiplier = 0
		if material_index_1 == 0 or material_index_2 == 0:
			spot_light.light_energy = 0
		if material_index_1 in [1, 2, 3, 4] or material_index_2 in [1, 2, 3, 4]:
			omni_light.light_energy = 0

		await get_tree().create_timer(random.randf_range(0.15, 0.3)).timeout
