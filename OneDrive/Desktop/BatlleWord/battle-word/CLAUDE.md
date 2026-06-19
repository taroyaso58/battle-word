# CLAUDE.md — Kelime Savaşı (Türkçe Kelime Oyunu)

Bu dosya Claude Code'un her oturumda okuduğu ana yapılandırma dosyasıdır.
Projeyle ilgili her kararı buraya yaz — oturum başında bağlam kaybetme.

---

## Proje Özeti

**Oyun adı:** Kelime Savaşı *(değiştirilebilir)*
**Tür:** Türkçe kelime bilme oyunu
**Platform:** Android (öncelikli) → Web (HTML5) → sonraki aşama
**Geliştirme aracı:** Godot 4.x + GDScript
**Online altyapı:** Firebase Realtime Database *(karar aşamasında, değişebilir)*

---

## Oyun Modları

### 1. Online 1v1 Modu
- 2 oyuncu gerçek zamanlı olarak eşleşir
- Her turda her iki oyuncuya **aynı soru** gösterilir
- Kim önce doğru cevap verirse rakibinden **1 can alır**
- Başlangıç canı: **3 can**
- 0 cana düşen oyuncu elenir
- Eşleştirme: hızlı eşleş (rastgele) veya oda kodu ile arkadaşa davet

### 2. Solo Mod
- Oyuncu zamana karşı oynuyor
- Yanlış cevap → 1 can gider (3 canla başlar)
- Doğru cevap hızına göre bonus puan
- Kişisel en yüksek skor kaydedilir (Godot SaveGame)
- Günlük görev / rozet sistemi (retention için — ileriki aşama)

---

## Soru Sistemi

### Kategoriler (4 karma tip)
Sorular her turda bu 4 kategoriden **rastgele** seçilir:

| Kategori | Açıklama | Örnek |
|----------|----------|-------|
| **Tanım** | Kelime verilir → tanımı sor, veya tanım verilir → kelimeyi sor | "Gündüzleri uyuyan..." → Yarasa |
| **Anagram** | Harfleri karışık verilir → doğru kelimeyi bul | "AKRNI" → KARIM değil, KARIM → ... |
| **Hangman** | Boşluklu kelime → harf harf tahmin | "_ A _ A _" → KARAR |
| **İsim-Şehir** | Kategori verilir → o kategoriden kelime yaz | "Hayvan — H harfi" → Horoz |

### Soru Havuzu
- **Kaynak:** TDK Sözlük API (sozluk.gov.tr)
- **Format:** JSON dosyaları, `data/questions/` klasöründe
- **Zorluk:** Kolay / Orta / Zor etiketli
- **Minimum:** Her kategoriden 100 soru = toplam 400+ soru ile başla
- **Dil:** Sadece Türkçe

### JSON Soru Formatı
```json
{
  "id": "tanim_001",
  "kategori": "tanim",
  "zorluk": "orta",
  "soru": "Geceleri uçan, mağaralarda yaşayan memeli hayvan",
  "cevap": "yarasa",
  "ipucu": "Y harfi ile başlar",
  "sure": 30
}
```

---

## Teknik Mimari

### Godot Proje Yapısı
```
proje-koku/
├── CLAUDE.md                  ← Bu dosya
├── project.godot
├── scenes/
│   ├── main_menu.tscn
│   ├── mod_secimi.tscn
│   ├── oyun_ekrani.tscn       ← Ana oyun sahnesi
│   ├── sonuc_ekrani.tscn
│   └── ui/                    ← Tekrar kullanılan UI bileşenleri
├── scripts/
│   ├── game_manager.gd        ← Oyun döngüsü kontrolcüsü
│   ├── soru_yoneticisi.gd     ← JSON'dan soru yükleme ve seçme
│   ├── can_sistemi.gd         ← Can takibi
│   ├── online_manager.gd      ← Firebase / online bağlantı
│   ├── skor_yoneticisi.gd     ← Puan ve kayıt
│   └── ui/                    ← UI script'leri
├── assets/
│   ├── fonts/                 ← Türkçe karakter destekli fontlar
│   ├── icons/                 ← Uygulama ikonu (512x512px dahil)
│   ├── sounds/                ← Ses efektleri
│   └── images/                ← UI görselleri (Canva export)
├── data/
│   └── questions/
│       ├── tanim.json
│       ├── anagram.json
│       ├── hangman.json
│       └── isim_sehir.json
└── android/                   ← Android build dosyaları (otomatik oluşur)
```

