extends VehicleBody3D

# константы
const BRAKE_STRENGTH = 600.0
const STEER_SPEED = 1.0
const BRAKE_SPEED = 300
const STEER_LIMIT = 0.45
const MAX_RPM = 4500
# переменные
var gear = 0 #передача
var gears_ratio = [-0.2, 0, 0.5, 0.8, 1, 1.5]
####
var rpm = 0 # обороты
var test = 0.0
var current_brake = 0.0
var _steer_target = 0.0
var curret_steer = 0.0
var _engine_force = 0 # сила двигателя (зависит от оборотов и передачи)
var ignition = false #зажигание
var _engine_value = 3.5 # относительное число, чтобы можно было сделать 1 машину, быстрее другой 
var player = null # игрок
var in_car = false # "в машине"
@onready var streeting_wheel = $Whl
@onready var gearsmesh =$GearLie
@onready var enterMarker = $"Enter Marker"
@onready var exitMarker = $"Exit Marker"
func _physics_process(delta: float) -> void:
	
	if not (player and in_car): return # если нет игрока и не в машине, не выполняем дальше
	if in_car:
		player.global_position = enterMarker.global_position
	# ТОРМОЗ (Я)
	if Input.is_action_pressed("ui_down"): current_brake += BRAKE_SPEED * delta
	else: current_brake -= BRAKE_SPEED * 2 * delta
	current_brake = clamp(current_brake, 0.0, BRAKE_STRENGTH)
	brake = current_brake
	
	#ПОВОРОТЫ
	_steer_target = Input.get_axis("ui_left", "ui_right") * -STEER_LIMIT
	steering = move_toward(steering, _steer_target, STEER_SPEED * delta)
	#МЕШИ
	streeting_wheel.rotation_degrees.x = -rad_to_deg(steering) * 20.0
	gearsmesh.rotation_degrees.z = lerp(gearsmesh.rotation_degrees.z,gears_ratio[gear+1] * 20.0, 10 * delta )
	
	
	if Input.is_action_just_pressed("ignition"): ignition = not ignition # если в машине и нажат ignition: заводим
	if Input.is_action_just_pressed("exit_car"): exit_car(player) # выходим из авто
	if not ignition: return # если не заведено, не выполняем дальше.
	
	# ОБОРОТЫ
	if Input.is_action_pressed("ui_up") and rpm<=MAX_RPM:
		rpm += 800.0 * delta
	else:
		rpm -= 500.0 * delta
	# чтобы не падал rpm < 0, то ограничиваем его при помощи clamp
	
	#gprint("RPM: " + str(rpm))
	
	#ПЕРЕДАЧИ
	var old_gear = gear # создаем переменную с gear до переключения 
	if Input.is_action_just_pressed("gear_up"): if gear < gears_ratio.size()-2: gear += 1 # -2 так как не считаем заднюю и нейтраль
	if Input.is_action_just_pressed("gear_down"): if gear > -1: gear -= 1
	#print("GEAR: " + str(gear))
	if gear != old_gear:
		var old_ratio = gears_ratio[old_gear + 1]
		var new_ratio = gears_ratio[gear + 1]
		print("OLD" + str(old_ratio))
		print("NEW" + str(new_ratio))
		if old_ratio > 0 and new_ratio > 0:
			rpm = rpm * (old_ratio / new_ratio)
	rpm = clamp(rpm, 0.0, MAX_RPM)
	# РАСЧЕТ МОЩНОСТИ
	_engine_force = gears_ratio[gear + 1] * (rpm/_engine_value)
	engine_force = _engine_force
	
	#ОСТАЛЬНОЕ
	var speed_kmh = linear_velocity.length() * 3.6
	$Label3D.text = """
ignition: %s
gear: %d
rpm: %.0f
speed: %.1f km/h
engine_force: %.1f
current brake: %.0f
""" % [ignition, gear, rpm,speed_kmh, engine_force, current_brake]

	
func exit_car(body):
	in_car = false
	body.collision_layer = 1
	if body.has_method("input_toggle"): body.input_toggle() # включаем движение игрока
	body.global_position = exitMarker.global_position
func enter_car(body: CharacterBody3D):
	in_car = true
	body.collision_layer = 0
	if body.has_method("input_toggle"): body.input_toggle()# выключаем движение игрока
	player = body
