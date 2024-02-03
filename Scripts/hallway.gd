extends Node3D

var random = RandomNumberGenerator.new()

@onready var plane_end = $PlaneEnd
@onready var top_triangle = $PlaneTopTriangle
@onready var bottom_triangle = $PlaneBottomTriangle
@onready var left_triangle = $PlaneLeftTriangle
@onready var right_triangle = $PlaneRightTriangle
@onready var spot_light = $BackSpotLight
@onready var omni_light = $OmniLight3D

@onready var slice_middle = $"../TableWithInverseSlice/TableSlice/SliceMiddle"
@onready var top_light = $TopSpotLight3D
@onready var bottom_light = $BottomSpotLight3D
@onready var left_light = $LeftSpotLight3D
@onready var right_light = $RightSpotLight3D
@onready var top = $PlaneTop
@onready var bottom = $PlaneBottom
@onready var left = $PlaneLeft
@onready var right = $PlaneRight


func _ready():
	var materials = [
		plane_end.material_override,
		top_triangle.material_override,
		bottom_triangle.material_override,
		left_triangle.material_override,
		right_triangle.material_override,
	]

	while true:
		var tween1 = get_tree().create_tween().set_parallel()
		var fade_duration_1 = random.randf_range(0.01, 0.05)
		for material in materials:
			tween1.tween_property(material, "emission_energy_multiplier", 6, fade_duration_1)
		tween1.tween_property(spot_light, "light_energy", 8, fade_duration_1)
		tween1.tween_property(omni_light, "light_energy", 2, fade_duration_1)
		await get_tree().create_timer(random.randf_range(2, 10)).timeout

		var material_index_1 = random.randi_range(0, 4)
		var material_index_2 = null
		if random.randi_range(0, 1):
			material_index_2 = random.randi_range(0, 4)
		var tween2 = get_tree().create_tween().set_parallel()
		var fade_duration_2 = random.randf_range(0.01, 0.05)
		tween2.tween_property(
			materials[material_index_1], "emission_energy_multiplier", 0, fade_duration_2
		)
		if material_index_2:
			tween2.tween_property(
				materials[material_index_2], "emission_energy_multiplier", 0, fade_duration_2
			)
		if material_index_1 == 0 or material_index_2 == 0:
			tween2.tween_property(spot_light, "light_energy", 0, fade_duration_2)
		if material_index_1 in [1, 2, 3, 4] or material_index_2 in [1, 2, 3, 4]:
			tween2.tween_property(omni_light, "light_energy", 0, fade_duration_2)
		await get_tree().create_timer(random.randf_range(0.15, 0.3)).timeout

		tween2.stop()


func set_light(material, energy, emission = false):
	if emission:
		material.emission_energy_multiplier = energy
	else:
		material.light_energy = energy


func _process(_delta):
	set_energy_y(top_light, top)
	set_energy_y(bottom_light, bottom)
	set_energy_x(left_light, left)
	set_energy_x(right_light, right)

	for light in [top_light, bottom_light, left_light, right_light]:
		if light.light_energy <= 0:
			light.visible = false
		else:
			light.visible = true


func set_energy_y(light, plane):
	light.global_position.x = slice_middle.global_position.x
	light.global_position.z = slice_middle.global_position.z
	light.light_energy = (
		-abs(abs(slice_middle.global_position.y) - abs(plane.global_position.y)) + 1
	)


func set_energy_x(light, plane):
	light.global_position.y = slice_middle.global_position.y
	light.global_position.z = slice_middle.global_position.z
	light.light_energy = -abs(slice_middle.global_position.x - plane.global_position.x) + 1
