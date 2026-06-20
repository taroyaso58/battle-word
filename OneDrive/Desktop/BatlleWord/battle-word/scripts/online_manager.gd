extends Node

# == Firebase Yapılandırması ==
const FIREBASE_API_KEY    := "YOUR APIKEY"
const FIREBASE_PROJECT_ID := "YOUR ID"

const DB_URL   := "https://" + FIREBASE_PROJECT_ID + "-default-rtdb.firebaseio.com"
const AUTH_URL := "YOUR KEY" + FIREBASE_API_KEY

signal giris_tamamlandi(uid: String)
signal giris_hatasi(mesaj: String)
signal eslestirme_bekleniyor()
signal eslestirme_tamamlandi(lobi_id: String, oyuncu_no: int)
signal online_soru_geldi(soru: Dictionary)
signal tur_sonucu(kazanan_oyuncu_no: int)  # 1 | 2 | 0 (berabere)
signal online_oyun_bitti(kazanan_oyuncu_no: int)
signal puan_modu_sonucu(kazandim: bool, benim_skor: int, rakip_skor: int)

var uid: String       = ""
var id_token: String  = ""
var lobi_id: String   = ""
var oyuncu_no: int    = 0  # 1 = host, 2 = misafir

# Tur durumu
var _cevap_gonderildi: bool  = false
var _son_soru_id: String     = ""
var _son_kazanan: String     = ""
var _kazanan_yaziliyor: bool = false  # çift kazanan yazımını önler
var _bekleme_modunda: bool   = false  # sonuç bekleme süresi

# Puan modu: kendi cevabımızın doğruluğunu yerel olarak saklarız
var benim_cevabim_dogru: bool = false
var benim_kalan_sure: float   = 0.0

# Puan modu bitiş
var _puan_bekleniyor: bool = false

var _polling_timer: Timer
var _bekleme_timer: Timer = null

func _ready() -> void:
	_polling_timer = Timer.new()
	_polling_timer.wait_time = 0.5
	_polling_timer.one_shot = false
	_polling_timer.timeout.connect(_tur_poll)
	add_child(_polling_timer)

# ─── Kimlik Doğrulama ────────────────────────────────────────────

func anonim_giris_yap() -> void:
	if not uid.is_empty():
		emit_signal("giris_tamamlandi", uid)
		return
	if FIREBASE_API_KEY.is_empty():
		emit_signal("giris_hatasi", "Firebase API anahtarı ayarlanmamış")
		return
	_http(AUTH_URL, HTTPClient.METHOD_POST,
		JSON.stringify({"returnSecureToken": true}),
		func(kod, govde):
			if kod == 200:
				var j = JSON.parse_string(govde)
				uid      = j.get("localId", "")
				id_token = j.get("idToken", "")
				emit_signal("giris_tamamlandi", uid)
			else:
				emit_signal("giris_hatasi", "Sunucu hatası: " + str(kod))
	)

# ─── Eşleştirme ──────────────────────────────────────────────────

func lobi_ara() -> void:
	_db_oku("/lobbies", func(veri):
		if not (veri is Dictionary):
			_yeni_lobi()
			return
		for lid in veri:
			var l = veri[lid]
			if l.get("durum") == "bekliyor" and l.get("oyuncu2_uid", "") == "":
				_katil(lid)
				return
		_yeni_lobi()
	)

func _yeni_lobi() -> void:
	lobi_id = "l_" + uid.substr(0, 6) + "_" + str(randi() % 9999)
	oyuncu_no = 1
	_db_yaz("/lobbies/" + lobi_id, {
		"oyuncu1_uid": uid,
		"oyuncu2_uid": "",
		"durum": "bekliyor",
		"oyuncu1_can": 3,
		"oyuncu2_can": 3,
		"kural": GameManager.online_kural
	}, func(_ok):
		emit_signal("eslestirme_bekleniyor")
		_bekleme_pollunu_baslat()
	)

func _bekleme_pollunu_baslat() -> void:
	_bekleme_timer = Timer.new()
	_bekleme_timer.wait_time = 1.5
	_bekleme_timer.one_shot = false
	_bekleme_timer.timeout.connect(func():
		_db_oku("/lobbies/" + lobi_id + "/oyuncu2_uid", func(v):
			if v is String and v.length() > 0:
				_bekleme_timer.queue_free()
				_bekleme_timer = null
				emit_signal("eslestirme_tamamlandi", lobi_id, 1)
		)
	)
	add_child(_bekleme_timer)
	_bekleme_timer.start()

func _katil(lid: String) -> void:
	lobi_id   = lid
	oyuncu_no = 2
	_db_oku("/lobbies/" + lobi_id + "/kural", func(kural):
		if kural is String and kural.length() > 0:
			GameManager.online_kural = kural
		_db_guncelle("/lobbies/" + lobi_id, {
			"oyuncu2_uid": uid,
			"durum": "oynuyor"
		}, func(_ok):
			emit_signal("eslestirme_tamamlandi", lobi_id, 2)
		)
	)

