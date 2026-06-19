extends Control

@onready var sonuc_etiket: Label  = $MarginContainer/VBox/SonucEtiket
@onready var skor_etiket: Label   = $MarginContainer/VBox/SkorEtiket
@onready var dogru_yanlis: Label  = $MarginContainer/VBox/DogruYanlis
@onready var tekrar_buton: Button = $MarginContainer/VBox/ButonSatiri/TekrarButon
@onready var menu_buton: Button   = $MarginContainer/VBox/ButonSatiri/MenuButon

func _ready() -> void:
	tekrar_buton.pressed.connect(_tekrar_oyna)
	menu_buton.pressed.connect(_ana_menu)
	_sonucu_goster()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_ana_menu()

func _sonucu_goster() -> void:
	var kazanan    = GameManager.son_kazanan
	var skor       = SkorYoneticisi.mevcut_skor
	var en_yuksek  = SkorYoneticisi.en_yuksek_skor

	if GameManager.mod == "online" and GameManager.online_kural == "puan":
		var rakip_skor = GameManager.puan_modu_rakip_skor
		match kazanan:
			"oyuncu":
				sonuc_etiket.text = "KAZANDIN! 🏆"
				sonuc_etiket.add_theme_color_override("font_color", Color("#2DC653"))
			"berabere":
				sonuc_etiket.text = "BERABERE! 🤝"
				sonuc_etiket.add_theme_color_override("font_color", Color("#4895EF"))
			_:
				sonuc_etiket.text = "KAYBETTİN"
				sonuc_etiket.add_theme_color_override("font_color", Color("#E63946"))
		skor_etiket.text = "Senin puan: " + str(skor) + "   |   Rakip: " + str(rakip_skor)
		dogru_yanlis.text = (
			"✅ Doğru: " + str(SkorYoneticisi.toplam_dogru) +
			"   ❌ Yanlış: " + str(SkorYoneticisi.toplam_yanlis)
		)
		return

	match kazanan:
		"tamamlandi":
			sonuc_etiket.text = "TAMAMLADIN! 🎓"
			sonuc_etiket.add_theme_color_override("font_color", Color("#4895EF"))
			tekrar_buton.text = "TEKRAR ÇALIŞ"
		"oyuncu":
			sonuc_etiket.text = "KAZANDIN! 🏆"
			sonuc_etiket.add_theme_color_override("font_color", Color("#2DC653"))
		"berabere":
			sonuc_etiket.text = "BERABERE! 🤝"
			sonuc_etiket.add_theme_color_override("font_color", Color("#4895EF"))
		_:
			sonuc_etiket.text = "KAYBETTİN"
			sonuc_etiket.add_theme_color_override("font_color", Color("#E63946"))

	skor_etiket.text = "Skor: " + str(skor)
	if skor >= en_yuksek and skor > 0:
		skor_etiket.text += "  🌟 Yeni rekor!"

	dogru_yanlis.text = (
		"✅ Doğru: " + str(SkorYoneticisi.toplam_dogru) +
		"   ❌ Yanlış: " + str(SkorYoneticisi.toplam_yanlis)
	)

func _tekrar_oyna() -> void:
	if GameManager.mod == "online":
		get_tree().change_scene_to_file("res://scenes/bekleme_ekrani.tscn")
		return
	GameManager.oyun_baslat(GameManager.mod)
	get_tree().change_scene_to_file("res://scenes/oyun_ekrani.tscn")

func _ana_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
