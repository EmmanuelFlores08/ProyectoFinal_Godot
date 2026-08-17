extends Area3D
class_name Trap
## Componente de trampa reutilizable.
## Al detectar al jugador, le ordena morir. No depende del Character:
## solo llama a un método por nombre (por defecto "morir").
##
## Para crear una trampa nueva:
##   1. Crea/importa tu modelo.
##   2. Añade este componente (usa trap.tscn o pon este script en un Area3D).
##   3. Configura su CollisionShape3D.
##   4. Colócala en el escenario.
## No hay que tocar el código del Character.

## Si está desactivada, la trampa no hace nada (útil para activarla luego).
@export var activa: bool = true
## Método que se llama en el jugador al tocarlo. Cambia a "recibir_dano"
## u otro si en el futuro usas daño en vez de muerte directa.
@export var metodo_jugador: StringName = &"morir"
## Grupo que debe tener el cuerpo para contar como jugador ("" = cualquiera
## que tenga el método). Útil si hay otros cuerpos que también pueden morir.
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
