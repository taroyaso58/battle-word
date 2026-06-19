extends Node

const SORU_KLASORU = "res://data/questions/"
const KATEGORILER = ["tanim", "anagram", "hangman", "isim_sehir"]
const MAX_YANLIS_HAVUZ = 50

var soru_havuzlari: Dictionary = {}
var yanlis_havuz: Array = []

func _ready() -> void:
	_sorulari_yukle()
	_yanlis_havuzu_yukle()

func _sorulari_yukle() -> void:
	for kategori in KATEGORILER:
		var yol = SORU_KLASORU + kategori + ".json"
		var dosya = FileAccess.open(yol, FileAccess.READ)
		if dosya:
			var json = JSON.new()
			if json.parse(dosya.get_as_text()) == OK:
				soru_havuzlari[kategori] = json.get_data()
			dosya.close()

func rastgele_soru_al(zorluk: String = "") -> Dictionary:
	var kategori = KATEGORILER[randi() % KATEGORILER.size()]
	return kategoriden_soru_al(kategori, zorluk)

func kategoriden_soru_al(kategori: String, zorluk: String = "") -> Dictionary:
	if not soru_havuzlari.has(kategori):
		return {}
	var havuz: Array = soru_havuzlari[kategori].duplicate()
	if zorluk != "":
		havuz = havuz.filter(func(s): return s.get("zorluk", "") == zorluk)
	if havuz.is_empty():
		return {}
	return havuz[randi() % havuz.size()]

func cevap_dogru_mu(soru: Dictionary, verilen_cevap: String) -> bool:
	var temiz_cevap = verilen_cevap.strip_edges().to_lower()
	# İsim-şehir kategorisi için birden fazla kabul edilen cevap
	if soru.get("kategori") == "isim_sehir":
		var kabul_edilenler: Array = soru.get("cevaplar", [])
		return temiz_cevap in kabul_edilenler
	return temiz_cevap == soru.get("cevap", "").to_lower()

func yanlis_cevap_ekle(soru: Dictionary) -> void:
	# Aynı soru zaten havuzdaysa ekleme
	for mevcut in yanlis_havuz:
		if mevcut.get("id") == soru.get("id"):
			return
	yanlis_havuz.append(soru)
	# Maksimum 50 soru — eskisi düşer
	if yanlis_havuz.size() > MAX_YANLIS_HAVUZ:
		yanlis_havuz.pop_front()
	_yanlis_havuzu_kaydet()

func yanlis_havuzdan_soru_al() -> Dictionary:
	if yanlis_havuz.is_empty():
		return {}
	return yanlis_havuz[randi() % yanlis_havuz.size()]

func yanlis_havuzdan_cikar(soru: Dictionary) -> void:
	yanlis_havuz = yanlis_havuz.filter(func(s): return s.get("id") != soru.get("id"))
	_yanlis_havuzu_kaydet()

func yanlis_havuz_sayisi() -> int:
	return yanlis_havuz.size()

func id_ile_soru_al(id: String) -> Dictionary:
	for kategori in soru_havuzlari:
		for soru in soru_havuzlari[kategori]:
			if soru.get("id") == id:
				return soru
	return {}

func _yanlis_havuzu_kaydet() -> void:
	var dosya = FileAccess.open("user://yanlis_havuz.json", FileAccess.WRITE)
	if dosya:
		dosya.store_string(JSON.stringify(yanlis_havuz))
		dosya.close()

func _yanlis_havuzu_yukle() -> void:
	var dosya = FileAccess.open("user://yanlis_havuz.json", FileAccess.READ)
	if dosya:
		var json = JSON.new()
		if json.parse(dosya.get_as_text()) == OK:
			yanlis_havuz = json.get_data()
		dosya.close()
