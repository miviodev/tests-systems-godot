extends CharacterBody3D

const SPEED = 5.0
const RUN_SPEED = 8.0
const JUMP_VELOCITY = 4.5

var grabbed_collider = null
var grabbing = false
var disabled = false
var sitting = false
@onready var rotation_helper = $CameraHelper
@export var MOUSE_SENSITIVITY: float = 0.7
@onready var raycast = $CameraHelper/Camera/RayCast3D
@onready var label = $Control/StatusLabel
@export var character_texture: Texture2D
@onready var old_texture = $Control/Container/Sprite2D.texture
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if Input.is_action_just_released("exit"):
		get_tree().quit()

	if disabled: return
	if not is_on_floor():
		velocity += get_gravity() * delta


	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		var current_speed = RUN_SPEED if Input.is_action_pressed("run") else SPEED
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		# Smooth stop
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 8)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * 8)

	move_and_slide()

	if $Control/Container/Sprite2D.texture == character_texture: $Control/Container/Sprite2D.texture = old_texture
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		print(collider.name)
		if collider.is_in_group("draggable"):
			label.text = "grub (E)"
			if Input.is_action_just_pressed("grab"):
				grabbed_collider = collider
				grab(collider)
		if collider.is_in_group("car"):
			label.text = "Sit (F)"
			$Control/Container/Sprite2D.texture = character_texture
			if Input.is_action_just_pressed("sit"): collider.get_parent().enter_car(self)
	else:
		label.text = "..."
	if Input.is_action_just_released("grab") and grabbed_collider:
			ungrab(grabbed_collider)
	

	# Бросок по нажатию, даже если "grab" всё ещё зажата
	if grabbed_collider and Input.is_action_just_pressed("throw_dragged") and grabbing:
		throw(grabbed_collider)

	if grabbed_collider and grabbing:
		update_grab_pos()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
		
		var pitch = rotation_helper.rotation.x + deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY)
		pitch = clamp(pitch, deg_to_rad(-70), deg_to_rad(70))
		rotation_helper.rotation.x = pitch

func grab(collider: RigidBody3D):
	collider.gravity_scale = 0.0
	grabbing = true


func update_grab_pos():
	if not grabbed_collider or not grabbing:
		return

	var camera = $CameraHelper/Camera
	var target_pos = camera.global_transform.origin - camera.global_transform.basis.z * 2.0


	var current_pos = grabbed_collider.global_transform.origin

	# Пружинная сила
	var error = target_pos - current_pos
	var spring_strength = 25.0
	var damping = 5.5
	var force = error * spring_strength - grabbed_collider.linear_velocity * damping

	grabbed_collider.apply_central_force(force)
func ungrab(collider: RigidBody3D):
	grabbing = false
	collider.gravity_scale = 1.0
	grabbed_collider = null

func throw(collider: RigidBody3D):
	var direction_from_player = (collider.global_transform.origin - global_transform.origin).normalized()
	collider.apply_impulse(direction_from_player * 6.0)
	ungrab(collider)
func input_toggle():
	disabled = not disabled
func sit(): return sitting
