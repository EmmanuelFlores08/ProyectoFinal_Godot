extends Area3D

@export var animacion: String = "TrampasCaen"
@onready var anim: AnimationPlayer = $AnimationPlayer

func _on_body_entered(body: Node3D) -> void:
	if body.has_method("morir"):
		anim.play(animacion)
