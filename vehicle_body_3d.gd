extends VehicleBody3D

const STEER_SPEED = 2.0
var _steer_target = 0.0
var curret_steer = 0.0
const STEER_LIMIT = 0.45
const BRAKE_STRENGTH = 2.0
const BRAKE_SPEED = 1.0
var curret_brake = 0.0
@export var engine_force_value := 40.0 #относительная величина, чтобы определять мощность авто
var previous_speed := linear_velocity.length()
var engineforce = 0
var rpm = 0
var gear = 0
var gear_ratio = [-0.4, 0.0, 0.5, 0.8, 1.0, 1.2] #мощность будет увеличиватся при большей передачи, так же при больших оборотах
var max_rpm = 4500
var ignation = false
var player = null
var in_car = false
@onready var gearsmesh =$GearLie
var gear_degrees_rotate = [-0.5, 0.0, 0.5, 1.0, 1.5, 2.0]
@onready var streeting_wheel = $Whl

func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if player and is_instance_valid(player) and in_car:
		player.global_position = $"Start Marker".global_position
	
	if Input.is_action_just_pressed("ignition") and in_car:
		ignation = not ignation
	if Input.is_action_pressed("exit_car"):
		exitcar()
		
	if not (in_car and ignation):return
		
	_steer_target = Input.get_axis("ui_right","ui_left" )
	curret_steer = lerp(curret_steer, _steer_target, STEER_SPEED * delta)
	print(curret_steer)
	streeting_wheel.rotation.x = deg_to_rad(curret_steer * -900.0)
	steering = clamp(curret_steer, -1, 1)
	
	gearsmesh.rotation_degrees.z = lerp(gearsmesh.rotation_degrees.z,gear_degrees_rotate[gear+1] * 20.0, 10 * delta )
	
	var old_gear = gear
	if Input.is_action_just_pressed("gear_up"):
		if gear < gear_ratio.size()-2:
			if gear == -1:
				rpm = rpm + 800
			gear += 1
			
	if Input.is_action_just_pressed("gear_down"):
		if gear >= 0:
			gear -=1
			if gear == -1:
				rpm = rpm - 800
				if linear_velocity.length() > 2.0:
					gear = 0
	if gear != old_gear:
		var old_ratio = gear_ratio[old_gear + 1]
		var new_ratio = gear_ratio[gear + 1]
		if old_ratio > 0 and new_ratio > 0:
			rpm = rpm * (old_ratio / new_ratio)
		rpm = clamp(rpm, 0, max_rpm)
	if Input.is_action_pressed("ui_up") and rpm<=max_rpm:
		rpm += 500.0*delta
	else:
		if rpm > 0:
			rpm -= 200.0*delta 
		elif rpm <=0:
			rpm = 0
	if Input.is_action_pressed("ui_down"):
		curret_brake = lerp(curret_brake, BRAKE_STRENGTH, BRAKE_SPEED * delta)
	else:
		if curret_brake >= 0:
			curret_brake = max(lerp(curret_brake, -BRAKE_STRENGTH, BRAKE_SPEED * delta), 0.0)
	
	engineforce = gear_ratio[gear +1] * (rpm/engine_force_value)
	print("RPM" + str(round(rpm)) + ". GEAR" + str(gear) + ". FORCE" +str(engineforce) + ". CURRENT BRAKE" + str(curret_brake),". SPEED " + str(linear_velocity.length() *3.6))
	engine_force = engineforce
	brake = curret_brake * 4
	
	

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not in_car:
		player = body
		body.global_transform = $"Start Marker".global_transform
		in_car = true
		body.collision_layer = 0
		body.input_toggle()
func exitcar():
	if player and is_instance_valid(player) and in_car:
		player.global_position = $"Exit Marker".global_position
		player.rotation = Vector3.ZERO
		in_car = false
		player.collision_layer = 1
		
		player = null
		

	
