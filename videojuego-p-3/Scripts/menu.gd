extends Control

@export_file("*.tscn") var escena_seleccion: String = "res://Scenes/elección_planeta.tscn"

@onready var boton_jugar: BaseButton = $Botones/BotonJugar
@onready var boton_salir: BaseButton = $Botones/BotonSalir
@onready var boton_creditos: BaseButton = $BotonCreditos
@onready var canvas_creditos: CanvasLayer = $Creditos
@onready var boton_cerrar_creditos: BaseButton = $Creditos/BotonCerrar


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	canvas_creditos.visible = false
	boton_jugar.pressed.connect(_jugar)
	boton_salir.pressed.connect(_salir)
	boton_creditos.pressed.connect(_abrir_creditos)
	boton_cerrar_creditos.pressed.connect(_cerrar_creditos)


func _jugar() -> void:
	get_tree().change_scene_to_file(escena_seleccion)


func _salir() -> void:
	get_tree().quit()


func _abrir_creditos() -> void:
	canvas_creditos.visible = true


func _cerrar_creditos() -> void:
	canvas_creditos.visible = false
