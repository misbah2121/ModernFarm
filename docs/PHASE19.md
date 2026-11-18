# Phase 19: Dekorasi, Traktor, Pekerja Farm, Font Baru

## 1. Dekorasi farm (furnitur, lampu, hiasan)
- Ada 18 hiasan yang **dijual di Toko Serba Ada (Mira)**.
- **Memasang:** pegang hiasan di hotbar, lalu tekan **SPACE**. Hiasan muncul di tile depan player.
- **Mengambil lagi:** pukul dengan **Pickaxe / Axe**. Hiasan kembali ke tas.

Daftar hiasan:
- Lampu Taman (menyala otomatis 18:00–06:00, memakai PointLight2D)
- Orang-orangan Sawah
- Bangku Kayu
- Meja Kayu
- Labu Hias
- Jerami Gulung
- Tumpukan Jerami
- Peti Hias
- Kaleng Susu
- Pot Bunga
- Rumpun Bunga
- Papan Nama
- Rumah Anjing
- Sumur Batu
- Kanopi Kayu (bisa dilewati)
- Kios Kecil
- Tumpukan Papan
- Penunjuk Angin

Gambar diambil dari props asli Modern Farm. Ada dua pengecualian:
- **Lampu Taman** digambar sendiri, karena pack tidak punya lampu.
- **Pot Bunga** adalah gabungan `Pot_Empty` dan `Grass_Tufts_Flowers`.

Kategori item baru: **Dekorasi** (`ItemData.Category.DECOR`).

Catatan: **dekorasi di dalam rumah belum bisa**. Pack Modern Farm tidak punya interior rumah maupun furnitur dalam ruangan. Kalau kamu menambahkan pack LimeZu *Modern Interiors*, `InteriorMap` dan `DecorObject` bisa langsung dipakai untuk itu.

## 2. Traktor yang bisa dikendarai (upgrade tahap lanjut)
Sprite memakai `Tractor_16x16.png` asli: frame 96x96, 4 arah, animasi jalan dengan asap knalpot.

| Level | Cara | Kemampuan |
|---|---|---|
| 0 | awal | Rusak |
| 1 | Papan Farm: 2000 Gold + 5 Iron Ore | Bajak: mencangkul 3 petak di belakang traktor |
| 2 | Papan Farm: 5000 Gold + 5 Gold Ore | Bajak + Siram |

Kontrol:
- **E** di dekat traktor: naik.
- **WASD**: jalan 4 arah, lebih cepat dari jalan kaki.
- **SPACE**: ganti alat (Mati → Bajak → Bajak + Siram).
- **E** lagi: turun.

Traktor hanya mengolah lahan pertanian, tidak memakai stamina, dan tidak bisa keluar dari Farm. Posisi parkirnya ikut tersimpan.

## 3. Pekerja farm
Pekerja diatur di **Papan Farm**, yang sudah terpasang di dekat rumah. Papan Farm juga bisa dibuat lewat C (10 Wood).

| Pekerja | Lv 1 | Lv 2 (hari ke-7) | Lv 3 (hari ke-21) |
|---|---|---|---|
| **Budi**, Penyiram | siram 12 petak | siram 30 petak | siram semua |
| **Sari**, Pemanen | panen 6 | panen 15 | panen semua + pohon buah |
| **Joko**, Peternak | beli & isi pakan hewan lapar | + ambil telur/susu/wol | + elus semua hewan |

Aturan kerja:
- **Waktu:** pekerja bekerja tiap pagi.
- **Gaji:** dipotong otomatis, naik sesuai level. Kalau Gold kurang, pekerja libur. Saat hujan, Budi libur dan tidak dibayar.
- **Hasil panen dan ternak** masuk ke **Peti Kayu** di Farm. Kalau peti penuh, hasil masuk ke tas.
- **Laporan** pekerjaan muncul sebagai pesan pagi.
- **Di lahan:** pekerja terlihat berjalan dan bekerja di lahan pada siang hari. E di dekat pekerja menampilkan tugasnya.
- **Sprite:**
  - Budi memakai `Farmer_2_16x16` asli.
  - Sari dan Joko memakai versi yang sama dengan warna topi diganti.

## 4. Font baru: Pixel Game
- File: `assets/fonts/PixelGame.otf`. Lisensinya ada di `PixelGame_LICENSE.txt`: **freeware, non-commercial**. Untuk game yang dijual, kamu perlu lisensi komersial dari pembuat font.
- Font dipasang untuk seluruh game lewat **Project Settings → GUI → Theme → Custom Font**.
- Import diatur agar tetap tajam: Antialiasing = None, Hinting = None, Subpixel = Disabled.
- Font ini hanya tajam di **ukuran 16** (1 piksel font = 1 piksel layar pada jendela 2x). Karena itu semua teks memakai `UiTheme.FS` (16), dan judul besar memakai `UiTheme.FS_BIG` (32).
- Semua panel sudah dirapikan untuk font baru:
  - Panel tugas, toko, dan memancing dibuat lebih lebar atau tinggi.
  - Baris toko kini 2 baris.
  - Keterangan yang panjang dipotong dengan `UiTheme.fit()`.
  - Tombol sentuh dibuat lebih besar.
- Font ini hanya punya huruf kapital, jadi semua teks tampil KAPITAL. Angka 5 bentuknya mirip huruf S, itu memang ciri font ini.

## 5. File
Baru:
- `scripts/systems/farm_services.gd`: autoload **FarmServices** (level traktor, pekerja, ikut save).
- `scripts/vehicles/tractor.gd`
- `scripts/farming/farm_workers.gd`, `scripts/farming/farm_worker_npc.gd`
- `scripts/crafting/decor_object.gd`, `scripts/crafting/farm_board.gd`
- `scripts/ui/farm_board_panel.gd`
- `scenes/decor/*.tscn` (18 hiasan), `scenes/crafting/farm_board.tscn`
- `data/items/*` (18 hiasan + farm_board), `data/recipes/farm_board.tres`
- Asset: `objects/decor/*`, `objects/vehicles/Tractor_16x16.png`, `characters/workers/*`, `assets/fonts/*`, ikon baru di `icons/`

Diubah:
- `scenes/world/props/tractor.tscn`: sekarang memakai script Tractor dan tidak lagi masuk grup `solid_prop`.
- `player.gd`: mengemudi.
- `farm_soil.gd`: `till_quiet`, `dry_cells`, `ripe_cells`, `take_harvest`.
- `animal_manager.gd`: fungsi untuk pekerja.
- `storage_chest.gd`: `add_item`.
- `farm_map.gd`: traktor, pekerja, Papan Farm awal.
- `main.gd`, `main.tscn`: node baru `HUD/FarmBoardPanel`.
- `save_manager.gd`, `project.godot`: autoload FarmServices dan custom font.
- `item_data.gd`: kategori DECOR.
- `general_store.tres`
- `ui_theme.gd` (FS, FS_BIG, fit) dan semua panel UI.

Tidak ada Input Map baru.
