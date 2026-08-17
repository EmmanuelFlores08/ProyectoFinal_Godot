extends Area3D
## Coleccionable de gasolina. Se recoge automáticamente al tocarlo.
## Instancia autónoma: arrástrala a la escena (coloca 3 por escenario).

## Cuánta gasolina suma al jugador al recogerla.
@export var cantidad: int = 1

@export_group("Animación")
@export var girar: bool = true
@export var velocidad_giro: float = 90.0   # grados por segundo
@export var flotar: bool = true
@export var altura_flote: float = 0.15     # metros
@export var velocidad_flote: float = 2.0

var _pos_base: Vector3
var _t: float = 0.0


func _ready() -> void:
	# Una animación importada podría reescribir la posición y teletransportar
	# el coleccionable al origen; la detenemos y animamos por código.
	var ap: AnimationPlayer = get_node_or_null("AnimationPlayer")
	if ap:
		ap.stop()
	_pos_base = position
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	if girar:
		rotate_y(deg_to_rad(velocidad_giro) * delta)
	if flotar:
		position.y = _pos_base.y + sin(_t * velocidad_flote) * altura_flote


func _on_body_entered(body: Node) -> void:
	# Sin dependencias: cualquier cuerpo que sepa recoger gasolina la recoge.
	if body.has_method("recolectar_gasolina"):
		body.recolectar_gasolina(cantidad)
		queue_free()  # Desaparece al recogerla.
