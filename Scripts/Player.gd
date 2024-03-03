extends CharacterBody3D

const UTILS := preload("res://Scripts/utils.gd")
const SPEED := 6.0
const JUMP_VELOCITY := 4.5
const SENSITIVITY := 0.002
const JUST_UNDER_ONE := 1. - 10. ** -15.

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var can_move := false
var can_use_timeline := false
var timeline_stopped := true
var has_interacted := false
var progress := 0.

var timeline_tween: Tween

var timeline_identification_position := [
	Vector3(0, 0, 0),
	Vector3(0, 0, 0),
	Vector3(0.5, 1, -20),
	Vector3(2.345, 0.134, -34),
	Vector3(2.325, 1.5, -47.5),
	Vector3(2.3, 0.075, -46),
]
var timeline_identification_rotation := [
	Vector3(300, -350, 100),
	Vector3(300, -350, 100),
	Vector3(300, -350, 100),
	Vector3(55, -70, 0),
	Vector3(55, -70, 180),
	Vector3(25, -100, 220),
]

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var identification: Node3D = $"../Identification"
@onready var timeline: Node3D = $Head/Camera3D/Timeline
@onready var level: Node3D = $".."
@onready var viewport: SubViewport = $"../Control/SubViewportContainer/SubViewport"


func _ready() -> void:
	level.movable.connect(update_can_move)
	level.timeline_adjustable.connect(update_can_use_timeline)


func _unhandled_input(event: InputEvent) -> void:
	if can_move and event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x as float * SENSITIVITY)
		camera.rotate_x(-event.relative.y as float * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))


func _physics_process(delta: float) -> void:
	if can_move:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Handle Slow.
		var adjusted_speed: float = SPEED
		if Input.is_action_pressed("slow"):
			adjusted_speed = adjusted_speed * 0.25

		# Get the input direction and handle the movement/deceleration.
		var input_dir := Input.get_vector("left", "right", "forward", "backward")
		var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		if is_on_floor():
			if direction:
				velocity.x = direction.x * adjusted_speed
				velocity.z = direction.z * adjusted_speed
			else:
				velocity.x = lerp(velocity.x, direction.x * adjusted_speed, delta * 12.0)
				velocity.z = lerp(velocity.z, direction.z * adjusted_speed, delta * 12.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * adjusted_speed, delta * 2.0)
			velocity.z = lerp(velocity.z, direction.z * adjusted_speed, delta * 2.0)


func _process(delta: float) -> void:
	move_and_slide()  # Not ideal, should move out of _process eventually

	if can_use_timeline:
		var timeline_material: ShaderMaterial = timeline.get_child(0).material_override
		if Input.is_action_pressed("left") and Input.is_action_pressed("right"):
			timeline_rotation(0)
		elif Input.is_action_pressed("left"):
			timeline_rotation(-0.2)
			var new_progress := progress - 0.15 * delta
			progress = new_progress if new_progress >= 0 else 0.
			timeline_move(timeline_material)
		elif Input.is_action_pressed("right"):
			timeline_rotation(0.2)
			var new_progress := progress + 0.15 * delta
			progress = new_progress if new_progress <= JUST_UNDER_ONE else JUST_UNDER_ONE
			timeline_move(timeline_material)
		else:
			timeline_rotation(0)
		if (
			Input.is_action_just_pressed("interact")
			and viewport.identification_selectable
			and !has_interacted
		):
			handle_interact()


func timeline_rotation(rotation_y: float) -> void:
	timeline_tween = get_tree().create_tween()
	(
		timeline_tween
		. tween_property(timeline, "rotation", Vector3(0, rotation_y, 0), 0.75)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_SINE)
	)
	timeline_stopped = rotation_y == 0


func timeline_move(timeline_material: ShaderMaterial) -> void:
	timeline_material.set_shader_parameter("progress", progress)
	timeline_move_camera()
	timeline_move_identification()


func timeline_move_camera() -> void:
	camera.global_position = UTILS.piecewise_linear_interpolation(
		[Vector3(0.4, 0.5, -10), Vector3(0, 1.75, -42)], progress
	)
	camera.global_rotation_degrees = UTILS.piecewise_linear_interpolation(
		[Vector3(55, 11.6, 0), Vector3(-30, -50, 5), Vector3(0, 0, 0)], progress
	)


func timeline_move_identification() -> void:
	identification.global_position = (UTILS.piecewise_linear_interpolation(
		timeline_identification_position, progress
	))
	identification.global_rotation_degrees = (UTILS.piecewise_linear_interpolation(
		timeline_identification_rotation, progress
	))


func handle_interact() -> void:
	has_interacted = true
	can_use_timeline = false
	timeline_identification_position = [
		Vector3(0, 0, 0),
		Vector3(0, 0, 0),
		Vector3(0, 0.5, -20),
		Vector3(0, 0.5, -28),
		Vector3(-.2, 1.25, -34),
		Vector3(0, 1.5, -43.25),
	]
	timeline_identification_rotation = [
		Vector3(300, -350, 100),
		Vector3(300, -350, 100),
		Vector3(300, -350, 100),
		Vector3(55, -70, 50),
		Vector3(25, -25, 25),
		Vector3(0, -100, 0),
	]
	var tween := get_tree().create_tween().set_parallel()
	tween.tween_property(
		identification,
		"global_position",
		UTILS.piecewise_linear_interpolation(timeline_identification_position, progress),
		1
	)
	tween.tween_property(
		identification,
		"global_rotation_degrees",
		UTILS.piecewise_linear_interpolation(timeline_identification_rotation, progress),
		1
	)
	await get_tree().create_timer(1).timeout

	can_use_timeline = true
	level.interacted_with_identification = true


func update_can_move(movable: bool) -> void:
	can_move = movable


func update_can_use_timeline(timeline_adjustable: bool) -> void:
	can_use_timeline = timeline_adjustable
