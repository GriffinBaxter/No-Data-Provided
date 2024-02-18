extends Node3D

var random: RandomNumberGenerator = RandomNumberGenerator.new()

@onready var plane_end: MeshInstance3D = $PlaneEnd
@onready var top_triangle: MeshInstance3D = $PlaneTopTriangle
@onready var bottom_triangle: MeshInstance3D = $PlaneBottomTriangle
@onready var left_triangle: MeshInstance3D = $PlaneLeftTriangle
@onready var right_triangle: MeshInstance3D = $PlaneRightTriangle
@onready var spot_light: SpotLight3D = $BackSpotLight
@onready var omni_light: OmniLight3D = $OmniLight3D

@onready var slice_middle: Node3D = $"../TableWithInverseSlice/TableSlice/SliceMiddle"
@onready var top_light: SpotLight3D = $TopSpotLight3D
@onready var bottom_light: SpotLight3D = $BottomSpotLight3D
@onready var left_light: SpotLight3D = $LeftSpotLight3D
@onready var right_light: SpotLight3D = $RightSpotLight3D
@onready var top: MeshInstance3D = $PlaneTop
@onready var bottom: MeshInstance3D = $PlaneBottom
@onready var left: MeshInstance3D = $PlaneLeft
@onready var right: MeshInstance3D = $PlaneRight


func _ready() -> void:
	var materials: Array[Material] = [
		plane_end.material_override,
		top_triangle.material_override,
		bottom_triangle.material_override,
		left_triangle.material_override,
		right_triangle.material_override,
	]

	while true:
		var tween_1: Tween = get_tree().create_tween().set_parallel()
		var fade_duration_1: float = random.randf_range(0.01, 0.05)
		for material in materials:
			tween_1.tween_property(material, "emission_energy_multiplier", 6, fade_duration_1)
		tween_1.tween_property(spot_light, "light_energy", 8, fade_duration_1)
		tween_1.tween_property(omni_light, "light_energy", 2, fade_duration_1)
		await get_tree().create_timer(random.randf_range(2, 10)).timeout

		tween_1.stop()
		var material_index_1: int = random.randi_range(0, 4)
		var material_index_2: int = -1
		if random.randi_range(0, 1):
			material_index_2 = random.randi_range(0, 4)
		var tween_2: Tween = get_tree().create_tween().set_parallel()
		var fade_duration_2: float = random.randf_range(0.01, 0.05)
		tween_2.tween_property(
			materials[material_index_1], "emission_energy_multiplier", 0, fade_duration_2
		)
		if material_index_2 != -1:
			tween_2.tween_property(
				materials[material_index_2], "emission_energy_multiplier", 0, fade_duration_2
			)
		if material_index_1 == 0 or material_index_2 == 0:
			tween_2.tween_property(spot_light, "light_energy", 0, fade_duration_2)
		if material_index_1 in [1, 2, 3, 4] or material_index_2 in [1, 2, 3, 4]:
			tween_2.tween_property(omni_light, "light_energy", 0, fade_duration_2)
		await get_tree().create_timer(random.randf_range(0.15, 0.3)).timeout

		tween_2.stop()


func _process(_delta: float) -> void:
	set_energy_y(top_light, top)
	set_energy_y(bottom_light, bottom)
	set_energy_x(left_light, left)
	set_energy_x(right_light, right)

	for light: SpotLight3D in [top_light, bottom_light, left_light, right_light]:
		if light.light_energy <= 0:
			light.visible = false
		else:
			light.visible = true


func set_energy_y(light: SpotLight3D, plane: MeshInstance3D) -> void:
	light.global_position.x = slice_middle.global_position.x
	light.global_position.z = slice_middle.global_position.z
	light.light_energy = (
		-abs(abs(slice_middle.global_position.y) - abs(plane.global_position.y)) + 1
	)


func set_energy_x(light: SpotLight3D, plane: MeshInstance3D) -> void:
	light.global_position.y = slice_middle.global_position.y
	light.global_position.z = slice_middle.global_position.z
	light.light_energy = -abs(slice_middle.global_position.x - plane.global_position.x) + 1
