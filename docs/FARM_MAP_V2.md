# Peta Farm Baru (v2) — terinspirasi gambar promo Modern Farm

Layout `scenes/farm/farm.tscn` disusun ulang: hutan pinus lebat di atas, halaman tanah besar
dengan traktor, gudang kayu, dan anjing, dua kebun berpagar di selatan, kandang berpagar di timur,
dan sungai di bawah untuk memancing. Semua asset diambil dari Modern_Farm_v1.2 (16x16).

## Yang berubah

| File | Perubahan |
|---|---|
| `scenes/farm/farm.tscn` | Layout baru. Rumah, pintu (tidur), dan jalan keluar ke Village tetap di posisi lama. |
| `scripts/world/farm_map.gd` | Mendukung banyak lahan: semua kotak `Areas/FarmPlot*` (FarmPlot, FarmPlot2, ...). Fungsi baru `farm_plot_rects()` dan `is_farm_plot(cell)`. |
| `scripts/farming/farm_soil.gd` | Cangkul memakai `is_farm_plot()`. Tanah dari save lama yang berada di luar lahan baru dilewati. |
| `data/events/welcome.tres` | Teks hari pertama: kebun sekarang ada di selatan rumah. |
| `assets/modern_farm/tilesets/modern_farm_fences.tres` | TileSet pagar kayu (2_Fences_16x16.png) lengkap dengan collision. |
| `scenes/world/props/*.tscn` (baru) | tractor, canopy_tools_big, canopy_small, trunk_load_big, wood_board_load, weathercock, doghouse, dog_labrador, bucket, pumpkin_big, pumpkin_basket, market_stand_yellow_small, sign_2, stump_pine, stump_oak, tree_pine_green_huge, tree_pine_green_medium, tree_pine_dark_green_big |

## Struktur scene Farm

```
Farm (Node2D, farm_map.gd)
├─ Ground (TileMapLayer)        terrain: rumput / tanah jalan / air
├─ Cursor
├─ Objects (Node2D, Y Sort Enabled = On)
│   ├─ Player
│   ├─ Fences (TileMapLayer, Y Sort Enabled = On)   pagar kebun & kandang (ada collision)
│   ├─ Feeder, FarmerHouse1, Tractor, WoodShed, Dog, BarnSmall, ...
│   └─ pohon pinus, tunggul, batu, bunga
├─ Areas
│   ├─ FarmPlot   (kebun kiri, 15x7 tile)
│   ├─ FarmPlot2  (kebun kanan, 10x7 tile, ada orang-orangan sawah)
│   ├─ HouseDoor
│   └─ AnimalPen  (area jalan-jalan hewan di dalam kandang)
├─ Markers/SpawnFromVillage
├─ ExitToVillage
└─ Soil
```

## Mengedit di editor Godot

- **Pagar**: pilih `Objects/Fences`, buka panel **TileMap** di bawah, pilih potongan pagar,
  lalu klik untuk menggambar atau klik kanan untuk menghapus. Sisakan celah 2 tile sebagai pintu.
- **Lahan baru**: pilih `Areas/FarmPlot`, tekan **Ctrl+D**, lalu geser atau ubah ukuran kotaknya.
  Kotak yang namanya diawali `FarmPlot` otomatis bisa dicangkul.
- **Objek**: drag file `.tscn` dari `res://scenes/world/props/` ke dalam node `Objects`.

## Catatan save lama

Save lama tetap bisa dimuat. Tanah olahan dan tanaman yang dulu berada di lahan lama
(di timur rumah) tidak lagi berada di dalam kebun baru, jadi dilewati saat dimuat.
Untuk hasil terbaik, mulai **New Game**.
