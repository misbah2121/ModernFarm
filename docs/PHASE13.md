# Modern Farm - Phase 13 (Mobile Controls + Android)

KONTROL SENTUH (muncul otomatis di HP / layar sentuh)
- Kiri bawah : joystick virtual (geser = jalan; atas/bawah juga memilih pilihan dialog).
- Tombol A   : pakai item terpilih (alat / makan / pancing). Tahan A saat mini game memancing.
- Tombol B   : bicara / panen / pungut / tidur / buka toko (sama dengan E).
- Hotbar     : ketuk slot untuk memilih item (pengganti 1-8).
- TAS / TUGAS / MENU (kanan atas): sama dengan I / J / ESC. MENU juga menutup tas, toko, dan daftar tugas.
- Dialog     : ketuk kotak dialog untuk lanjut, ketuk pilihan untuk memilih.
- Tas & toko : ketuk = klik kiri (ambil / taruh / beli 1 / jual 1).
Settings > Kontrol sentuh: Otomatis (HP / layar sentuh) | Selalu (untuk mencoba di PC dengan mouse) | Mati.

PENGATURAN PROJECT YANG DITAMBAHKAN
- display/window/handheld/orientation = Sensor Landscape
- rendering/textures/vram_compression/import_etc2_astc = On (wajib untuk Android)
- input_devices/pointing/emulate_touch_from_mouse = On (agar kontrol sentuh bisa dicoba dengan mouse)
- export_presets.cfg: preset "Android" (package com.modernfarm.game, arm64 + armv7, hasil: build/ModernFarm.apk)

EXPORT APK SENDIRI (Godot 4.5)
1. Install JDK 17 dan Android SDK (lewat Android Studio > SDK Manager: Platform-Tools, Build-Tools,
   SDK Platform, Command-line Tools).
2. Editor > Manage Export Templates > Download and Install.
3. Editor > Editor Settings > Export > Android: isi Java SDK Path dan Android SDK Path.
   (Debug keystore biasanya dibuat otomatis oleh Godot.)
4. Project > Export > pilih preset "Android" > Export Project > simpan ke build/ModernFarm.apk.
   Atau sambungkan HP (USB debugging aktif) lalu klik ikon Android di kanan atas editor (one-click deploy).

CATATAN
- APK debug yang dikirim bersama phase ini ditandatangani dengan debug key milik build Claude.
  Jika nanti kamu meng-install APK hasil export sendiri, uninstall versi lama dulu (tanda tangan berbeda).
- Lisensi asset Modern Farm melarang menyebarkan asset. APK ini untuk dipakai sendiri; jangan diunggah ke publik.
