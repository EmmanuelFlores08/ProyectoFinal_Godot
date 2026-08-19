extends Control
class_name PantallaCargando

static var siguiente_escena: String = ""

@onready var punto1 = $CanvasLayer/punto1
@onready var punto2 = $CanvasLayer/punto2
@onready var punto3 = $CanvasLayer/punto3

var estado = 0


func _ready():
	punto1.hide()
	punto2.hide()
	punto3.hide()
	$CanvasLayer/cargando2.start()
	if siguiente_escena != "":
		ResourceLoader.load_threaded_request(siguiente_escena)


func _on_timer_timeout() -> void:
	if siguiente_escena == "":
		return
	var escena: PackedScene = ResourceLoader.load_threaded_get(siguiente_escena)
	if escena == null:
		escena = load(siguiente_escena)
	get_tree().change_scene_to_packed(escena)


func _on_cargando_2_timeout() -> void:
	estado += 1

	if estado == 1:
		punto1.show()
	elif estado == 2:
		punto2.show()
	elif estado == 3:
		punto3.show()
	elif estado == 4:
		punto1.hide()
		punto2.hide()
		punto3.hide()
		estado = 0
