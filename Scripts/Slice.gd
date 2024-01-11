@tool
extends MeshInstance3D

@export var inversed = false

@onready var slicer = $"../Slicer"


func _process(_delta):
	material_override.set_shader_parameter("slice_plane", slicer.transform)
	material_override.set_shader_parameter("inversed", inversed)
	if material_override.next_pass:
		material_override.next_pass.set_shader_parameter("slice_plane", slicer.transform)
		material_override.next_pass.set_shader_parameter("inversed", inversed)
