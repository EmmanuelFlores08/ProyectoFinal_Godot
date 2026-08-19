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
@export var empuje_jetpack: float = 20.0     
@export var subida_maxima: float = 6.0       
@export var consumo_jetpack: float = 40.0    
@export var recarga_jetpack: float = 30.0    

# --- Gasolina---
@export_group("Gasolina")
@export var objetivo_gasolinas: int = 3
## Imagen que aparece en el HUD al recoger cada gasolina (reemplázala por un
## icono de gasolina desde el Inspector).
@export var icono_gasolina: Texture2D = preload("res://icon.svg")

# --- Nombres de animaciones---
@export_group("Animaciones")
@export var anim_idle: String = "Idle"
@export var anim_caminar: String = "Walk"
@export var anim_correr: String = "Run"
@export var anim_aire: String = "Fall"
@export var anim_jetpack: String = "Jet"

# --- Nivel / muerte ---
@export_group("Nivel")
## Escena del menú de selección de escenario (botón "Salir").
@export_file("*.tscn") var escena_menu: String = "res://Scenes/elección_planeta.tscn"

# --- Sonidos del personaje (editables/reemplazables desde el Inspector) ---
@export_group("Sonidos")
@export var sfx_caminar: AudioStream = preload("res://Sounds/SFX/AlienWalk.mp3")
@export var sfx_correr: AudioStream = preload("res://Sounds/SFX/AlienRun.mp3")
@export var sfx_jetpack: AudioStream = preload("res://Sounds/SFX/Jetpack.mp3")
@export var sfx_saltar: AudioStream = preload("res://Sounds/SFX/AlienJump.mp3")
@export var sfx_gasolina: AudioStream = preload("res://Sounds/SFX/AlienSound.mp3")
@export var sfx_muerte: AudioStream = preload("res://Sounds/SFX/Damage.mp3")

@onready var pivote_camara: Node3D = $PivoteCamara
@onready var brazo_camara: SpringArm3D = $PivoteCamara/SpringArm3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var barra_combustible: ProgressBar = $CanvasLayer/BarraCombustible
@onready var etiqueta_gasolina: Label = $CanvasLayer/EtiquetaGasolina
@onready var canvas_muerte: CanvasLayer = $CanvasMuerte
@onready var etiqueta_tiempo_muerte: Label = $CanvasMuerte/EtiquetaTiempo
@onready var boton_reintentar: BaseButton = $CanvasMuerte/BotonReintentar
@onready var boton_menu: BaseButton = $CanvasMuerte/BotonSalir
@onready var sonido_mov: AudioStreamPlayer = $SonidoMovimiento
@onready var sonido_accion: AudioStreamPlayer = $SonidoAccion
@onready var iconos_gasolina: Array = [
	$CanvasLayer/IconosGasolina/Icono1,
	$CanvasLayer/IconosGasolina/Icono2,
	$CanvasLayer/IconosGasolina/Icono3,
]

var combustible: float = 0.0
var gasolinas: int = 0
var muerto: bool = false
var tiempo_inicio_ms: int = 0
var _loop_actual: AudioStream = null  


func _ready() -> void:
	combustible = combustible_max
	tiempo_inicio_ms = Time.get_ticks_msec()
	brazo_camara.spring_length = distancia_camara

	brazo_camara.add_excluded_object(get_rid())
	canvas_muerte.visible = false
	boton_reintentar.pressed.connect(_reintentar)
	boton_menu.pressed.connect(_salir_menu)

	for ic in iconos_gasolina:
		ic.texture = icono_gasolina
		ic.modulate = Color(1, 1, 1, 0.25)
	
	for s in [sfx_caminar, sfx_correr, sfx_jetpack]:
		if s is AudioStreamMP3:
			s.loop = true
	if capturar_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_actualizar_ui()


func _unhandled_input(event: InputEvent) -> void:
	if muerto:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		
		rotate_y(-event.relative.x * sensibilidad_mouse)
		var delta_pitch: float = event.relative.y * sensibilidad_mouse
		if invertir_y:
			delta_pitch = -delta_pitch
		pivote_camara.rotation.x = clamp(
			pivote_camara.rotation.x - delta_pitch,
			deg_to_rad(pitch_min),
			deg_to_rad(pitch_max))

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

	
	var usando_jetpack: bool = false
	if en_suelo:
		if Input.is_action_just_pressed("saltar"):
			velocity.y = fuerza_salto
			_reproducir_accion(sfx_saltar)
		# El combustible se recarga al tocar el suelo.
		combustible = min(combustible + recarga_jetpack * delta, combustible_max)
	else:
		if Input.is_action_pressed("saltar") and combustible > 0.0:
			velocity.y = move_toward(velocity.y, subida_maxima, empuje_jetpack * delta)
			combustible = max(combustible - consumo_jetpack * delta, 0.0)
			usando_jetpack = true

	
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
	_actualizar_sonido(en_suelo, usando_jetpack, direccion != Vector3.ZERO, corriendo)
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



func _actualizar_sonido(en_suelo: bool, jetpack: bool, moviendo: bool, corriendo: bool) -> void:
	var objetivo: AudioStream = null
	if not en_suelo:
		if jetpack:
			objetivo = sfx_jetpack
	elif moviendo:
		objetivo = sfx_correr if corriendo else sfx_caminar
	if objetivo == _loop_actual:
		return
	_loop_actual = objetivo
	if objetivo:
		sonido_mov.stream = objetivo
		sonido_mov.play()
	else:
		sonido_mov.stop()



func _reproducir_accion(stream: AudioStream) -> void:
	if stream:
		sonido_accion.stream = stream
		sonido_accion.play()


func _actualizar_ui() -> void:
	barra_combustible.max_value = combustible_max
	barra_combustible.value = combustible
	etiqueta_gasolina.text = "Gasolina: %d/%d" % [gasolinas, objetivo_gasolinas]


func recolectar_gasolina(cantidad: int = 1) -> void:
	gasolinas += cantidad
	_reproducir_accion(sfx_gasolina)
	_encender_iconos()
	_actualizar_ui()



func _encender_iconos() -> void:
	for i in iconos_gasolina.size():
		var ic: TextureRect = iconos_gasolina[i]
		if i < gasolinas:
			if ic.modulate.a < 1.0:  # recién recogido: animación de aparición
				ic.modulate = Color(1, 1, 1, 1)
				ic.pivot_offset = ic.size / 2.0
				ic.scale = Vector2(1.6, 1.6)
				create_tween().tween_property(ic, "scale", Vector2.ONE, 0.25) \
					.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			ic.modulate = Color(1, 1, 1, 0.25)


func _formato_tiempo(ms: int) -> String:
	var segundos: float = ms / 1000.0
	return "Tiempo: %02d:%05.2f" % [int(segundos) / 60, fmod(segundos, 60.0)]


## La llama la Nave para comprobar si el nivel puede completarse.
func get_gasolinas() -> int:
	return gasolinas


func morir() -> void:
	if muerto:
		return
	muerto = true
	velocity = Vector3.ZERO
	if anim.has_animation(anim_idle):
		anim.play(anim_idle)
	sonido_mov.stop()
	_reproducir_accion(sfx_muerte)

	get_tree().call_group("musica_escenario", "derrota")
	etiqueta_tiempo_muerte.text = _formato_tiempo(Time.get_ticks_msec() - tiempo_inicio_ms)
	canvas_muerte.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true  


func _reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _salir_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(escena_menu)
