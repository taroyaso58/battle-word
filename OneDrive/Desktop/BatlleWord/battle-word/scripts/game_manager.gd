extends Node

signal soru_degisti(soru: Dictionary)
signal sure_guncellendi(kalan: float, toplam: float)
signal can_degisti(taraf: String, can: int)
signal mikro_feedback_yanlis(dogru_cevap: String)
signal mikro_feedback_dogru(kazanilan_puan: int)
signal oyun_bitti(kazanan: String, skor: int)
signal tur_sayaci_guncellendi(mevcut: int, toplam: int)

const BASLANGIC_CAN  := 3
const YANLIS_BEKLEME := 2.0
const DOGRU_BEKLEME  := 0.8
const PUAN_MODU_TUR  := 8

var mod: String          = ""    # "solo" | "online" | "zayyif_noktalar"
var online_kural: String = "can" # "can" | "puan"
var oyuncu_can: int      = BASLANGIC_CAN
var rakip_can: int       = BASLANGIC_CAN
var aktif_soru: Dictionary = {}
var kalan_sure: float    = 0.0
var oyun_aktif: bool     = false
var son_kazanan: String  = ""
var tur_sayaci: int      = 0
var puan_modu_rakip_skor: int = 0

func _process(delta: float) -> void:
	if not oyun_aktif:
		return
	kalan_sure -= delta
	emit_signal("sure_guncellendi", kalan_sure, aktif_soru.get("sure", 30.0))
	if kalan_sure <= 0.0:
		_sure_doldu()

# ─── Başlatma ───────────────────────────────────────────────────

func oyun_baslat(oyun_modu: String) -> void:
	mod        = oyun_modu
	oyuncu_can = BASLANGIC_CAN
	rakip_can  = BASLANGIC_CAN
	oyun_aktif = false
	son_kazanan = ""
	tur_sayaci = 0
	puan_modu_rakip_skor = 0
	SkorYoneticisi.reset()

	if mod == "online":
		_online_sinyalleri_bagla()
		OnlineManager.oyun_baslat_online()
	else:
		yeni_soru_al()

# ─── Solo / Zayıf Noktalar ──────────────────────────────────────

func yeni_soru_al() -> void:
	if mod == "zayyif_noktalar":
		aktif_soru = SoruYoneticisi.yanlis_havuzdan_soru_al()
		if aktif_soru.is_empty():
			_oyun_bitir("tamamlandi")
			return
	else:
		aktif_soru = SoruYoneticisi.rastgele_soru_al()
	kalan_sure = float(aktif_soru.get("sure", 30))
	oyun_aktif = true
	emit_signal("soru_degisti", aktif_soru)

func cevap_gonder(cevap: String) -> void:
	if not oyun_aktif:
		return
	if mod == "online":
		oyun_aktif = false
		OnlineManager.cevap_gonder(aktif_soru, cevap)
		return
	var dogru = SoruYoneticisi.cevap_dogru_mu(aktif_soru, cevap)
	if dogru:
		var puan = SkorYoneticisi.BAZ_PUAN + int(kalan_sure * SkorYoneticisi.HIZ_CARPANI)
		SkorYoneticisi.dogru_cevap(kalan_sure)
		if mod == "zayyif_noktalar":
			SoruYoneticisi.yanlis_havuzdan_cikar(aktif_soru)
		emit_signal("mikro_feedback_dogru", puan)
		await get_tree().create_timer(DOGRU_BEKLEME).timeout
		yeni_soru_al()
	else:
		SoruYoneticisi.yanlis_cevap_ekle(aktif_soru)
		SkorYoneticisi.yanlis_cevap()
		emit_signal("mikro_feedback_yanlis", aktif_soru.get("cevap", ""))
		_can_azalt("oyuncu")

func _sure_doldu() -> void:
	oyun_aktif = false
	if mod == "online":
		OnlineManager.sure_doldu()
		return
	SoruYoneticisi.yanlis_cevap_ekle(aktif_soru)
	SkorYoneticisi.yanlis_cevap()
	emit_signal("mikro_feedback_yanlis", aktif_soru.get("cevap", ""))
	_can_azalt("oyuncu")

func _can_azalt(taraf: String) -> void:
	if taraf == "oyuncu":
		oyuncu_can -= 1
		emit_signal("can_degisti", "oyuncu", oyuncu_can)
		if oyuncu_can <= 0:
			await get_tree().create_timer(YANLIS_BEKLEME).timeout
			_oyun_bitir("rakip")
			return
	else:
		rakip_can -= 1
		emit_signal("can_degisti", "rakip", rakip_can)
		if rakip_can <= 0:
			await get_tree().create_timer(YANLIS_BEKLEME).timeout
			_oyun_bitir("oyuncu")
			return
	await get_tree().create_timer(YANLIS_BEKLEME).timeout
	oyun_aktif = true
	yeni_soru_al()

# ─── Online Mod ──────────────────────────────────────────────────

func _online_sinyalleri_bagla() -> void:
	if not OnlineManager.online_soru_geldi.is_connected(_online_soru_geldi):
		OnlineManager.online_soru_geldi.connect(_online_soru_geldi)
	if not OnlineManager.tur_sonucu.is_connected(_online_tur_sonucu):
		OnlineManager.tur_sonucu.connect(_online_tur_sonucu)
	if not OnlineManager.puan_modu_sonucu.is_connected(_puan_modu_sonucu):
		OnlineManager.puan_modu_sonucu.connect(_puan_modu_sonucu)

