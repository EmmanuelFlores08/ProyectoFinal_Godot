extends Control

@export_file("*.tscn") var escena_seleccion: String = "res://Scenes/elección_planeta.tscn"

@onready var boton_jugar: BaseButton = $Botones/BotonJugar
@onready var boton_salir: BaseButton = $Botones/BotonSalir


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	boton_jugar.pressed.connect(_jugar)
	boton_salir.pressed.connect(_salir)


func _jugar() -> void:
	get_tree().change_scene_to_file(escena_seleccion)


func _salir() -> void:
	get_tree().quit()
