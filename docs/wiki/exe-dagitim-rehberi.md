# Windows EXE Dağıtım ve Kararlı Başlatıcı Rehberi

## Bu Sayfanın Amacı

**Amaç:** İmzasız bir Windows masaüstü uygulamasını (FocusTracker) sorunsuz kurulan, Windows 11 Akıllı Uygulama Denetimi'ne (Smart App Control - SAC) takılmayan, etiketle yayınlanan ve kendini güncelleyen hâle getirmek için rehber ve gerekçe kaynağıdır.

İlgili sayfalar: [[guncelleme-sistemi]], [[surum-yayinlama]], [[architecture]], [[index]], [[log]].

Teknoloji Yığını: Python 3.10, PySide6/QML, PyInstaller 6.22.3, Inno Setup 6, GitHub Actions + GitHub Releases.

---

## 1. Hedef ve Kararlı EXE Yaklaşımı

Hedef: Son kullanıcı **kurulum dosyasını indirir, kurar ve kullanır**; sonraki sürümlerde uygulama kendi içinden güncellenir ve **beklemeden** yeniden açılır. Kod imzalama (EV/OV sertifikası ya da üçüncü taraf servis başvurusu) **yapılmaz** (imzasız dağıtım kararı).

### Kök Sorun: Akıllı Uygulama Denetimi (SAC)

Windows 11'de SAC açıksa **imzasız** her çalıştırılabilir dosya (exe, DLL, kurulum dosyası, kaldırıcı) dosya **özetine (SHA-256)** göre Microsoft'un bulut itibar kararına bırakılır.
- Karar **dosya özetine (SHA-256)** bağlıdır.
- Her derlemede yeni bir exe özeti üretilirse, SAC her yeni sürümde kullanıcı uygulamasını engelleyebilir (`OSError: [WinError 4551] Uygulama Denetimi ilkesi bu dosyayı engelledi`).
- Çözüm: **EXE'yi sürümler arasında bayt bayt aynı tutmak ("Kararlı EXE")**. Uygulama kodu exe'nin dışına çıkarılır (`_internal` altında `.pyc` dosyaları); güncellemeyle yalnızca çalıştırılabilir olmayan Python bytecode ve veri dosyaları değişir.

---

## 2. Kararlı EXE'nin Dört Ayağı

Exe'nin her derlemede bayt bayt aynı SHA-256 özetini üretmesi için 4 bileşenin tümü zorunludur:

| Parça | Yapılan İşlem | Gerekçe |
|---|---|---|
| **Sabit Giriş Betiği** | `packaging/launcher.py` yalnızca uygulamanın `main()` işlevini çağırır (3 satır). **Asla değiştirilmez.** | Giriş betiği exe'nin içine gömülür; içeriği değişirse exe özeti değişir. |
| **Modüller EXE Dışında** | PyInstaller `--debug=noarchive` bayrağı | Python modülleri exe'ye gömülmez, `_internal` altında `.pyc` olarak durur. Kod değişse de exe değişmez. |
| **Sabit Zaman Damgası** | Derlemeden hemen önce `os.environ["SOURCE_DATE_EPOCH"] = "1700000000"` | PE başlığındaki derleme zaman damgası deterministik yapılır. |
| **Sabit Sürüm Kaynağı** | `--version-file=packaging/launcher_version_info.txt` (sabit `1.0.0.0`) | Exe PE kaynağı sabit kalır; ürün sürümü Inno Setup kaydında ve uygulama UI'ında görünür. |

PyInstaller argümanları (`build_exe.py`):
```python
LAUNCHER_EPOCH = 1700000000
arguments = [
    str(root / "packaging" / "launcher.py"),
    f"--paths={root}",
    "--name=FocusTracker",
    "--onedir",
    "--windowed",
    "--clean",
    "--noconfirm",
    "--noupx",               # UPX DLL imzalarını bozar, virüs yanlış pozitifini artırır; kullanılmaz
    "--debug=noarchive",     # modüller .pyc olarak _internal altında
    f"--version-file={root / 'packaging' / 'launcher_version_info.txt'}",
    "--add-data=app;app",
    "--add-data=icons;icons",
    "--icon=icons/256_converted.ico",
]
```

