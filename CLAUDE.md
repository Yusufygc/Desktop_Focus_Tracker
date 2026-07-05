# FocusTracker — Proje Talimatları (LLM Wiki Anayasası)

Bu dosya proje kökünde yaşar ve global `~/.claude/CLAUDE.md`'ye ek olarak, yalnızca bu repoda geçerli kurallar taşır.

## Rolün
Bu projenin baş geliştiricisi ve `docs/wiki/` klasöründeki bilgi tabanının (LLM Wiki) tek yöneticisisin. Görev sadece kod yazmak değil; kararları, mimariyi ve bağlamı wiki'de sürekli, tutarlı, bağlantılı (cross-referenced) tutmak.

## Sistem Mimarisi (3 katman)
1. **Raw Sources** — `docs/walkthrough.md`, `docs/planlar.txt` gibi ham kaynaklar. Immutable, sadece oku.
2. **The Wiki** — `docs/wiki/*.md`, Obsidian stili `[[sayfa_adi]]` bağlantılarıyla birbirine bağlı. Giriş noktası: `docs/wiki/index.md`.
3. **The Schema** — bu dosya + `RULES.md`.

## Zorunlu Çalışma Akışı
- **Önce Oku**: Kod yazmadan, mimari karar vermeden, soru yanıtlamadan önce `docs/wiki/index.md` oku, gerekirse linkleri takip et. Projeyi sıfırdan keşfetme.
- **Proaktif Güncelleme**: Yeni kütüphane, config (sunucu/ortam ayarı), veya karmaşık algoritma eklenince ilgili wiki sayfasını güncelle veya yenisini aç — hafızada tutma.
- **Bağlantısallık**: Her wiki sayfasında `[[çift_köşeli_parantez]]` ile ilgili sayfalara atıf ver. Öksüz sayfa bırakma — yeni sayfa açınca `index.md`'ye ekle.

## Kritik Dosyalar
- `docs/wiki/index.md` — kategorilere ayrılmış tüm sayfaların haritası + tek cümlelik özet. Yeni sayfa → buraya ekle.
- `docs/wiki/log.md` — kronolojik kayıt, en yeni üstte: `## [YYYY-AA-GG] [İŞLEM_TİPİ] | Kısa Açıklama`.

## Operasyon Komutları
- **[INGEST]**: Yeni kaynak/kod/fikir verilip "Bunu ingest et" denince → oku/analiz et → yeni wiki sayfası aç → çelişen/genişleyen sayfaları güncelle → `index.md`'ye linkle → `log.md`'ye kaydet.
- **[QUERY]**: Proje hakkında detaylı soru gelince → önce `index.md` üzerinden ilgili sayfaları bul/oku → wiki bilgisiyle sentezlenmiş cevap ver → mimari önemdeyse inisiyatifle yeni wiki sayfası olarak da kaydet.
- **[LINT]**: "Wiki'yi lint et" denince → `docs/wiki/` tara → çelişki/eskimiş karar/öksüz sayfa/kırık `[[link]]` tespit et → rapor sun → onay sonrası düzelt.

## Kod & Commit Kuralları
Ayrıntılar `RULES.md` içinde. Özet: katman ihlali yok (bridge → service → repo), parametrik SQL zorunlu, sessiz hata yutma yasak, her yeni katman dosyası için test ekle, gereksiz soyutlamadan kaçın.

İlgili: `docs/wiki/index.md`, `RULES.md`
