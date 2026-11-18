# Phase 17 – Rapikan Animasi + Efek Visual (VFX)

## 1. Kenapa animasi terlihat "tidak rapi"
Di sheet asli `Farmer_1_16x16.png` dan `Farmer_1_Fishing_128_frames_16x16.png`, tubuh petani pada
animasi aksi **tidak berada di posisi yang sama** dengan animasi idle. Akibatnya saat mencangkul / menyiram /
menebang / memancing, karakter "loncat" beberapa piksel lalu kembali lagi:

| Animasi    | Kanan     | Atas     | Kiri       | Bawah     |
|------------|-----------|----------|------------|-----------|
| cangkul    | 8 px      | 8 px     | 8 px       | 8 px, 7 px|
| siram      | 8 px      | 1 px     | 8 px       | **18 px** |
| kapak      | 8,5 px    | 8,5 px   | 8,5 px     | 8,8 px    |
| memancing  | 15,10 px  | 0        | 15,10 px   | **32 px** |

Angka diukur otomatis: kepala di frame idle dicocokkan (template matching) dengan setiap frame aksi.

**Perbaikan:** `ANIM_OFFSETS` di `player.gd` menggeser `AnimatedSprite2D.offset` setiap kali animasi berganti
(signal `animation_changed`), sehingga tubuh tetap diam di tempat dan hanya alatnya yang bergerak.

Frame kena alat juga disamakan dengan gambarnya:

| Alat           | hit_frame lama | baru | Saat di gambar        |
|----------------|----------------|------|-----------------------|
| Hoe            | 5              | 3    | cangkul menyentuh tanah |
| Watering Can   | 7              | 6    | air mulai mengalir    |
| Axe / Pickaxe  | 6              | 7    | ayunan (garis sabetan) |

## 2. Memancing
* Tubuh tidak lagi naik 32 px saat memancing ke bawah.
* `Player.BOBBER_OFFSETS` = titik jatuh pelampung yang tergambar di sheet. Air dicek **tepat di titik pelampung**
  (bukan lagi "air dalam 2 tile"), jadi pelampung tidak tampak jatuh di rumput / pagar.
  Jika belum pas: muncul pesan *"Pelampung belum sampai ke air. Geser sedikit (maju / mundur)."*
* Kotak kursor tile disembunyikan selama memancing.
* Efek: cipratan saat pelampung jatuh, riak berkala saat menunggu, riak cepat + cipratan besar saat ikan
  menggigit, cipratan saat ikan ditarik / pancing ditarik.

## 3. Efek visual (VFX)
| Aksi                         | Efek |
|------------------------------|------|
| Mencangkul                   | serpih tanah coklat |
| Menyiram                     | percikan air di tile |
| Axe / Pickaxe                | serpih kayu / serpih batu |
| Pohon dipukul                | daun berguguran (`Modern_Farm_vfx_Falling_Leaves*` asli; musim gugur kuning, dingin coklat) |
| Pohon tumbang / batu pecah   | daun + serpih besar |
| Panen tanaman / pohon buah   | daun berhamburan + ikon hasil melompat ke atas |
| Tanaman siap panen           | berkilau (`Modern_Farm_vfx_Rare_Crop_Glitter` asli) |
| Cheese Machine bekerja       | uap tipis |
| Berjalan                     | debu langkah halus |
(Sprinkler sudah memakai animasi air aslinya sejak Phase 14.)

Partikel = `CPUParticles2D` tanpa tekstur (kotak 1–2 px) sehingga tetap tajam seperti pixel art.

## 4. File
**Baru**
* `scripts/effects/vfx.gd` – class `Vfx` (fungsi static: `burst`, `splash`, `ripple`, `leaves`, `pop_icon`, `glitter`, `steam`).
* `scripts/effects/ripple_fx.gd` – class `RippleFx` (riak air 1 px).
* `assets/modern_farm/effects/` – disalin dari pack: Falling_Leaf, Falling_Leaves (hijau/kuning/coklat), Rare_Crop_Glitter, Stone_Oven_Smoke_Effect.

**Diubah**
* `scripts/player/player.gd` – `ANIM_OFFSETS`, `BOBBER_OFFSETS`, `TOOL_FX`, `_apply_anim_offset()`, `bobber_position()`, `_play_hit_fx()`, debu langkah.
* `scripts/fishing/fishing_controller.gd` – cek air di pelampung, riak & cipratan.
* `scripts/farming/tile_cursor.gd` – sembunyi saat memancing.
* `scripts/farming/farm_soil.gd` – efek panen.
* `scripts/farming/crop_plant.gd` – kilau siap panen.
* `scripts/farming/fruit_tree.gd` – daun saat digoyang, ikon buah saat panen.
* `scripts/world/resource_node.gd` – daun saat pohon dipukul, efek saat tumbang / pecah.
* `scripts/crafting/cheese_machine.gd` – uap saat bekerja.
* `data/tools/hoe.tres`, `watering_can.tres`, `axe.tres`, `pickaxe.tres` – `hit_frame`.

Tidak ada node / Input Map baru. Semua fitur lama tetap ada.

## 5. Mengatur sendiri
* Karakter masih geser 1–2 px di arah tertentu → ubah angka di `ANIM_OFFSETS` (player.gd).
* Pelampung kurang pas → ubah `BOBBER_OFFSETS`.
* Efek terlalu ramai / kurang → ubah `SETTINGS` (jumlah, umur, kecepatan, gravitasi) dan `PALETTES` di `vfx.gd`.
* Matikan debu langkah: hapus baris `Vfx.burst(... Vfx.Kind.STEP)` di `_physics_process` player.gd.