### Onay Kapısı: `packaging/launcher.sha256`

Yerelde Windows'ta açıldığı doğrulanmış exe özeti `packaging/launcher.sha256` dosyasında tutulur:
- Derleme sonrası `check_launcher_hash` çalışır.
- Özet onaylananla aynıysa derleme devam eder.
- Özet farklıysa derleme **derhal durdurulur** (`sys.exit(1)`). Böylece onaysız/engellenebilecek bir exe'nin yayına çıkması engellenir.
- Bilerek yapılan değişikliklerde `python build_installer.py --update-launcher-hash` ile yeni özet onaylanır.

---

## 3. Kurulum Sihirbazı (Inno Setup 6)

Referans: `packaging/FocusTracker.iss`. Temel kurallar:
1. **Sabit AppId:** `AppId={{C8F6E025-41D7-49BA-B6A8-580F6E31C582}}` sabittir; değişirse sonraki sürüm üstüne yazmaz, ikinci bir kopya kurar.
2. **Kullanıcı Yetkisi (`PrivilegesRequired=lowest`):** Yönetici UAC onayı sormaz; `%LOCALAPPDATA%\Programs\FocusTracker` dizinine kurulur. Bu sayede uygulama içi güncelleme sessizce tamamlanır.
3. **Çalışan Uygulamayı Kapatma:** `CloseApplications=yes`, `RestartApplications=no`.
4. **Sürümlü Çıktı:** `OutputBaseFilename=FocusTracker-Setup-{#AppVersion}` (güncelleme servisi `^FocusTracker-Setup-[0-9.]+\.exe$` desenini arar).
5. **Yeniden Açma (`Check: RelaunchAfterUpdate`):** Uygulama içi güncelleme `/SILENT` ile çalışır ve kurulum sonrası uygulamayı açar; derleme denemesi `/VERYSILENT` ile çalışır ve uygulamayı açmaz.

---

## 4. Derleme ve Doğrulama Betikleri

- **`build_exe.py`:** PyInstaller'ı sabit epoch ve bayraklarla çalıştırır, hash kapısını denetler.
- **`build_verify.py`:** 
  - `launch_check`: Exe'yi başlatır (`FOCUSTRACKER_NO_UPDATE_CHECK=1` ile), 8 saniye boyunca çalışır durumda kaldığını ve SAC hatası (`WinError 4551/1260`) almadığını doğrular, sonra ağacı temiz kapatır.
  - `installer_check`: Kurulum dosyasını geçici klasöre sessizce kurar, kurulan exe'yi açıp dener, kaldırıcıyı (`unins000.exe`) çalıştırır. Gerçek sistemdeki `HKCU` kayıt defteri ve Başlat kısayolu `save_registration` / `restore_registration` ile korunur.
- **`build_installer.py`:** Tek komutla derleme: ISCC bul $\rightarrow$ `build_exe` $\rightarrow$ `launch_check` $\rightarrow$ Inno derle $\rightarrow$ `installer_check` $\rightarrow$ `.sha256` dosyası üret.

---

## 5. Yapılmaması Gerekenler

1. **Her sürümde yeni exe özeti üretmek:** SAC her sürümde yeni karar verir; güncelleme başarılı görünse de exe açılmayabilir.
2. **UPX sıkıştırması kullanmak:** Antivirüs yanlış pozitiflerini artırır ve DLL bütünlüğünü bozar.
3. **`PrivilegesRequired=admin` kullanmak:** Güncelleme sessiz çalışamaz, UAC sorar.
4. **Kullanıcı veritabanını kaldırıcıyla silmek:** `%APPDATA%\FocusTracker` altındaki `focustracker.db` kullanıcı verisidir; kaldırıcı tarafından silinmez.
5. **Kapıyı atlamak (`--no-verify`):** Onaysız exe'nin yayına gitmesine yol açar.