### Temel Node Hiyerarşisi (Oyun Ekranı)
```
OyunEkrani (Node2D)
├── GameManager (Node) ← game_manager.gd
├── UI (CanvasLayer)
│   ├── SoruAlani (VBoxContainer)
│   │   ├── KategoriEtiketi (Label)
│   │   ├── SoruMetni (RichTextLabel)
│   │   └── CevapInput (LineEdit)
│   ├── CanGostergesi (HBoxContainer)
│   │   ├── OyuncuCanlar (HBoxContainer)  ← 3x kalp ikonu
│   │   └── RakipCanlar (HBoxContainer)   ← 1v1 modda görünür
│   └── SureGostergesi (ProgressBar)
└── OnlineKatman (Node) ← online_manager.gd (1v1 modda aktif)
```

---

## Öğrenme Mekanizması

### Yanlış Cevap Akışı (Maç İçi)
- Yanlış cevapta cevap kutusu kırmızıya döner
- **2 saniye** "Doğrusu: [kelime]" gösterilir → oyun otomatik devam eder
- Kelime arka planda oyuncunun **Zayıf Noktalar havuzuna** eklenir
- Maç akışı en fazla 2 saniye kesilir, sıkıcı hale getirmez

### Zayıf Noktalar Modu (Solo Mod Alt Modu)
- Solo mod içinde "Zayıf Noktalarını Çalış" seçeneği
- Daha önce yanlış cevaplanan kelimelerden otomatik quiz oluşturulur
- Oyuncu kendi isteğiyle girer — maç sonu zorlanmaz, hazır olduğunda çalışır
- Havuz Godot SaveGame ile cihazda saklanır (Firebase gerektirmez, çevrimdışı çalışır)
- Havuz 50 kelimeyi aştığında en eski eklenenler düşer (liste yönetilebilir kalır)

### Tasarım Notu
Maç sonu ekranı yalnızca kazanma/kaybetme özeti gösterir.
Yanlış kelime listesi maç sonuna **eklenmez** — kullanıcı o anda öğrenmeye hazır değildir.

---

## Kodlama Kuralları

