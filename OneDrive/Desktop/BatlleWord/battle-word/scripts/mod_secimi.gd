extends Control

@onready var online_buton: Button  = $MarginContainer/VBox/KartSatiri/OnlineKart/OnlineVBox/OnlineButon
@onready var solo_buton: Button    = $MarginContainer/VBox/KartSatiri/SoloKart/SoloVBox/SoloButon
@onready var online_kilit: Label   = $MarginContainer/VBox/KilitlemeMetni
@onready var geri_buton: Button    = $MarginContainer/VBox/UstSatir/GeriButon
@onready var zayif_buton: Button   = $MarginContainer/VBox/ZayifButon
@onready var puan_buton: Button    = $MarginContainer/VBox/PuanModuButon

func _ready() -> void:
	geri_buton.pressed.connect(_geri)
	online_buton.pressed.connect(_online_sec)
	solo_buton.pressed.connect(_solo_sec)
	zayif_buton.pressed.connect(_zayif_sec)
	puan_buton.pressed.connect(_puan_modu_sec)
	_online_durumunu_guncelle()
	_zayif_havuz_guncelle()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_geri()

func _online_durumunu_guncelle() -> void:
	var firebase_ayarli = not OnlineManager.FIREBASE_API_KEY.is_empty()
	if firebase_ayarli:
		online_buton.disabled = false
		puan_buton.disabled   = false
		online_kilit.visible  = false
	else:
		online_buton.disabled = true
		puan_buton.disabled   = true
		online_kilit.visible  = true
		online_kilit.text     = "🔒  Firebase ayarlanmamış"

func _zayif_havuz_guncelle() -> void:
	var sayi = SoruYoneticisi.yanlis_havuz_sayisi()
	if sayi == 0:
		zayif_buton.text = "📚  Zayıf Noktalarını Çalış  (henüz kelime yok)"
		zayif_buton.disabled = true
	else:
		zayif_buton.text = "📚  Zayıf Noktalarını Çalış  (" + str(sayi) + " kelime)"
		zayif_buton.disabled = false

func _online_sec() -> void:
	SesYoneticisi.cal("buton_tikla")
	GameManager.online_kural = "can"
	get_tree().change_scene_to_file("res://scenes/bekleme_ekrani.tscn")

func _puan_modu_sec() -> void:
	SesYoneticisi.cal("buton_tikla")
	GameManager.online_kural = "puan"
	get_tree().change_scene_to_file("res://scenes/bekleme_ekrani.tscn")

func _solo_sec() -> void:
	SesYoneticisi.cal("buton_tikla")
	GameManager.oyun_baslat("solo")
	get_tree().change_scene_to_file("res://scenes/oyun_ekrani.tscn")

func _zayif_sec() -> void:
	SesYoneticisi.cal("buton_tikla")
	GameManager.oyun_baslat("zayyif_noktalar")
	get_tree().change_scene_to_file("res://scenes/oyun_ekrani.tscn")

func _geri() -> void:
	SesYoneticisi.cal("buton_tikla")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
