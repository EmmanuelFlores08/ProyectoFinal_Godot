extends Node3D

const PANTALLA_CARGA := "res://Scenes/Pantalla_Cargando.tscn"

@export_file("*.tscn") var escena_planeta1: String = "res://Scenes/Kalamyr.tscn"
@export_file("*.tscn") var escena_planeta2: String = "res://Scenes/Fungora.tscn"
@export_file("*.tscn") var escena_planeta3: String = "res://Scenes/Calcyra.tscn"
@export_file("*.tscn") var escena_menu: String = "res://Scenes/Menu.tscn"

@onready var b1: BaseButton = $IU/Control/B_Planeta1
@onready var b2: BaseButton = $IU/Control/B_Planeta2
@onready var b3: BaseButton = $IU/Control/B_Planeta3
@onready var boton_menu: BaseButton = $IU/Control/BotonMenu


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	b1.pressed.connect(_ir.bind(escena_planeta1))
	b2.pressed.connect(_ir.bind(escena_planeta2))
	b3.pressed.connect(_ir.bind(escena_planeta3))
	boton_menu.pressed.connect(_volver_menu)


func _ir(escena: String) -> void:
	PantallaCargando.siguiente_escena = escena
	get_tree().change_scene_to_file(PANTALLA_CARGA)


func _volver_menu() -> void:
	get_tree().change_scene_to_file(escena_menu)
