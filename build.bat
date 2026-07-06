@echo off
echo FocusTracker Derleniyor...

:: PyInstaller ile projeyi exe'ye cevirme komutu
:: --noconfirm: Var olan build/dist klasorlerinin uzerine yazar
:: --windowed: Konsol penceresini gizler (virus uyarisini engellemeye yardimci olur)
:: --icon: Uygulama ikonu
:: --add-data: QML dosyalari ve ikonlarin exe icine dahil edilmesi

pyinstaller --noconfirm --windowed --icon="icons\256_converted.ico" --add-data="app;app/" --add-data="icons;icons/" main.py

echo.
echo Derleme tamamlandi! Exe dosyasi 'dist\main' klasorunun icinde yer almaktadir.
pause
