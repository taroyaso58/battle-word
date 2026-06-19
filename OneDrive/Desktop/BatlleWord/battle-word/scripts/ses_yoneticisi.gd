extends Node

# Ses dosyaları buraya: res://assets/sounds/<isim>.wav
# Dosya yoksa sessiz geçer — crash yok.

const SES_YOLU = "res://assets/sounds/"
const SESLER = [
	"dogru_cevap",
	"yanlis_cevap",
	"buton_tikla",
	"sure_bitti",
	"mac_kazanildi",
	"mac_kaybedildi",
]

var _oynaticilar: Dictionary = {}

func _ready() -> void:
	for isim in SESLER:
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_oynaticilar[isim] = p
	_yukle()

func _yukle() -> void:
	for isim in SESLER:
		for uzanti in [".wav", ".ogg", ".mp3"]:
			var yol = SES_YOLU + isim + uzanti
			if ResourceLoader.exists(yol):
				_oynaticilar[isim].stream = load(yol)
				break

func cal(isim: String) -> void:
	if not _oynaticilar.has(isim):
		return
	var p: AudioStreamPlayer = _oynaticilar[isim]
	if p.stream:
		p.play()
