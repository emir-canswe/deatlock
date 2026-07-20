# Deadlock — Dağıtım ve Yayınlama Kılavuzu (Deployment Guide)

Bu kılavuz, Deadlock oyununun Web PWA (birincil) ve Android APK (ikincil) platformları için release sürümünün nasıl derlenip yayınlanacağını anlatmaktadır.

---

## 1. Flutter Web (PWA) Yayınlama

Web sürümü, herhangi bir mağaza onayına ihtiyaç duymadan kullanıcıların telefon tarayıcısından (PWA destekli) oyunu doğrudan ana ekrana ekleyip uçak modunda dahi oynayabilmesini sağlar.

### A. Derleme Komutu
```bash
flutter build web --release --base-href /deadlock/
```

* **`--base-href` Açıklaması**: Web sunucunuzdaki alt dizin yoludur.
  - Eğer oyunu `https://kullanici.github.io/deadlock/` gibi bir GitHub Pages alt sayfasında barındırıyorsanız, `--base-href /deadlock/` olmalıdır.
  - Eğer root dizinde (örn. `https://oyun.com/`) barındırıyorsanız, `--base-href /` olmalıdır. Bu değer yanlış ayarlanırsa tarayıcı js dosyalarını bulamaz ve ekran **beyaz** kalır.

### B. Dağıtım Adımları (Hosting)

#### GitHub Pages
1. GitHub deponuzda `gh-pages` adında boş bir dal (branch) açın.
2. Derlenen `build/web/` klasöründeki tüm dosyaları bu dala yükleyin.
3. Depo ayarlarından GitHub Pages'i açıp dalı `gh-pages` olarak seçin.

#### Cloudflare Pages / Netlify
1. Deponuzu bağlayın.
2. Build command: `flutter build web --release --base-href /` (veya uygun alt dizin).
3. Publish directory: `build/web`.

### C. Renderer Tercihi ve Performans
- Tarayıcıda 60 FPS kaydırma performansı ve `CustomPainter` çizimlerinin doğruluğu için Flutter varsayılan olarak **skwasm** veya **canvaskit** kullanır.
- İlk yükleme boyutunun (payload) minimumda tutulması için build alırken otomatik optimizasyonlar uygulanır. Gzip/Brotli sıkıştırma aktif olan bir sunucuda başlangıç yükleme boyutu **~2.8 MB** civarındadır.

---

## 2. Android APK Yayınlama

Üçüncü şahıslarla doğrudan paylaşılabilir, Google Play Mağazası kapalı test süreçlerini atlayan doğrudan kurulum sürümüdür.

### A. Derleme Komutu
```bash
flutter build apk --release --split-per-abi
```
Bu komut, her işlemci mimarisi (arm64, armv7, x86) için ayrı APK'lar üretir ve boyutun cihazlarda **10 MB'ın altında** kalmasını sağlar.

- **Paylaşılacak Birincil APK**: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

### B. Kurulum Notu (Android)
APK dosyasını telefona kurarken Android güvenlik sistemi uyarı verebilir. Kurulum için:
1. İndirilen APK dosyasına dokunun.
2. Çıkan uyarıda "Ayarlar"a gidip **"Bilinmeyen kaynaklardan uygulama yüklemeye izin ver"** (Allow from this source) seçeneğini etkinleştirin.
3. Geri gelip "Yükle" butonuna dokunarak kurulumu tamamlayın.

---

## 3. Önemli Çalışma Zamanı Notları

- **Gün Dönümü (Daily Mode)**: Günlük bulmacanın seed'i yerel tarih saatine göre (`DateTime.now()`) hesaplanır. Yeni gün yerel saatle gece `00:00`'da devreye girer. Kullanıcının saat dilimi ne ise, günün değişimi de o saat dilimine göre gerçekleşir.
- **Uçak Modu (Offline)**: Service Worker, ilk ziyarette tüm oyun kaynaklarını (Nunito fontu dahil) tarayıcı önbelleğine alır. Sonraki tüm açılışlar uçak modunda dahi **1 saniyenin altında** gerçekleşir.
