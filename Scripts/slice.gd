@tool
extends MeshInstance3D

@export var inversed := false

@onready var slicer: MeshInstance3D = $"../Slicer"


func _process(_delta: float) -> void:
	material_override.set_shader_parameter("slice_plane", slicer.transform)
	material_override.set_shader_parameter("inversed", inversed)
	material_override.next_pass.set_shader_parameter("slice_plane", slicer.transform)
	material_override.next_pass.set_shader_parameter("inversed", inversed)
