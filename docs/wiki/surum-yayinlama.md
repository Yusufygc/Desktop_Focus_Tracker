# Sürüm Yayınlama Süreci

## Genel Bakış

Yeni sürüm **etiket (tag)** ile yayınlanır: `vX.Y.Z` etiketi push edilince GitHub Actions testleri koşar, uygulamayı ve Inno kurulum dosyasını derler ve GitHub Releases'e yükler.
Kurulu uygulamalar açılışta bu yayını görüp otomatik güncelleme teklif eder ([[guncelleme-sistemi]]).

İlgili sayfalar: [[exe-dagitim-rehberi]], [[guncelleme-sistemi]], [[index]], [[log]].

---

## 1. Sürüm Numaralandırması

- **Biçim:** `MAJOR.MINOR.PATCH` (örn. `1.1.0`). Etiketin başına `v` konur (`v1.1.0`).
- **Sayısal Karşılaştırma:** Güncelleyici yalnızca bu üç sayılı biçimi tanır ve sayısal karşılaştırır (`1.10.0 > 1.9.0`). `-rc1` gibi ön sürümler yok sayılır.
- **Tek Kaynak:** `app/version.py` (`__version__`, `RELEASE_REPO`). README rozeti `tools/release.py` ile aynı değere çekilir; elle düzenlenmez (`tests/test_release_packaging.py` tutarlılığı denetler).
- **Sabit PE Kaynağı:** Exe'nin Windows sürüm kaynağı (`packaging/launcher_version_info.txt`) **bilerek yükseltilmez** (kararlı exe mimarisi, [[exe-dagitim-rehberi]]); ürün sürümü kurulum dosyasında (`FocusTracker-Setup-{#AppVersion}`), Inno kaydında ve uygulama içinde görünür. Inno betiği sürümü `build_installer.py` üzerinden `/DAppVersion` ile alır.
- **Artış Kuralı:** 
  - Hata düzeltme $\rightarrow$ PATCH (`1.0.1`)
  - Yeni özellik $\rightarrow$ MINOR (`1.1.0`)
  - Geriye dönük uyumsuz veri / DB şema değişikliği $\rightarrow$ MAJOR (`2.0.0`)

---

## 2. Yayın Adımları

Ön koşul: Yayınlanacak commit'te yerel testler yeşil (`pytest`), çalışma ağacı temiz, dal `main`.

```powershell
python tools/release.py 1.1.0         # sürümü yükseltir, "chore(release): v1.1.0" commit'i atar, v1.1.0 etiketini oluşturur (itmez)
git push origin main
git push origin v1.1.0                # --follow-tags KULLANMA: hafif etiketleri göndermez, etiketi doğrudan it
gh run watch                          # Release iş akışını izle
gh release view v1.1.0                # yayın, kurulum dosyası ve .sha256 oluştu mu doğrula
```

Release iş akışı (`.github/workflows/release.yml`) sırayla şunları yapar:
1. Etiket (`v1.1.0`) ile `app/version.py` aynı değilse **iş akışı durur** (`tools/release.py --check-tag`).
2. `unittest` koşar; kırmızıysa yayın yapılmaz.
3. `python build_installer.py`: PyInstaller `--onedir` ile uygulamayı derler, **exe özetini onaylanmışla (`packaging/launcher.sha256`) karşılaştırır, farklıysa yayın durur**, Inno Setup ile `FocusTracker-Setup-X.Y.Z.exe` dosyasını derler ve `.sha256` yazar.
4. `gh release create`: Kurulum dosyası ve `.sha256` GitHub Releases'e yüklenir; sürüm notları otomatik oluşturulur.

---

## 3. Kontrol Listesi

- [ ] Testler yeşil: `python -m pytest -q` yerelde geçiyor (258/258).
- [ ] Davranış değişikliği varsa `README.md` ve ilgili wiki sayfası güncel.
- [ ] `tools/release.py` çalıştırıldı, `app/version.py` ve README rozeti aynı sürümde.
- [ ] Exe özeti onaylananla aynı (CI günlüğünde "Kararlı exe özeti onaylananla aynı"); değilse yayın durmuştur: nedeni araştır, bilerek değiştirdiysen [[exe-dagitim-rehberi]].
- [ ] Etiket sürümle birebir aynı (`v` + `__version__`).
- [ ] Release iş akışı yeşil, `gh release view` kurulum dosyasını ve `.sha256` dosyasını gösteriyor.
- [ ] Yayınlanan dosya indirilip bu makinede denendi ([[exe-dagitim-rehberi]]: CI'da derlenen dosya yerelde denenmemiş dosyadır).

---

## 4. Hata ve Geri Alma

| Durum | Ne Yapılır |
|---|---|
| **Etiket ile `__version__` farklı, iş akışı durdu** | Yayın oluşmadı. Sürümü düzelt, commit et, etiketi yeni commit'e taşı: `git tag -f vX.Y.Z` ve `git push -f origin vX.Y.Z`. |
| **Derleme adımı düştü (yayın yok)** | Sebebi düzelt, etiketi aynı yolla taşı. Yayın oluşmadığı için kimse etkilenmez. |
| **Yayın oluştu ama sürüm hatalı** | Etiketi taşıma. Yeni PATCH sürümü çıkar. Acilse `gh release delete vX.Y.Z --cleanup-tag`: güncelleyici `latest` yayına baktığından önceki sürüm tekrar "son sürüm" olur. |
| **`git push --follow-tags` etiketi göndermedi** | Hafif etiketler gitmez; `git push origin vX.Y.Z` ile ayrıca gönder (`tools/release.py` ek açıklamalı etiket oluşturur). |
| **Kurulu kullanıcıda güncelleme başlamadı** | `%TEMP%\FocusTrackerUpdate\install.log` (sessiz kurulum hata göstermez, neden orada yazar). |

---

## 5. Güvenlik ve Sınırlar

- Yayın, tüm kurulu kullanıcılara güncelleme penceresi çıkarır. **Yapay zekâ asistanları kullanıcının açık isteği olmadan etiket oluşturmaz ve push etmez.**
- İndirme adresi yalnızca bu deponun `releases/download/` yolu olabilir; boyut ve SHA-256 özeti doğrulanır, özet yoksa güncelleme reddedilir. Bu kontroller kaldırılmaz.
- Kurulum dosyası **imzasızdır** (karar: imzalama yapılmıyor); Windows SmartScreen uyarısı ve Akıllı Uygulama Denetimi engeli olabilir ([[exe-dagitim-rehberi]]).
- Yalnızca Windows.