### GDScript Standartları
- **Dil:** GDScript (C# kullanma)
- **Godot sürümü:** 4.x API kullan, Godot 3.x syntax'ı KULLANMA
- **Değişken adları:** Türkçe (okunabilirlik için) veya İngilizce — tutarlı ol
- **Sinyaller:** Node'lar arası iletişimde her zaman signal kullan, direkt referans verme
- **Singleton'lar:** GameManager, SoruYoneticisi, SkorYoneticisi autoload olarak tanımla
- **Sabit değerler:** `const` ile tanımla, magic number kullanma

### Yapılmaması Gerekenler
- Python idiomları kullanma — bu GDScript, Python değil
- Godot 3.x `onready` yerine Godot 4.x `@onready` kullan
- `$NodeAdi` yerine mümkünse `@export` veya signal tercih et
- Sahneler arası direkt script referansı verme — sinyal veya autoload kullan

### Örnek Doğru GDScript (Godot 4.x)
```gdscript
extends Node

signal soru_cevaplandi(dogru: bool)

@onready var soru_metni: Label = $UI/SoruAlani/SoruMetni
@export var sure: float = 30.0

var aktif_soru: Dictionary = {}

func _ready() -> void:
    yeni_soru_yukle()

func yeni_soru_yukle() -> void:
    aktif_soru = SoruYoneticisi.rastgele_soru_al()
    soru_metni.text = aktif_soru.soru
```

---

## Online Altyapı (Firebase)

### Mimari Karar
Kelime oyunu gerçek zamanlı aksiyon değil — 500ms gecikme tolere edilebilir.
Bu yüzden Firebase Realtime Database yeterli (Nakama veya özel sunucu gerekmez).

### Firebase Veri Yapısı
```
firebase-root/
├── lobbies/
│   └── {lobby_id}/
│       ├── oyuncu1: "uid_1"
│       ├── oyuncu2: "uid_2"
│       ├── durum: "bekliyor" | "oynuyor" | "bitti"
│       └── aktif_soru_id: "tanim_042"
├── oyunlar/
│   └── {oyun_id}/
│       ├── soru_id: "tanim_042"
│       ├── oyuncu1_cevap: { cevap: "yarasa", timestamp: 1234567890 }
│       ├── oyuncu2_cevap: { cevap: "yarasa", timestamp: 1234567895 }
│       └── kazanan: "oyuncu1"
└── kullanicilar/
    └── {uid}/
        ├── kullanici_adi: "Ahmet"
        ├── can: 3
        └── toplam_skor: 1250
```

### Kritik Kural: Timestamp Sunucuda Tutulmalı
Kim önce cevapladı kararını **client'ta verme** — hile açığı olur.
Firebase Server Timestamp kullan: `ServerValue.TIMESTAMP`

### Bağlantı Kopması
- Oyuncu bağlantıyı keserse: 30 saniyelik yeniden bağlanma penceresi
- 30 saniye dolunca: rakip kazanır, oyun biter
- Firebase `onDisconnect()` hook ile uygula

---

## Android Export Ayarları

### Zorunlu Ayarlar
- **Paket adı:** `com.ADINSOYADIN.kelimesavasi` *(kendi adını yaz)*
- **Min SDK:** 24 (Android 7.0+)
- **Target SDK:** En güncel (34+)
- **Mimari:** arm64-v8a zorunlu, armeabi-v7a opsiyonel
- **Export formatı:** AAB (APK değil — Play Store AAB istiyor)
- **Keystore:** `android/release.keystore` *(ASLA git'e commit etme!)*

### .gitignore'a Ekle
```
android/release.keystore
export_presets.cfg
```

### Uygulama İkonu Boyutları
- 512×512px → Play Store
- 192×192px → xxxhdpi
- 144×144px → xxhdpi
- 96×96px → xhdpi

---

## Tasarım Araçları ve Yönergeler

### Araç Dağılımı
| Araç | Kullanım Alanı |
|------|---------------|
| **Canva** (MCP entegrasyonu mevcut) | Uygulama ikonu, feature graphic, Play Store görselleri, sosyal medya |
| **Figma** (web, ücretsiz) | In-game ekran tasarımı, UI component sistemi, ekran akış diyagramı |
| **Suno AI** (suno.com) | Arka plan müziği üretimi (metin prompt ile) |
| **Pixabay / Freesound.org** | Ses efektleri — ücretsiz, Creative Commons lisanslı |

### Suno AI Kullanımı
- Metin prompt ile özel oyun müziği üretilir
- Örnek prompt: `"cheerful upbeat Turkish word game background music, light and non-distracting, loop-friendly"`
- **Önemli:** Play Store yayını öncesinde ticari lisans (Pro plan) alınmalı
- Üretilen `.mp3` → `assets/sounds/muzik/` klasörüne ekle

### Ses Efektleri Listesi (Gerekli)
- `dogru_cevap.wav` — kısa, pozitif tını
- `yanlis_cevap.wav` — kısa, nötr (sinir bozucu olmasın)
- `buton_tikla.wav` — hafif tık
- `sure_bitti.wav` — alarm tarzı, kısa
- `mac_kazanildi.wav` — kısa zafer fanfarı
- `mac_kaybedildi.wav` — kısa düşen ton

### UI Tasarım İlkeleri
- **Font:** Türkçe karakter destekli, büyük ve okunaklı (min 18sp metin, 24sp soru)
- **Renk paleti:** Koyu arka plan + parlak vurgu rengi (mavi/sarı kontrast önerilir)
- **Dokunmatik hedefler:** Min 48×48dp (mobil erişilebilirlik)
- **Animasyon:** Yanlış cevap → kırmızı flash (0.2s), doğru → yeşil flash (0.2s)
- **Sadelik:** Oyun ekranında dikkat dağıtacak dekorasyon olmasın — soru, cevap, can, süre

---

## Google Play Yayın Süreci

### Gerekli Görseller (Canva'da Hazırla)
| Görsel | Boyut |
|--------|-------|
| Uygulama ikonu | 512×512px |
| Feature graphic | 1024×500px |
| Telefon ekran görüntüsü (min 2) | 1080×1920px |

### Yayın Adımları
1. Google Play Console hesabı aç (play.google.com/console) — $25 bir kerelik
2. Yeni uygulama oluştur → Oyun kategorisi seç
3. Store listing doldur (Türkçe + İngilizce)
4. **Kapalı test:** Kişisel hesaplar için zorunlu — 12 test kullanıcısı, 14 gün
5. İçerik derecelendirmesi doldur (IARC anketi)
6. AAB dosyasını yükle → İncelemeye gönder
7. İnceleme: birkaç saat – birkaç gün

---

## Claude Code için Skill'ler

### Kurulu Olması Gereken Skill'ler
```bash
# Godot 4.x özel skill (GDScript API referansı dahil)
/plugin marketplace add Randroids-Dojo/Godot-Claude-Skills
/plugin install godot

# Opsiyonel: Tam stüdyo hiyerarşisi
# github.com/Donchitos/Claude-Code-Game-Studios
```

### Claude Code'a Görev Verme Örnekleri
```
"CLAUDE.md'yi oku, oyun döngüsünü game_manager.gd'ye uygula"
"Tanım kategorisi için 20 yeni soru JSON formatında oluştur"
"Canva tasarımıma göre oyun_ekrani.tscn sahnesini kur"
"Firebase bağlantısını online_manager.gd'ye ekle, timestamp sunucuda tutulsun"
"Android AAB export için export_presets.cfg'yi yapılandır"
```

---

## Geliştirme Aşamaları

- [x] **Aşama 0:** Yol haritası ve mimari kararlar *(bu dosya)*
- [ ] **Aşama 1:** Godot proje yapısı + soru havuzu JSON (min 400 soru, İsim-Şehir cevap listesi tanımlı)
- [ ] **Aşama 1.5:** UI tasarımı — Figma ekran akışı + Canva store görselleri + Suno müzik üretimi
- [ ] **Aşama 2:** Solo mod — soru döngüsü + can sistemi + mikro feedback (2s) + Zayıf Noktalar havuzu
- [ ] **Aşama 3:** UI uygulama (Figma tasarımından Godot'a, ses efektleri entegrasyonu)
- [ ] **Aşama 4:** Online 1v1 — Firebase entegrasyonu
- [ ] **Aşama 5:** Android export + gerçek cihaz testi
- [ ] **Aşama 6:** Google Play kapalı test (14 gün)
- [ ] **Aşama 7:** Production yayını

---

## Notlar ve Kararlar

- Türkçe karakter desteği için Godot'ta UTF-8 font şart — varsayılan font Türkçe'yi desteklemeyebilir
- Solo mod önce bitirilecek, online katman sonra eklenecek
- Soru havuzu Claude Code ile script yazılarak TDK API'dan otomatik doldurulacak
- Web (HTML5) export — Android bittikten sonra, aynı proje dosyasından

*Son güncelleme: Haziran 2026*