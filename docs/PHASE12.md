# Modern Farm - Phase 12 (Save, Load, Main Menu, Pause, Settings, Audio, Stamina, Polish)
Game sekarang dimulai dari MAIN MENU (scenes/ui/main_menu.tscn): NEW GAME / LOAD GAME / SETTINGS / EXIT.

Kontrol: WASD jalan | 1-8 pilih | SPACE alat / makan / pancing | E bicara / pungut / panen / tidur
         I tas | J tugas | ESC menu pause | F1 bantuan kontrol | Debug: F2 item uji, N tidur.

SIMPAN / MUAT (SaveManager, JSON: user://savegame.json)
- Otomatis setiap pagi setelah tidur, dan tombol SAVE di menu pause (ESC).
- Yang disimpan: peta & posisi player, hari/musim/jam/cuaca, Gold, stamina, isi tas, tanah olahan &
  tanaman (tahap tumbuh), friendship NPC, tugas, hewan & isi tempat pakan, pohon/batu yang sudah dipecah.
- Lokasi file di Windows: %APPDATA%\Godot\app_userdata\Modern Farm\savegame.json

MENU PAUSE (ESC): RESUME, SAVE, SETTINGS, MAIN MENU (tekan dua kali untuk konfirmasi).
SETTINGS (user://settings.cfg): volume utama/musik/efek/lingkungan, layar penuh, kecepatan waktu.

STAMINA (bilah "E" kanan bawah, maks 100)
- Cangkul 2, siram 1, Axe/Pickaxe 4, lempar pancing 4. Stamina habis = tidak bisa memakai alat.
- Makan: pilih makanan di hotbar lalu SPACE. Baguette 30, Croissant 45, Cheese 60, Coffee 20,
  Egg 15, Milk 20, Apple 15, Peach 15, Lemon 10.
- Tidur memulihkan penuh. Pingsan jam 02:00 hanya pulih setengah.

AUDIO (AudioManager): musik per peta, suara hujan saat hujan/badai, efek suara alat, langkah, toko,
tugas, memancing, UI. Lihat assets/audio/README_AUDIO.md untuk menambah file suaramu sendiri.
