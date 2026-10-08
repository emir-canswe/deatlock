# Redbound - Yıldız Kapısı (Star Gate) ve İnteraktif Rehber (Tutorial)

Her 50 seviyede bir devreye giren **Yıldız Kapısı (Star Gate)** kilit sistemi ile ilk 3 seviye için hazırlanan **İnteraktif Rehber (Tutorial Overlay)** sistemi başarıyla entegre edildi.

---

## 🌟 1. Yıldız Sistemi ve Yıldız Kapısı (Star Gate)

### Yıldız Hesaplama Kuralı
- **3 Yıldız (⭐⭐⭐)**: İpucu kullanmadan optimal hamle sayısında bitirme (Mükemmel çözüm).
- **2 Yıldız (⭐⭐)**: İpucu kullanmadan en fazla `optimal + 2` hamlede bitirme veya ipucu ile optimal çözme.
- **1 Yıldız (⭐)**: Bölümü tamamlama.

### 50'lik Aralıklarla Yıldız Kapıları
Her 50 seviyede bir (örneğin 50 $\to$ 51, 100 $\to$ 101, 150 $\to$ 151...), bir sonraki seviye bloğuna geçmek için oyuncunun belirli bir kümülatif yıldız sayısına ulaşması gerekir:
- **51. Seviye Kapısı**: 100 ⭐ (Maksimum 150 yıldızdan)
- **101. Seviye Kapısı**: 210 ⭐ (Maksimum 300 yıldızdan)
- **151. Seviye Kapısı**: 325 ⭐ (Maksimum 450 yıldızdan)
- **201. Seviye Kapısı**: 440 ⭐ (Maksimum 600 yıldızdan)

### Arayüz ve Kullanıcı Deneyimi
1. **Bölümler Ekranı (LevelsScreen)**:
   - Başlıkta toplanan **Toplam Yıldız Sayacı** (`⭐ 84`) rozeti.
   - Çözülen her kutucuğun altında kazanılan yıldız sayısı (1, 2 veya 3 mini yıldız).
   - Yıldız yetersizliğinden kilitli olan kapı seviyesinde (örn. 51. seviye) özel **Kilit + Hedef Yıldız Rozeti** (`100⭐`).
   - Kapıya tıklandığında açılan bilgilendirme penceresi: Kalan yıldız sayısı, ilerleme çubuğu ve önceki bölümleri 3 yıldızla tekrar oynama yönlendirmesi.
2. **Kazanma Ekranı (WinSheet)**:
   - Seviye tamamlandığında 3 yıldızlı animasyonlu değerlendirme.
   - Eğer 50. seviye bitirilip 51 için yıldız yetersizse, bir sonraki bölüme geçmek yerine **"Yıldız Kapısı Kilitli"** uyarısı ve doğrudan **"Bölümlere Dön"** butonu sunulur.
3. **Ana Menü (ModeSelectScreen)**:
   - Hem toplanan toplam yıldızlar (`⭐`) hem de ipucu ekonomisi (`💡`) menü üst barında gösterilir.

---

## 👆 2. İlk 3 Seviye İnteraktif Rehber (Tutorial)

Oyuncuya oyun dinamiklerini adım adım öğretmek için ilk 3 seviyede rehber devreye girer:

1. **1. Seviye: "HEDEF: ÇIKIŞA ULAŞ"**
   - Kırmızı ana bloğu sağ taraftaki çıkış kapısına doğru kaydırma mantığı.
   - Kırmızı bloktan çıkış kapısına doğru kaydırma yapan animasyonlu el ikonu.
2. **2. Seviye: "ENGELLERİ TEMİZLE"**
   - Yol üstündeki engel blokları kaydırarak kırmızı bloğa yol açma mantığı.
   - Engel bloğu gösteren kaydırma animasyonu.
3. **3. Seviye: "HAREKET YÖNLERİ"**
   - Yatay blokların yalnızca yatay (sağa-sola), dikey blokların ise yalnızca dikey (yukarı-aşağı) hareket edebileceği kuralı.
4. **Akıcı Deneyim**:
   - Oyuncu ekrana dokunduğu veya bloğu kaydırmaya başladığı anda rehber akıcı bir şekilde kaybolur, oyunu asla engellemez.

---

## 📁 Değiştirilen ve Eklenen Dosyalar
- `lib/domain/star_gate.dart`: Yıldız hesabı ve kapı eşikleri lojiği.
- `lib/core/strings.dart`: Türkçe & İngilizce kapı ve rehber metinleri.
- `lib/data/progress_store.dart`: Yıldızların kalıcı olarak saklanması ve `totalStars` hesaplama.
- `lib/state/progress_controller.dart`: Kapı kilit kontrolü ve seviye tamamlama entegrasyonu.
- `lib/ui/widgets/tutorial_overlay.dart`: 1-3. seviye animasyonlu rehber bileşeni.
- `lib/ui/widgets/win_sheet.dart`: 3-yıldız gösterimi ve Yıldız Kapısı uyarı kartı.
- `lib/ui/screens/levels_screen.dart`: Yıldız sayaçları, 3-yıldız kutucukları ve kapı modal penceresi.
- `lib/ui/screens/game_screen.dart`: Rehber katmanı ve kapı geçiş kontrolü.
- `lib/ui/screens/mode_select_screen.dart`: Yıldız ve ipucu üst barı.
