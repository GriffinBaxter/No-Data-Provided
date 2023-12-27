@tool
extends MeshInstance3D

@onready var slicer = $"../Slicer"

func _process(_delta):
	material_override.set_shader_parameter("slice_plane", slicer.transform)
	material_override.set_shader_parameter("inversed", true)
