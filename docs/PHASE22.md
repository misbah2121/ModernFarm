# Phase 22 – Desa & Hutan Senada, Tanaman Baru + Panen Langka, Kios Pasar

## 1. Gaya Farm diterapkan ke Desa & Hutan
- Layer **GrassDetail** dan shader angin juga ada di **Desa** dan **Hutan**: rumput detail, bunga kecil, kerikil di jalan, dan rumput bergoyang / menyibak saat dilewati. Tambang tidak diberi efek ini karena ruangannya bawah tanah.
- **Pohon oak bulat** menggantikan pinus:
  - **Desa:** pinus diganti oak Huge dan Big (Blue_Green).
  - **Hutan:** pinus diganti oak Big (hijau dan Blue_Green) yang tetap bisa ditebang. Resource baru: `tree_oak_bluegreen_big.tscn` dan `tree_oak_huge.tscn`.
  - Nama node pohon tidak diubah, jadi save lama (pohon yang sudah ditebang) tetap cocok.
- Pohon di Hutan juga **jadi transparan saat player di belakangnya**.
- **Daun gugur** muncul siang hari dan **kunang-kunang** muncul malam hari di Desa dan Hutan.

## 2. Tanaman baru + panen langka
10 tanaman baru, semuanya memakai sheet pertumbuhan, ikon, kantong benih, dan pickup **asli pack**. Benihnya dijual Mira:

| Musim | Tanaman (hari panen, harga jual) |
|---|---|
| Semi | Stroberi (5, 85), Kubis (4, 55), Kembang Kol (6, 100) |
| Panas | Semangka (8, 150), Cabai (4, 45), Nanas (9, 190), Zukini (5, 58) |
| Gugur | Anggur (6, 115), Gandum (4, 26), Kapas (5, 68) |

**Panen langka:**
- Saat tanaman siap panen, ada **peluang 10%** tanaman itu menjadi **langka**. Hanya tanaman langka yang **berkilau** (efek Rare_Crop_Glitter asli).
- Hasil panennya item **"… Langka"** dengan gambar `Pickup_Crop_*_Rare` asli dan **harga jual 3x**. Panen langka muncul dengan pesan "WAH!", efek kilau ekstra, dan suara khusus.
- Berlaku untuk semua tanaman, termasuk yang lama (wortel, bawang, labu, lobak, tomat, jagung).
- Status langka ikut tersimpan. Pekerja Sari juga bisa memanen hasil langka.

## 3. Kios Pasar
Market Stand kuning di dekat jalan ke Desa sekarang berfungsi:
- **E di depan kios** membuka panel **KIOS PASAR**. Klik barang di tas untuk menaruh setumpuk di rak (klik kanan = 1). Klik barang di rak untuk mengambilnya kembali.
- **Harga kios** = harga jual × 1,25.
- Setiap pagi satu kategori sedang **DICARI**: Hasil Panen, Ikan, Makanan, Bahan, atau Bijih. Kategori itu dihargai **×1,6**.
- **Jam 09:00–17:00** warga desa (Mira, Lila, Toby, Barnaby, dengan sprite asli) berjalan datang dari arah Desa. Mereka berhenti di kios, membeli 1 barang (lebih suka barang yang sedang dicari), lalu pulang. Gold langsung masuk dan muncul pesan.
- Kalau kamu sedang di peta lain, penjualan tetap terjadi.
- 3 barang pertama di rak terlihat di meja kios. Isi rak, kategori dicari, dan penghasilan hari ini ikut tersimpan.

## File
**Baru:**
- `scripts/shop/market_stall.gd`, `scripts/shop/stall_customer.gd`, `scripts/ui/stall_panel.gd`
- `data/crops/` (10 tanaman), `data/tools/seeds_*` dan `data/items/seeds_*` (10), `data/items/<tanaman>.tres` (10), `data/items/*_rare.tres` (16)
- `scenes/world/resources/tree_oak_huge.tscn`, `tree_oak_bluegreen_big.tscn`
- Asset: `crops/*` (sheet baru), `icons/*`, `objects/pickups/*` (biasa + Rare)

**Diubah:**
- `grass_detail.gd` (bisa dipakai di peta mana pun), `farm_ambience.gd` (Desa/Hutan, daun dari pohon Hutan)
- `village_map.gd`, `wild_map.gd`: `get_terrain`, `_setup_style`, rumput menyibak
- `resource_node.gd`: pohon transparan
- `crop_plant.gd`: panen langka; `farm_soil.gd`: hasil langka + simpan
- `scenes/village/village.tscn`, `scenes/forest/forest.tscn`: node GrassDetail, pohon oak
- `scenes/farm/farm.tscn`: MarketStand memakai script `market_stall.gd`
- `farm_map.gd`, `main.gd`, `main.tscn` (node baru `HUD/StallPanel`), `interact_hint.gd`
- `general_store.tres`: 10 benih baru

Tidak ada Input Map baru.
