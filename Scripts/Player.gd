extends CharacterBody3D

const SPEED = 6.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var can_move = false
var can_use_timeline = false

var timeline_tween

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var timeline = $Head/Camera3D/Timeline
@onready var level = $".."


func _unhandled_input(event):
	if can_move and event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(60))


func _physics_process(delta):
	if can_move:
		# Add the gravity.
		if not is_on_floor():
			velocity.y -= gravity * delta

		# Handle Jump.
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY

		# Handle Slow.
		var adjusted_speed = SPEED
		if Input.is_action_pressed("slow"):
			adjusted_speed = adjusted_speed * 0.25

		# Get the input direction and handle the movement/deceleration.
		var input_dir = Input.get_vector("left", "right", "forward", "backward")
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
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


func _process(delta):
	move_and_slide()  # Not ideal, should move out of _process eventually

	if can_use_timeline:
		var timeline_material = timeline.get_child(0).material_override
		var current_progress = timeline_material.get_shader_parameter("progress")
		if Input.is_action_pressed("left") and Input.is_action_pressed("right"):
			timeline_rotation(0)
		elif Input.is_action_pressed("left"):
			timeline_rotation(-0.2)
			if current_progress > 0:
				var updated_progress = current_progress - 0.15 * delta
				timeline_material.set_shader_parameter("progress", updated_progress)
				timeline_move_camera(updated_progress)
		elif Input.is_action_pressed("right"):
			timeline_rotation(0.2)
			if current_progress < 1:
				var updated_progress = current_progress + 0.15 * delta
				timeline_material.set_shader_parameter("progress", updated_progress)
				timeline_move_camera(updated_progress)
		else:
			timeline_rotation(0)


func timeline_rotation(rotation_y):
	timeline_tween = get_tree().create_tween()
	(
		timeline_tween
		. tween_property(timeline, "rotation", Vector3(0, rotation_y, 0), 0.75)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_SINE)
	)


func timeline_move_camera(progress):
	const TIMELINE_FINAL_POS = Vector3(0, 1.75, -42)
	const TIMELINE_FINAL_ROT = Vector3(0, 0, 0)
	const TIMELINE_MID_ROT = Vector3(-30, -50, 5)
	const TIMELINE_INITIAL_POS = Vector3(0.4, 0.5, -10)
	const TIMELINE_INITIAL_ROT = Vector3(55, 11.6, 0)
	camera.global_position = progress * TIMELINE_FINAL_POS + (1 - progress) * TIMELINE_INITIAL_POS
	camera.global_rotation_degrees = (
		(progress * 2 * TIMELINE_MID_ROT + (1 - progress * 2) * TIMELINE_INITIAL_ROT)
		if progress <= 0.5
		else (
			(progress - 0.5) * 2 * TIMELINE_FINAL_ROT
			+ (1 - (progress - 0.5) * 2) * TIMELINE_MID_ROT
		)
	)


func _ready():
	level.movable.connect(update_can_move)
	level.timeline_adjustable.connect(update_can_use_timeline)


func update_can_move(movable):
	can_move = movable


func update_can_use_timeline(timeline_adjustable):
	can_use_timeline = timeline_adjustable
