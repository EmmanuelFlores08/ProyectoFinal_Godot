extends Control

@onready var punto1 = $CanvasLayer/punto1
@onready var punto2 = $CanvasLayer/punto2
@onready var punto3 = $CanvasLayer/punto3

var estado = 0

func _ready():
	punto1.hide()
	punto2.hide()
	punto3.hide()
	$CanvasLayer/cargando2.start()
func _on_timer_timeout() -> void:
	
	print("¡¡EL TIMER FUNCIONÓ!!")
	get_tree().change_scene_to_file("res://Instancias/Kalamyr/krakencito_1.tscn")


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
