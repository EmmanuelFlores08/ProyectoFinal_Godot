extends CharacterBody3D
## Personaje jugable en tercera persona con jetpack.
## Instancia autónoma: solo arrástrala a una escena y funciona.
## Todo lo configurable está expuesto en el Inspector.

# --- Movimiento ---
@export_group("Movimiento")
@export var velocidad_caminar: float = 5.0
@export var velocidad_correr: float = 8.0
@export var fuerza_salto: float = 4.5
@export var gravedad: float = 18.0

# --- Cámara (tercera persona) ---
@export_group("Cámara")
@export var sensibilidad_mouse: float = 0.003
@export var distancia_camara: float = 4.0
@export var pitch_min: float = -60.0   # grados
@export var pitch_max: float = 60.0    # grados
@export var invertir_y: bool = false
@export var capturar_mouse: bool = true

# --- Jetpack ---
@export_group("Jetpack")
@export var combustible_max: float = 100.0
@export var empuje_jetpack: float = 20.0      # aceleración hacia arriba
@export var subida_maxima: float = 6.0        # velocidad vertical máxima con jetpack
@export var consumo_jetpack: float = 40.0     # combustible/segundo al usarlo
@export var recarga_jetpack: float = 30.0     # combustible/segundo tocando el suelo

# --- Gasolina (solo para mostrar el progreso en pantalla) ---
@export_group("Gasolina")
@export var objetivo_gasolinas: int = 3

# --- Nombres de animaciones (ajústalos si tu modelo usa otros) ---
@export_group("Animaciones")
@export var anim_idle: String = "Idle"
@export var anim_caminar: String = "Walk"
@export var anim_correr: String = "Run"
@export var anim_aire: String = "Fall"
@export var anim_jetpack: String = "Jet"

# --- Nivel / muerte ---
@export_group("Nivel")
## Escena del menú de selección de escenario (botón "Salir a selección").
@export_file("*.tscn") var escena_menu: String = "res://Scenes/elección_planeta.tscn"

@onready var pivote_camara: Node3D = $PivoteCamara
@onready var brazo_camara: SpringArm3D = $PivoteCamara/SpringArm3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var barra_combustible: ProgressBar = $CanvasLayer/BarraCombustible
@onready var etiqueta_gasolina: Label = $CanvasLayer/EtiquetaGasolina
@onready var canvas_muerte: CanvasLayer = $CanvasMuerte
@onready var boton_reintentar: Button = $CanvasMuerte/Contenido/BotonReintentar
@onready var boton_menu: Button = $CanvasMuerte/Contenido/BotonMenu

var combustible: float = 0.0
var gasolinas: int = 0
var muerto: bool = false


func _ready() -> void:
	combustible = combustible_max
	brazo_camara.spring_length = distancia_camara
	# Evita que el brazo de cámara choque contra el propio personaje.
	brazo_camara.add_excluded_object(get_rid())
	canvas_muerte.visible = false
	boton_reintentar.pressed.connect(_reintentar)
	boton_menu.pressed.connect(_salir_menu)
	if capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_actualizar_ui()


func _unhandled_input(event: InputEvent) -> void:
	if muerto:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		# Giro horizontal: rota el cuerpo. Giro vertical: inclina el pivote.
		rotate_y(-event.relative.x * sensibilidad_mouse)
		var delta_pitch: float = event.relative.y * sensibilidad_mouse
		if invertir_y:
			delta_pitch = -delta_pitch
		pivote_camara.rotation.x = clamp(
			pivote_camara.rotation.x - delta_pitch,
			deg_to_rad(pitch_min),
			deg_to_rad(pitch_max))
	# Esc libera el mouse; clic vuelve a capturarlo (útil al probar).
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	if muerto:
		velocity = Vector3.ZERO
		return
	var en_suelo: bool = is_on_floor()

	# Gravedad.
	if not en_suelo:
		velocity.y -= gravedad * delta

	# Salto y jetpack (misma tecla: "saltar").
	var usando_jetpack: bool = false
	if en_suelo:
		if Input.is_action_just_pressed("saltar"):
			velocity.y = fuerza_salto
		# El combustible se recarga al tocar el suelo.
		combustible = min(combustible + recarga_jetpack * delta, combustible_max)
	else:
		if Input.is_action_pressed("saltar") and combustible > 0.0:
			velocity.y = move_toward(velocity.y, subida_maxima, empuje_jetpack * delta)
			combustible = max(combustible - consumo_jetpack * delta, 0.0)
			usando_jetpack = true

	# Movimiento horizontal relativo a hacia dónde mira el personaje.
	var corriendo: bool = Input.is_action_pressed("correr")
	var velocidad: float = velocidad_correr if corriendo else velocidad_caminar
	var entrada: Vector2 = Input.get_vector("left", "right", "up", "down")
	var direccion: Vector3 = (transform.basis * Vector3(entrada.x, 0.0, entrada.y)).normalized()
	if direccion:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad)
		velocity.z = move_toward(velocity.z, 0.0, velocidad)

	move_and_slide()
	_actualizar_animacion(en_suelo, usando_jetpack, direccion != Vector3.ZERO, corriendo)
	_actualizar_ui()


func _actualizar_animacion(en_suelo: bool, jetpack: bool, moviendo: bool, corriendo: bool) -> void:
	var objetivo: String
	if not en_suelo:
		objetivo = anim_jetpack if jetpack else anim_aire
	elif moviendo:
		objetivo = anim_correr if corriendo else anim_caminar
	else:
		objetivo = anim_idle
	if anim.has_animation(objetivo) and anim.current_animation != objetivo:
		anim.play(objetivo)


func _actualizar_ui() -> void:
	barra_combustible.max_value = combustible_max
	barra_combustible.value = combustible
	etiqueta_gasolina.text = "Gasolina: %d/%d" % [gasolinas, objetivo_gasolinas]


# --- API pública para las otras instancias (sin dependencias fuertes) ---

## La llama la Gasolina al ser recogida.
func recolectar_gasolina(cantidad: int = 1) -> void:
	gasolinas += cantidad
	_actualizar_ui()


## La llama la Nave para comprobar si el nivel puede completarse.
func get_gasolinas() -> int:
	return gasolinas


## Sistema centralizado de muerte. Cualquier trampa la llama con
## body.morir(): detiene al personaje, bloquea los controles y muestra
## el Canvas de muerte. No hay que tocar este código al añadir trampas.
func morir() -> void:
	if muerto:
		return
	muerto = true
	velocity = Vector3.ZERO
	if anim.has_animation(anim_idle):
		anim.play(anim_idle)
	canvas_muerte.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true  # Congela el juego; el Canvas sigue activo.


func _reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _salir_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(escena_menu)
