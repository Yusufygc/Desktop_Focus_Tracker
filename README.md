# FocusTracker

FocusTracker, Pomodoro tekniği ve derin odaklanma (deep work) pratiklerini temel alarak tasarlanmış, **modern ve şık bir arayüze** sahip bir masaüstü zaman yönetimi uygulamasıdır. PySide6 (Python) ve QML (Qt Quick) teknolojileri kullanılarak performans ve görsellik ön planda tutularak geliştirilmiştir.

Uygulama temel olarak şu felsefeye dayanır: *Sadece ne kadar çalıştığınızı değil, nasıl çalıştığınızı (ne kadar bölündüğünüzü) de ölçmek.*

---

## 🌟 Öne Çıkan Özellikler

### 1. Modern ve Akıcı Kullanıcı Arayüzü (QML)
- Karanlık tema (Dark Mode) öncelikli, modern renk paleti.
- Akıcı geçiş animasyonları, durum bildirimleri ve pürüzsüz grafikler.
- Her menüye erişim sağlayan minimal bir yan gezinme çubuğu (Sidebar).

### 2. Gelişmiş Zamanlayıcı (Timer & Pomodoro)
- **Esnek Kronometre Modu:** Önceden belirlediğiniz bir süre yoksa kronometre gibi sayarak ne kadar çalıştığınızı takip eder.
- **Pomodoro Modu:** "Katı Pomodoro Modu"nu aktif ederek (25 dk Odak, 5 dk Mola, vb.) disiplinli bir döngüde çalışmanızı sağlar.
- **Zaman Önayarları (Presets):** Sık kullandığınız süreleri (15, 25, 45, 90 dakika vb.) kaydedip tek tıkla seans başlatabilirsiniz.

### 3. "Daima Üstte" Mini Pencere Modu (PiP)
- Ana pencere dikkatinizi dağıtıyorsa **Mini Moda** geçebilirsiniz.
- Ekranınızın bir köşesinde "Daima Üstte (Always on Top)" duran bu ufak widget üzerinden; seansı duraklatabilir, sürdürebilir veya bitirebilirsiniz.

### 4. Odak Bozulması Takibi (Distraction Tracking)
- Çalışırken telefonunuz mu çaldı? Birisi size seslenip dikkatinizi mi dağıttı?
- Ana ekrandan veya odak panelinden anında **Odak Bozuldu** butonuna tıklayarak (örn: "Telefon", "Gürültü") dikkatinizin neden dağıldığını not alabilirsiniz.

### 5. Kategori ve Konu / Proje Yönetimi
- **Konu Yönetimi:** Odaklandığınız alanı seçin (Matematik, Tasarım, Yazılım Mimarisi, vb.) ve her konuya özel bir renk atayın.
- **Kategori Yönetimi:** Odak bozan etmenleri (Telefon, Sosyal Medya, Hayal Kurma, vb.) kendi çalışma tarzınıza göre özelleştirin.

### 6. Detaylı Analiz ve İstatistikler
- Uygulama, kayıtlı seanslarınızı analiz eder ve görsel istatistikler sunar:
  - **Dairesel Grafik (Donut Chart):** Hangi konulara / projelere ne kadar vakit ayırdınız?
  - **Çizgi Grafik (Line Chart):** Son 7 günün günlük odaklanma (dakika) seyri.
  - **Odak Kalitesi:** Toplam odak süreniz ve odak bozulma oranınıza göre hesaplanan başarı oranları.

---

## 🚀 Kurulum ve Çalıştırma

### A) Geliştirici Ortamı Kurulumu

Eğer projeyi kaynak kodundan çalıştırmak veya üzerinde geliştirme yapmak istiyorsanız:

1. **Projeyi Klonlayın:**
   ```bash
   git clone https://github.com/Yusufygc/Desktop_Focus_Tracker.git
   cd Desktop_Focus_Tracker
   ```
2. **Gerekli Kütüphaneleri Yükleyin:**
   Python 3.9+ kullanılması tavsiye edilir.
   ```bash
   pip install -r requirements.txt
   ```
3. **Uygulamayı Çalıştırın:**
   ```bash
   python main.py
   ```

### B) Tek Tıkla Kurulum (.exe Oluşturma)

Eğer projeyi bitmiş bir Windows kurulum dosyası (Installer) haline getirmek istiyorsanız:

1. **PyInstaller ile Derleme:**
   ```bash
   pyinstaller focustracker.spec
   ```
   Bu işlem, PySide6 kütüphanelerini ve uygulamanızı toplayarak `dist/FocusTracker` adında bağımsız bir klasör oluşturacaktır.

2. **Inno Setup ile Kurulum Sihirbazı (Installer) Hazırlama:**
   - Sisteminizde [Inno Setup 6](https://jrsoftware.org/isinfo.php) yüklü olmalıdır.
   - Komut satırından derlemek için (ISCC Path ayarlıysa):
     ```bash
     iscc installer.iss
     ```
   - İşlem bittiğinde `Output/` klasörü içerisinde `FocusTracker_Setup.exe` oluşacaktır. Bu dosyayı arkadaşlarınızla paylaşabilir veya kendi sisteminize bir profesyonel uygulama gibi (Masaüstü kısayolu, Başlat menüsü eklemeleri vb.) kurabilirsiniz.

---

## 📂 Proje Mimarisi (Kısaca)

- **`app/core/`**: Veritabanı (SQLite), model (Session, Distraction) tanımları ve logger.
- **`app/repositories/`**: Veritabanı sorgularının (CRUD işlemleri) yapıldığı katman.
- **`app/services/`**: İş mantığının (Business Logic) yer aldığı katman.
- **`app/bridge/`**: Python tarafındaki servislerin, QML tarafına açılmasını sağlayan (QmlElement) iletişim katmanı.
- **`app/ui/qml/`**: Tamamen QML diliyle yazılmış modern bileşenler (Components), sayfalar ve ana tasarım.

---

