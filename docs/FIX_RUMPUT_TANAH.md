# Perbaikan: rumput hias, tanah cangkul kotak, peta lebih ramai

## 1. Rumput tidak lagi menutupi player
Sebelumnya rumput/bunga (`flowers_1..3.tscn`) adalah objek di dalam `Objects` yang di-y-sort,
jadi saat player berdiri sedikit di atasnya, rumput tergambar di depan kaki player.
Sekarang semua rumput hias dipindah ke layer baru **`Decor`** (TileMapLayer) yang berada
**di bawah** `Objects` dan tanpa y-sort. Urutan node di farm/village/forest:

```
Ground  (TileMapLayer)  tanah, jalan, air
Decor   (TileMapLayer)  rumput hias & bunga  <- baru, selalu di bawah player
Cursor                  (khusus farm)
Objects (y-sort)        player, bangunan, pohon, pagar ...
```

## 2. Tanah cangkul
Sudah diganti lagi agar sama dengan asset asli - lihat **README_FIX_CANGKUL.md**.

## 3. Rumput hias lebih banyak
Layer `Decor` diisi 11 jenis `Grass_Tufts_Flowers_1..11` (asset pack) secara berkelompok:
farm sekitar 245 tile, village 150, forest 55. Kebun (FarmPlot) dibiarkan bersih.

### Menggambar rumput sendiri di editor
1. Pilih node **Decor**.
2. Buka panel **TileMap** di bawah dan pilih tab **Tiles**.
3. Pilih salah satu jenis rumput, klik di peta untuk menggambar, klik kanan untuk menghapus.
TileSet: `res://assets/modern_farm/tilesets/modern_farm_decor.tres`.
