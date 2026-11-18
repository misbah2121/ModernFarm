# UI Baru: Free Basic Pixel Art UI for RPG + World Map Scroll

## Asset yang dipakai
| Asset | Lokasi di project | Lisensi |
|---|---|---|
| Free Basic Pixel Art UI for RPG (CraftPix) | `assets/ui/rpg_ui/` (Inventory, Main_tiles, Buttons, Action_panel, Settings .png) | `assets/ui/rpg_ui/LICENSE_craftpix.txt` |
| Humble Gift - World Map Scroll v1.0 (Humble Pixel) | `assets/ui/world_map/` (frame appear/disappear dipotong ke 474x373, parts/) | `assets/ui/world_map/LICENSE_humblepixel.txt` |

Gambar tidak diubah warnanya / diperbesar. Frame gulungan hanya dipotong (crop) ke area yang berisi gambar.

## Cara kerja: `scripts/ui/ui_theme.gd`
* `UiTheme.UiSkin` = kumpulan StyleBoxTexture **9-slice** dari sheet pack:
  `window` (kertas + pita hijau), `paper`, `wood`, `header` (pita hijau), `slot`, `bar` (papan hotbar),
  `button`, `button_hover`, `button_pressed`, `button_disabled`.
* `UiTheme.build()` -> Theme untuk Control biasa (Button, OptionButton, CheckButton, HSlider,
  PanelContainer, PopupMenu, Label). Dipakai Main Menu, Pause, Settings.
* Fungsi gambar untuk panel `_draw`: `draw_window()`, `draw_slot()`, `draw_count()`, `draw_button()`, `draw_progress()`.
* Warna teks di kertas krem: `TEXT` (cokelat tua), `TEXT_DIM`, `TITLE` (di pita hijau), `ACCENT`, `PRICE`, `RED`, `GREEN`.

## Yang diganti
| UI | File |
|---|---|
| Hotbar (papan kayu + slot + label nama item) | `scripts/ui/hotbar.gd` |
| Bilah stamina (bingkai kayu) | `scripts/ui/stamina_bar.gd` |
| Inventory | `scripts/ui/inventory_panel.gd` |
| Toko (tab hijau/kayu, kartu barang, tombol hijau) | `scripts/ui/shop_panel.gd` |
| Daftar tugas | `scripts/ui/quest_log.gd` |
| Kotak dialog (nama NPC di pita hijau) | `scripts/ui/dialogue_box.gd` |
| Main Menu / Pause / Settings (tombol hijau, centang & slider dari pack) | `main_menu.gd`, `pause_menu.gd`, `settings_panel.gd` |
| Mini game memancing | `scripts/fishing/fishing_minigame.gd` |
| Tombol sentuh (tombol hijau, + tombol PETA) | `scripts/ui/touch_controls.gd` |
| Bingkai jam & gold (kanan atas) | `scripts/ui/hud_frame.gd` (node `HUD/ClockFrame` di main.tscn) |

## Fitur baru: Peta Dunia (`scripts/ui/world_map.gd`, node `HUD/WorldMap`)
* Tombol **M** (Input Map action `world_map`, didaftarkan otomatis oleh GameManager) atau tombol **PETA** di HP.
* Gulungan membuka (11 frame), lalu tampil pulau, jalan, kompas, dan lokasi: **Desa** (tengah),
  **Hutan** (utara), **Tambang** (barat), **Farm** (timur). Penanda bergoyang = lokasi kamu sekarang.
* **M / ESC / klik** = tutup (gulungan menggulung). Waktu berhenti selama peta terbuka.
* Posisi lokasi bisa diubah di konstanta `LOCATIONS` (koordinat di dalam gulungan).

## Cara menguji
1. F5 -> Main Menu: tombol hijau.
2. New Game: hotbar papan kayu, jam & gold di kertas kanan atas.
3. I (inventory), J (tugas), bicara ke NPC (dialog), toko Mira/Barnaby, ESC (pause -> Settings).
4. M -> peta dunia; pindah ke Desa lalu M lagi -> penanda pindah ke Desa.
