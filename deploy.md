# FataBlock — Dağıtım ve Yayınlama Kılavuzu (Deployment Guide)

Bu kılavuz, FataBlock oyununun Web PWA (birincil) ve Android APK (ikincil) platformları için release sürümünün nasıl derlenip yayınlanacağını anlatmaktadır.

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

---

## 3. Google Play + Reklam (AdMob) Yayın Kontrol Listesi

### A. Bir kez yapılacaklar
1. **AdMob hesabı** aç, uygulamayı ekle (Android, paket `com.emircan.fatablock`).
   - *App ID* (`ca-app-pub-…~…`) → `android/key.properties` içine `admobAppId=` olarak yaz.
   - İki reklam birimi oluştur: **Interstitial** ve **Rewarded**.
   - Birim kimliklerini `ads.example.json` dosyasını `ads.json` olarak kopyalayıp doldur
     (git'e girmez).
2. **Keystore** üret ve `android/key.properties` doldur (README → Release signing).
   Keystore'u kaybedersen uygulamayı bir daha güncelleyemezsin; yedekle.
3. `docs/privacy-policy.md` içindeki `<…>` alanlarını doldur, herkese açık bir
   adreste yayınla (örn. GitHub Pages) ve Play Console'a gir.
4. AdMob → *Privacy & messaging* bölümünde **GDPR** mesajı oluştur (AEA/UK onay formu).
   Bunu yapmazsan o bölgelerde reklam gelmez. Ayrıca `app-ads.txt` istersen web sitene ekle.

### B. Derleme
```bash
flutter build appbundle --release --dart-define-from-file=ads.json
```
Çıktı: `build/app/outputs/bundle/release/app-release.aab` → Play Console'a yükle.
Her yeni yüklemede `pubspec.yaml` içindeki `version: 1.0.0+N` değerinde **N'yi artır**.

> Dikkat: `ads.json` veya `admobAppId` olmadan alınan derleme Google'ın TEST
> reklamlarını gösterir ve gelir getirmez. Yayın öncesi gerçek kimliklerle
> derlediğini kontrol et. Geliştirirken kendi reklamına tıklama; hesabın kapanabilir
> (test cihazı ekle veya test kimlikleriyle çalış).

### C. Play Console formları
- **Ads:** "Yes, my app contains ads".
- **Data safety:** *Device or other IDs* (Advertising ID) → toplanır, reklam amaçlı,
  Google AdMob ile paylaşılır. Başka veri toplanmıyor.
- **Target audience:** 13+ / genel kitle seç (çocuklara yönelik seçersen reklam kuralları sertleşir).
- **Content rating** anketini doldur; **Advertising ID** beyanını "Yes" yap.
- Yeni kişisel geliştirici hesaplarında üretime çıkmadan önce **kapalı test** (en az 12 test kullanıcısı, 14 gün) gerekir.
