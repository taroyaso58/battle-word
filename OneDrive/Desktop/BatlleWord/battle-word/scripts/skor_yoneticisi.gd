extends Node

const KAYIT_DOSYASI = "user://skor.json"
const BAZ_PUAN := 100
const HIZ_CARPANI := 3

var mevcut_skor: int = 0
var en_yuksek_skor: int = 0
var toplam_dogru: int = 0
var toplam_yanlis: int = 0

func _ready() -> void:
	yukle()

func dogru_cevap(kalan_sure: float) -> void:
	toplam_dogru += 1
	var bonus = int(kalan_sure * HIZ_CARPANI)
	_skor_ekle(BAZ_PUAN + bonus)

func yanlis_cevap() -> void:
	toplam_yanlis += 1

func _skor_ekle(puan: int) -> void:
	mevcut_skor += puan
	if mevcut_skor > en_yuksek_skor:
		en_yuksek_skor = mevcut_skor
		kaydet()

func reset() -> void:
	mevcut_skor = 0
	toplam_dogru = 0
	toplam_yanlis = 0

func kaydet() -> void:
	var dosya = FileAccess.open(KAYIT_DOSYASI, FileAccess.WRITE)
	if dosya:
		dosya.store_string(JSON.stringify({"en_yuksek_skor": en_yuksek_skor}))
		dosya.close()

func yukle() -> void:
	var dosya = FileAccess.open(KAYIT_DOSYASI, FileAccess.READ)
	if dosya:
		var json = JSON.new()
		if json.parse(dosya.get_as_text()) == OK:
			en_yuksek_skor = json.get_data().get("en_yuksek_skor", 0)
		dosya.close()
