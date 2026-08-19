extends BaseButton

@export var escala_hover: float = 1.08
@export var escala_pulsado: float = 0.94
@export var duracion: float = 0.08


func _ready() -> void:
	resized.connect(_centrar_pivote)
	mouse_entered.connect(_al_resaltar)
	focus_entered.connect(_al_resaltar)
	mouse_exited.connect(_al_soltar)
	focus_exited.connect(_al_soltar)
	button_down.connect(_al_pulsar)
	button_up.connect(_al_soltar)
	_centrar_pivote()


func _centrar_pivote() -> void:
	pivot_offset = size / 2.0


func _al_resaltar() -> void:
	_escalar(escala_hover)


func _al_pulsar() -> void:
	_escalar(escala_pulsado)


func _al_soltar() -> void:
	_escalar(escala_hover if is_hovered() else 1.0)


func _escalar(factor: float) -> void:
	create_tween().tween_property(self, "scale", Vector2.ONE * factor, duracion)
