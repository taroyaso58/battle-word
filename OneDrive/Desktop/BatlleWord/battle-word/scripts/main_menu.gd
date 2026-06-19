extends Control

@onready var profil_buton: Button = $MarginContainer/VBox/UstSatir/ProfilButon
@onready var oyna_buton: Button = $MarginContainer/VBox/OynaButon
@onready var nasil_buton: Button = $MarginContainer/VBox/NasilOynanilirButon
@onready var ayarlar_buton: Button = $MarginContainer/VBox/AyarlarButon

func _ready() -> void:
	oyna_buton.pressed.connect(_oyna)
	nasil_buton.pressed.connect(_nasil_oynanilir)
	ayarlar_buton.pressed.connect(_ayarlar)
	profil_buton.pressed.connect(_profil_ac)
	_profil_durumu_guncelle()
	# OYNA butonu diğerlerinden ayrışsın — turuncu
	oyna_buton.add_theme_stylebox_override("normal",  TemaYoneticisi.oyna_buton_stili())
	oyna_buton.add_theme_stylebox_override("hover",   TemaYoneticisi.oyna_buton_hover_stili())
	oyna_buton.add_theme_stylebox_override("pressed", TemaYoneticisi.oyna_buton_stili().duplicate())
	oyna_buton.add_theme_font_size_override("font_size", 28)

func _oyna() -> void:
	SesYoneticisi.cal("buton_tikla")
	get_tree().change_scene_to_file("res://scenes/mod_secimi.tscn")

func _nasil_oynanilir() -> void:
	SesYoneticisi.cal("buton_tikla")
	pass  # TODO: nasıl oynanılır ekranı

func _ayarlar() -> void:
	SesYoneticisi.cal("buton_tikla")
	pass  # TODO: ayarlar ekranı

func _profil_ac() -> void:
	SesYoneticisi.cal("buton_tikla")
	pass  # TODO: Google login ekranı

func _profil_durumu_guncelle() -> void:
	profil_buton.text = "👤  Giriş Yap"
