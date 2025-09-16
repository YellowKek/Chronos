extends CharacterBody3D

# Как быстро игрок движется в метрах в секунду.
@export var speed = 14
# Ускорение вниз, когда в воздухе, в метрах в секунду в квадрате.
@export var fall_acceleration = 75
@export var jump_impulse = 20

# Анимация
@onready var animation_player = $AnimationPlayer

@onready var _camera = $CameraPivot/SpringArm3D/Camera3D as Camera3D  # Полный путь к камере
@onready var _camera_pivot := $CameraPivot as Node3D

var target_velocity = Vector3.ZERO
var is_moving = false

@export_range(0.0, 1.0) var mouse_sensitivity = 0.01
@export var tilt_limit = deg_to_rad(75)
@export var camera_offset = Vector3(0, 1.5, -3)  # Смещение камеры относительно игрока

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_camera_pivot.rotation.x -= event.relative.y * mouse_sensitivity
		# Предотвращаем вращение камеры слишком далеко вверх или вниз.
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -tilt_limit, tilt_limit)
		_camera_pivot.rotation.y += -event.relative.x * mouse_sensitivity

func _physics_process(delta):
	var direction = Vector3.ZERO

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z -= 1
	if Input.is_action_pressed("move_forward"):
		direction.z += 1

	# Проверка, движется ли игрок
	is_moving = direction.length() > 0

	# Воспроизведение соответствующей анимации
	handle_animations()

	if direction != Vector3.ZERO:
		direction = direction.normalized()
		# Установка свойства basis повлияет на вращение узла.
		$Pivot.basis = Basis.looking_at(direction)

	# Горизонтальная скорость
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Вертикальная скорость
	if not is_on_floor():  # Если в воздухе, падаем к полу. Буквально гравитация
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	if is_on_floor() and Input.is_action_just_pressed("jump"):
		target_velocity.y = jump_impulse

	# Движение персонажа
	velocity = target_velocity
	move_and_slide()

	# Обновление позиции камеры
	_camera.position = global_transform.origin + camera_offset.rotated(Vector3.UP, rotation.y)

func handle_animations():
	if is_moving and is_on_floor():
		if animation_player.has_animation("walk"):
			animation_player.play("walk")
