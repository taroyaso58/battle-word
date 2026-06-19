extends Control

@onready var durum_etiket: Label  = $MarginContainer/VBox/DurumEtiket
@onready var iptal_buton: Button  = $MarginContainer/VBox/IptalButon

var _nokta_sayaci: int = 0
var _nokta_timer: Timer

func _ready() -> void:
	iptal_buton.pressed.connect(_iptal)

	OnlineManager.giris_tamamlandi.connect(_giris_ok)
	OnlineManager.giris_hatasi.connect(_giris_hata)
	OnlineManager.eslestirme_bekleniyor.connect(_eslesme_bekleniyor)
	OnlineManager.eslestirme_tamamlandi.connect(_eslesme_tamam)

	_nokta_timer = Timer.new()
	_nokta_timer.wait_time = 0.6
	_nokta_timer.one_shot  = false
	_nokta_timer.timeout.connect(_nokta_animasyon)
	add_child(_nokta_timer)
	_nokta_timer.start()

	_durum_goster("Bağlanılıyor")
	OnlineManager.anonim_giris_yap()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_iptal()

func _giris_ok(_uid: String) -> void:
	_durum_goster("Rakip aranıyor")
	OnlineManager.lobi_ara()

func _giris_hata(mesaj: String) -> void:
	durum_etiket.text = "Hata: " + mesaj
	iptal_buton.text  = "Geri Dön"
	_nokta_timer.stop()

func _eslesme_bekleniyor() -> void:
	_durum_goster("Rakip bekleniyor")

func _eslesme_tamam(_lobi_id: String, _oyuncu_no: int) -> void:
	_nokta_timer.stop()
	durum_etiket.text = "Rakip bulundu! Başlıyor..."
	GameManager.oyun_baslat("online")
	get_tree().change_scene_to_file("res://scenes/oyun_ekrani.tscn")

func _iptal() -> void:
	OnlineManager.lobi_temizle()
	get_tree().change_scene_to_file("res://scenes/mod_secimi.tscn")

func _durum_goster(baz: String) -> void:
	durum_etiket.set_meta("baz_metin", baz)

func _nokta_animasyon() -> void:
	_nokta_sayaci = (_nokta_sayaci + 1) % 4
	var baz: String = durum_etiket.get_meta("baz_metin", "Bekleniyor")
	durum_etiket.text = baz + ".".repeat(_nokta_sayaci)