# ─── Oyun Akışı ──────────────────────────────────────────────────

func oyun_baslat_online() -> void:
	_son_soru_id         = ""
	_son_kazanan         = ""
	_cevap_gonderildi    = false
	_kazanan_yaziliyor   = false
	_bekleme_modunda     = false
	_puan_bekleniyor     = false
	benim_cevabim_dogru  = false
	benim_kalan_sure     = 0.0
	_polling_timer.start()
	if oyuncu_no == 1:
		_yeni_soru_yaz()

func _yeni_soru_yaz() -> void:
	var soru = SoruYoneticisi.rastgele_soru_al()
	_db_yaz("/lobbies/" + lobi_id + "/tur", {
		"soru_id": soru.get("id", ""),
		"oyuncu1": {"cevap": "", "zaman": 0, "dogru": false, "hazir": false},
		"oyuncu2": {"cevap": "", "zaman": 0, "dogru": false, "hazir": false},
		"kazanan": ""
	}, func(_ok):
		_son_soru_id      = soru.get("id", "")
		_son_kazanan      = ""
		_cevap_gonderildi = false
		emit_signal("online_soru_geldi", soru)
	)

func cevap_gonder(soru: Dictionary, cevap: String) -> void:
	if _cevap_gonderildi:
		return
	_cevap_gonderildi   = true
	_bekleme_modunda    = true  # tur_sonucu gelmeden yeni soru algılanmasın
	benim_cevabim_dogru = SoruYoneticisi.cevap_dogru_mu(soru, cevap)
	benim_kalan_sure    = GameManager.kalan_sure
	var dogru    = benim_cevabim_dogru
	var anahtar  = "oyuncu" + str(oyuncu_no)
	_db_guncelle("/lobbies/" + lobi_id + "/tur/" + anahtar, {
		"cevap": cevap,
		"zaman": {".sv": "timestamp"},
		"dogru": dogru,
		"hazir": true
	}, Callable())

func sure_doldu() -> void:
	if _cevap_gonderildi:
		return
	_cevap_gonderildi   = true
	_bekleme_modunda    = true  # tur_sonucu gelmeden yeni soru algılanmasın
	benim_cevabim_dogru = false
	benim_kalan_sure    = 0.0
	var anahtar = "oyuncu" + str(oyuncu_no)
	_db_guncelle("/lobbies/" + lobi_id + "/tur/" + anahtar, {
		"cevap": "",
		"zaman": {".sv": "timestamp"},
		"dogru": false,
		"hazir": true
	}, Callable())

func yeni_tur_baslat() -> void:
	# _son_kazanan SIFIRLAMA: eski kazanan verisi polling'de yeniden tetiklenmesin diye
	# burada sıfırlamıyoruz — oyuncu2 için yeni soru_id gelince, oyuncu1 için
	# _yeni_soru_yaz callback'inde doğal olarak sıfırlanır.
	_cevap_gonderildi  = false
	_kazanan_yaziliyor = false
	_bekleme_modunda   = false
	if oyuncu_no == 1:
		_yeni_soru_yaz()

# Sonuç feedback gösterilirken yeni soru sinyalini engeller
func bekleme_moduna_gir() -> void:
	_bekleme_modunda = true

func bekleme_modundan_cik() -> void:
	_bekleme_modunda = false

# ─── Puan Modu Bitiş ─────────────────────────────────────────────

func puan_modu_bitir(skor: int) -> void:
	_puan_bekleniyor = true
	var anahtar = "oyuncu" + str(oyuncu_no) + "_skor"
	_db_guncelle("/lobbies/" + lobi_id + "/final", {anahtar: skor}, Callable())

# ─── Polling ─────────────────────────────────────────────────────

