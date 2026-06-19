extends Control

@onready var sure_bar: ProgressBar      = $VBox/UstBar/SureGostergesi
@onready var kategori_etiket: Label     = $VBox/SoruAlani/KategoriEtiketi
@onready var soru_metni: RichTextLabel  = $VBox/SoruAlani/SoruMetni
@onready var cevap_input: LineEdit      = $VBox/SoruAlani/CevapInput
@onready var gonder_buton: Button       = $VBox/GonderButon
@onready var oyuncu_canlar: HBoxContainer = $VBox/UstBar/CanSatiri/OyuncuCanlar
@onready var rakip_canlar: HBoxContainer  = $VBox/UstBar/CanSatiri/RakipBolum/RakipCanlar
@onready var rakip_bolum: VBoxContainer   = $VBox/UstBar/CanSatiri/RakipBolum
@onready var sure_metin: Label            = $VBox/UstBar/CanSatiri/SureMetin
@onready var feedback_panel: Panel      = $FeedbackPanel
@onready var feedback_etiket: Label     = $FeedbackPanel/FeedbackEtiket
@onready var ipucu_buton: Button        = $VBox/SoruAlani/IpucuButon

func _ready() -> void:
	GameManager.soru_degisti.connect(_soru_guncelle)
	GameManager.sure_guncellendi.connect(_sure_guncelle)
	GameManager.can_degisti.connect(_can_guncelle)
	GameManager.mikro_feedback_yanlis.connect(_feedback_yanlis)
	GameManager.mikro_feedback_dogru.connect(_feedback_dogru)
	GameManager.oyun_bitti.connect(_oyun_bitti)

	gonder_buton.pressed.connect(_cevap_gonder)
	cevap_input.text_submitted.connect(func(_t): _cevap_gonder())
	ipucu_buton.pressed.connect(_ipucu_goster)

	feedback_panel.visible = false

	var puan_modu = (GameManager.mod == "online" and GameManager.online_kural == "puan")

	if puan_modu:
		oyuncu_canlar.visible = false
		rakip_bolum.visible   = false
		sure_metin.text       = "0/" + str(GameManager.PUAN_MODU_TUR)
		GameManager.tur_sayaci_guncellendi.connect(_tur_sayaci_guncelle)
	else:
		_canlari_goster("oyuncu", GameManager.BASLANGIC_CAN)
		_canlari_goster("rakip", GameManager.BASLANGIC_CAN)
		rakip_bolum.visible = (GameManager.mod == "online")

	if not GameManager.aktif_soru.is_empty():
		_soru_guncelle(GameManager.aktif_soru)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		GameManager.oyun_aktif = false
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _soru_guncelle(soru: Dictionary) -> void:
	var kat = soru.get("kategori", "tanim").replace("_", "-").to_upper()
	kategori_etiket.text = "[ " + kat + " ]"
	soru_metni.text = "[center]" + soru.get("soru", "") + "[/center]"
	cevap_input.text = ""
	feedback_panel.visible = false
	if OS.get_name() != "Android" and OS.get_name() != "iOS":
		cevap_input.grab_focus()

func _sure_guncelle(kalan: float, toplam: float) -> void:
	sure_bar.max_value = toplam
	sure_bar.value = kalan
	if kalan <= 10.0:
		sure_bar.modulate = Color("#E63946")
	else:
		sure_bar.modulate = Color("#4895EF")

func _can_guncelle(taraf: String, can: int) -> void:
	_canlari_goster(taraf, can)

func _tur_sayaci_guncelle(mevcut: int, toplam: int) -> void:
	sure_metin.text = str(mevcut) + "/" + str(toplam)

func _feedback_yanlis(dogru_cevap: String) -> void:
	SesYoneticisi.cal("yanlis_cevap")
	feedback_etiket.text = "✗  Doğrusu:  " + dogru_cevap.to_upper()
	feedback_etiket.add_theme_color_override("font_color", Color("#E63946"))
	feedback_panel.visible = true

func _feedback_dogru(kazanilan_puan: int) -> void:
	SesYoneticisi.cal("dogru_cevap")
	feedback_etiket.text = "✓  DOĞRU!  +" + str(kazanilan_puan) + " puan"
	feedback_etiket.add_theme_color_override("font_color", Color("#2DC653"))
	feedback_panel.visible = true

func _cevap_gonder() -> void:
	var metin = cevap_input.text.strip_edges()
	if metin.is_empty():
		return
	if GameManager.mod == "online":
		feedback_etiket.text = "⏳  Cevabın: " + metin.to_upper()
		feedback_etiket.add_theme_color_override("font_color", Color("#4895EF"))
		feedback_panel.visible = true
	GameManager.cevap_gonder(metin)
	cevap_input.text = ""

func _ipucu_goster() -> void:
	var ipucu = GameManager.aktif_soru.get("ipucu", "")
	if ipucu.is_empty():
		return
	feedback_etiket.text = "İpucu:  " + ipucu
	feedback_panel.visible = true

func _oyun_bitti(kazanan: String, _skor: int) -> void:
	match kazanan:
		"oyuncu", "tamamlandi":
			SesYoneticisi.cal("mac_kazanildi")
		_:
			SesYoneticisi.cal("mac_kaybedildi")
	get_tree().change_scene_to_file("res://scenes/sonuc_ekrani.tscn")

func _canlari_goster(taraf: String, can: int) -> void:
	var hedef = oyuncu_canlar if taraf == "oyuncu" else rakip_canlar
	for child in hedef.get_children():
		child.queue_free()
	for i in GameManager.BASLANGIC_CAN:
		var kalp = Label.new()
		kalp.text = "♥" if i < can else "♡"
		kalp.add_theme_color_override("font_color",
			Color("#E63946") if i < can else Color("#444444"))
		kalp.add_theme_font_size_override("font_size", 36)
		hedef.add_child(kalp)
