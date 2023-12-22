extends CharacterBody3D


const SPEED = 6.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = 0.002

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var can_move = false

@onready var head = $Head
@onready var camera = $Head/Camera3D

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
		var adjusted_speed = SPEED;
		if Input.is_action_pressed("slow"):
			adjusted_speed = adjusted_speed * 0.25;

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

func _process(_delta):
	move_and_slide()  # Not ideal, should move out of _process eventually

func _on_smm_animation_player_animation_finished(anim_name):
	if anim_name == "hallway_intro":
		can_move = true