func _tur_poll() -> void:
	if _puan_bekleniyor:
		_db_oku("/lobbies/" + lobi_id + "/final", func(final):
			if not (final is Dictionary):
				return
			# Host her iki skoru görünce kazananı yazar
			if oyuncu_no == 1:
				var o1 = final.get("oyuncu1_skor", -1)
				var o2 = final.get("oyuncu2_skor", -1)
				if o1 != -1 and o2 != -1 and final.get("kazanan", "").is_empty():
					var k: String
					if o1 > o2:   k = "oyuncu1"
					elif o2 > o1: k = "oyuncu2"
					else:         k = "berabere"
					_db_guncelle("/lobbies/" + lobi_id + "/final", {"kazanan": k}, Callable())
			var kazanan: String = final.get("kazanan", "")
			if not kazanan.is_empty():
				_puan_bekleniyor = false
				_polling_timer.stop()
				var benim_skor = final.get("oyuncu" + str(oyuncu_no) + "_skor", 0)
				var rakip_no   = 2 if oyuncu_no == 1 else 1
				var rakip_skor = final.get("oyuncu" + str(rakip_no) + "_skor", 0)
				var kazandim   = (kazanan == "oyuncu" + str(oyuncu_no))
				emit_signal("puan_modu_sonucu", kazandim, benim_skor, rakip_skor)
		)
		return

	_db_oku("/lobbies/" + lobi_id + "/tur", func(tur):
		if not (tur is Dictionary):
			return

		var soru_id: String = tur.get("soru_id", "")
		var kazanan: String = tur.get("kazanan", "")

		# Oyuncu2: yeni soru — sadece bekleme modunda değilse işle
		if oyuncu_no == 2 and not _bekleme_modunda \
				and soru_id != _son_soru_id and soru_id.length() > 0:
			_son_soru_id      = soru_id
			_son_kazanan      = ""
			_cevap_gonderildi = false
			var soru = SoruYoneticisi.id_ile_soru_al(soru_id)
			if not soru.is_empty():
				emit_signal("online_soru_geldi", soru)

		# Oyuncu1: her iki taraf hazırsa kazananı belirle (tek seferlik)
		if oyuncu_no == 1 and kazanan.is_empty() \
				and soru_id == _son_soru_id and not _kazanan_yaziliyor:
			var o1: Dictionary = tur.get("oyuncu1", {})
			var o2: Dictionary = tur.get("oyuncu2", {})
			if o1.get("hazir", false) and o2.get("hazir", false):
				_kazanan_yaziliyor = true
				_kazanani_belirle(o1, o2)

		# Her iki oyuncu: kazanan değişti mi?
		if not kazanan.is_empty() and kazanan != _son_kazanan:
			_son_kazanan = kazanan
			_tur_sonucunu_isle(kazanan)
	)

func _kazanani_belirle(o1: Dictionary, o2: Dictionary) -> void:
	var o1_dogru: bool = o1.get("dogru", false)
	var o2_dogru: bool = o2.get("dogru", false)
	var o1_zaman: int  = int(o1.get("zaman", 0))
	var o2_zaman: int  = int(o2.get("zaman", 0))

	var kazanan := "berabere"
	if o1_dogru and o2_dogru:
		kazanan = "oyuncu1" if o1_zaman <= o2_zaman else "oyuncu2"
	elif o1_dogru:
		kazanan = "oyuncu1"
	elif o2_dogru:
		kazanan = "oyuncu2"

	_db_guncelle("/lobbies/" + lobi_id + "/tur", {"kazanan": kazanan},
		func(_ok): _kazanan_yaziliyor = false
	)

func _tur_sonucunu_isle(kazanan: String) -> void:
	var kazanan_no := 0
	match kazanan:
		"oyuncu1": kazanan_no = 1
		"oyuncu2": kazanan_no = 2
	emit_signal("tur_sonucu", kazanan_no)

# ─── Temizlik ────────────────────────────────────────────────────

func lobi_temizle() -> void:
	_polling_timer.stop()
	_puan_bekleniyor   = false
	_bekleme_modunda   = false
	_kazanan_yaziliyor = false
	if _bekleme_timer != null:
		_bekleme_timer.queue_free()
		_bekleme_timer = null
	if not lobi_id.is_empty():
		_db_sil("/lobbies/" + lobi_id)
	lobi_id   = ""
	oyuncu_no = 0

# ─── Firebase REST Yardımcıları ───────────────────────────────────

func _db_oku(yol: String, cb: Callable) -> void:
	_http(DB_URL + yol + ".json?auth=" + id_token, HTTPClient.METHOD_GET, "",
		func(kod, govde):
			cb.call(JSON.parse_string(govde) if kod == 200 else null)
	)

func _db_yaz(yol: String, veri: Dictionary, cb: Callable) -> void:
	_http(DB_URL + yol + ".json?auth=" + id_token, HTTPClient.METHOD_PUT,
		JSON.stringify(veri),
		func(kod, _g): if cb.is_valid(): cb.call(kod == 200)
	)

func _db_guncelle(yol: String, veri: Dictionary, cb: Callable) -> void:
	_http(DB_URL + yol + ".json?auth=" + id_token, HTTPClient.METHOD_PATCH,
		JSON.stringify(veri),
		func(kod, _g): if cb.is_valid(): cb.call(kod == 200)
	)

func _db_sil(yol: String) -> void:
	_http(DB_URL + yol + ".json?auth=" + id_token, HTTPClient.METHOD_DELETE, "", Callable())

func _http(url: String, metod: int, govde: String, cb: Callable) -> void:
	var h = HTTPRequest.new()
	add_child(h)
	h.request_completed.connect(func(_r, kod, _hd, raw):
		h.queue_free()
		if cb.is_valid():
			cb.call(kod, raw.get_string_from_utf8())
	)
	h.request(url, ["Content-Type: application/json"], metod, govde)
