extends AudioStreamPlayer

@export var musica: AudioStream
@export_dir var carpeta_musica: String = "res://Sounds/Music"

@export_group("Efecto derrota")
@export var duracion_fundido: float = 1.2
@export var volumen_derrota_db: float = -30.0
@export var pitch_derrota: float = 0.6


func _ready() -> void:
	add_to_group("musica_escenario")
	if musica == null:
		var raiz: Node = owner if owner else self
		var ruta_escena: String = raiz.scene_file_path
		if ruta_escena != "":
			var nombre: String = ruta_escena.get_file().get_basename()
			var ruta: String = carpeta_musica.path_join(nombre + ".mp3")
			if ResourceLoader.exists(ruta):
				musica = load(ruta)
	if musica:
		if musica is AudioStreamMP3:
			musica.loop = true
		stream = musica
		play()

func derrota() -> void:
	var t: Tween = create_tween()
	t.set_parallel(true)
	t.tween_property(self, "volume_db", volumen_derrota_db, duracion_fundido)
	t.tween_property(self, "pitch_scale", pitch_derrota, duracion_fundido)