func _online_sinyalleri_coz() -> void:
	if OnlineManager.online_soru_geldi.is_connected(_online_soru_geldi):
		OnlineManager.online_soru_geldi.disconnect(_online_soru_geldi)
	if OnlineManager.tur_sonucu.is_connected(_online_tur_sonucu):
		OnlineManager.tur_sonucu.disconnect(_online_tur_sonucu)
	if OnlineManager.puan_modu_sonucu.is_connected(_puan_modu_sonucu):
		OnlineManager.puan_modu_sonucu.disconnect(_puan_modu_sonucu)

func _online_soru_geldi(soru: Dictionary) -> void:
	aktif_soru = soru
	kalan_sure = float(soru.get("sure", 30))
	oyun_aktif = true
	emit_signal("soru_degisti", soru)

func _online_tur_sonucu(kazanan_oyuncu_no: int) -> void:
	oyun_aktif = false
	tur_sayaci += 1
	emit_signal("tur_sayaci_guncellendi", tur_sayaci, PUAN_MODU_TUR)

	# ── Puan Modu: kendi cevabımızın doğruluğuna bakıyoruz ──────
	if online_kural == "puan":
		if OnlineManager.benim_cevabim_dogru:
			var puan = SkorYoneticisi.BAZ_PUAN + int(OnlineManager.benim_kalan_sure * SkorYoneticisi.HIZ_CARPANI)
			SkorYoneticisi.dogru_cevap(OnlineManager.benim_kalan_sure)
			emit_signal("mikro_feedback_dogru", puan)
		else:
			SkorYoneticisi.yanlis_cevap()
			emit_signal("mikro_feedback_yanlis", _dogru_cevabi_al())

		OnlineManager.bekleme_moduna_gir()
		await get_tree().create_timer(YANLIS_BEKLEME).timeout

		if tur_sayaci >= PUAN_MODU_TUR:
			OnlineManager.puan_modu_bitir(SkorYoneticisi.mevcut_skor)
		else:
			OnlineManager.bekleme_modundan_cik()
			OnlineManager.yeni_tur_baslat()
		return

	# ── Can Modu ────────────────────────────────────────────────
	var ben_kazandim = (kazanan_oyuncu_no != 0 and kazanan_oyuncu_no == OnlineManager.oyuncu_no)
	var rakip_kazandi = (kazanan_oyuncu_no != 0 and kazanan_oyuncu_no != OnlineManager.oyuncu_no)

	if ben_kazandim:
		var puan = SkorYoneticisi.BAZ_PUAN + int(kalan_sure * SkorYoneticisi.HIZ_CARPANI)
		SkorYoneticisi.dogru_cevap(kalan_sure)
		emit_signal("mikro_feedback_dogru", puan)
		rakip_can -= 1
		emit_signal("can_degisti", "rakip", rakip_can)
	elif rakip_kazandi:
		SkorYoneticisi.yanlis_cevap()
		emit_signal("mikro_feedback_yanlis", _dogru_cevabi_al())
		oyuncu_can -= 1
		emit_signal("can_degisti", "oyuncu", oyuncu_can)
	else:
		# Berabere: ikisi de yanlış — ikisi de can kaybeder
		SkorYoneticisi.yanlis_cevap()
		emit_signal("mikro_feedback_yanlis", _dogru_cevabi_al())
		oyuncu_can -= 1
		rakip_can  -= 1
		emit_signal("can_degisti", "oyuncu", oyuncu_can)
		emit_signal("can_degisti", "rakip",  rakip_can)

	OnlineManager.bekleme_moduna_gir()

	# Eş zamanlı ölüm → berabere
	if rakip_can <= 0 and oyuncu_can <= 0:
		await get_tree().create_timer(YANLIS_BEKLEME).timeout
		_oyun_bitir("berabere")
		return
	if rakip_can <= 0:
		await get_tree().create_timer(YANLIS_BEKLEME).timeout
		_oyun_bitir("oyuncu")
		return
	if oyuncu_can <= 0:
		await get_tree().create_timer(YANLIS_BEKLEME).timeout
		_oyun_bitir("rakip")
		return

	await get_tree().create_timer(YANLIS_BEKLEME).timeout
	OnlineManager.bekleme_modundan_cik()
	OnlineManager.yeni_tur_baslat()

func _dogru_cevabi_al() -> String:
	if aktif_soru.get("kategori") == "isim_sehir":
		var kabul: Array = aktif_soru.get("cevaplar", [])
		return kabul[0] if not kabul.is_empty() else "?"
	return aktif_soru.get("cevap", "")

func _puan_modu_sonucu(kazandim: bool, benim_skor: int, rakip_skor: int) -> void:
	puan_modu_rakip_skor = rakip_skor
	son_kazanan = "oyuncu" if kazandim else ("berabere" if benim_skor == rakip_skor else "rakip")
	oyun_aktif = false
	_online_sinyalleri_coz()
	OnlineManager.lobi_temizle()
	emit_signal("oyun_bitti", son_kazanan, benim_skor)

# ─── Ortak ───────────────────────────────────────────────────────

func _oyun_bitir(kazanan: String) -> void:
	son_kazanan = kazanan
	oyun_aktif  = false
	if mod == "online":
		_online_sinyalleri_coz()
		OnlineManager.lobi_temizle()
	emit_signal("oyun_bitti", kazanan, SkorYoneticisi.mevcut_skor)
