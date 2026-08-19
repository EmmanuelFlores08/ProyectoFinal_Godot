extends Area3D
class_name Trap

@export var activa: bool = true

@export var metodo_jugador: StringName = &"morir"

@export var grupo_jugador: StringName = &""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if not activa:
		return
	if grupo_jugador != &"" and not body.is_in_group(grupo_jugador):
		return
	if body.has_method(metodo_jugador):
		body.call(metodo_jugador)


func _on_area_3d_body_entered(body: Node3D) -> void:
	pass # Replace with function body.
