extends Area3D
## Meta del nivel. Al entrar el jugador, comprueba si tiene las gasolinas
## necesarias; si es así muestra la pantalla de victoria con el tiempo total.
## Instancia autónoma: arrástrala a la escena.

## Gasolinas que el jugador debe haber recogido para completar el nivel.
@export var gasolinas_necesarias: int = 3
## Escena del menú de selección de escenario (botón "Volver al menú").
@export_file("*.tscn") var escena_menu: String = "res://Scenes/elección_planeta.tscn"

@export_group("Animación")
@export var girar: bool = true
@export var velocidad_giro: float = 30.0   # grados por segundo
@export var flotar: bool = true
@export var altura_flote: float = 0.2      # metros
@export var velocidad_flote: float = 1.5

@onready var canvas_victoria: CanvasLayer = $CanvasVictoria
@onready var etiqueta_tiempo: Label = $CanvasVictoria/Panel/Contenido/EtiquetaTiempo
@onready var boton_reintentar: Button = $CanvasVictoria/Panel/Contenido/BotonReintentar
@onready var boton_menu: Button = $CanvasVictoria/Panel/Contenido/BotonMenu

var tiempo_inicio_ms: int = 0
var completado: bool = false
var _pos_base: Vector3
var _t: float = 0.0


func _ready() -> void:
	# La animación importada reescribe la posición (la llevaría al origen);
	# la detenemos y animamos por código, respetando dónde la colocaste.
	var ap: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if ap:
		ap.stop()
	_pos_base = position
	tiempo_inicio_ms = Time.get_ticks_msec()
	canvas_victoria.visible = false
	body_entered.connect(_on_body_entered)
	boton_reintentar.pressed.connect(_on_reintentar)
	boton_menu.pressed.connect(_on_menu)


func _process(delta: float) -> void:
	_t += delta
	if girar:
		rotate_y(deg_to_rad(velocidad_giro) * delta)
	if flotar:
		position.y = _pos_base.y + sin(_t * velocidad_flote) * altura_flote


func _on_body_entered(body: Node) -> void:
	if completado:
		return
	# Solo completa si el cuerpo es el jugador y tiene las gasolinas.
	if body.has_method("get_gasolinas") and body.get_gasolinas() >= gasolinas_necesarias:
		_victoria()


func _victoria() -> void:
	completado = true
	var segundos: float = (Time.get_ticks_msec() - tiempo_inicio_ms) / 1000.0
	var minutos: int = int(segundos) / 60
	etiqueta_tiempo.text = "Tiempo: %02d:%05.2f" % [minutos, fmod(segundos, 60.0)]
	canvas_victoria.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true


func _on_reintentar() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(escena_menu)
