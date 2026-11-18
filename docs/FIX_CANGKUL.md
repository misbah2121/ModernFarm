# Perbaikan Tileset Tanah Cangkul

## Penyebab bug
1. **Versi awal** memakai blok autotile *Autotiles_Godot_16x16.png* baris 32 (tanah bergaris).
   Di blok autotile ini tanahnya **menjorok ke dalam** tile (tepi rumput ±4 px di dalam tile).
   Akibatnya 1 tile = gumpalan kecil dan baris 1 tile = garis tipis, tidak seperti petak kebun di asset.
2. **Versi kedua** memakai 1 tile kotak bergaris (1_Terrains 1,9) tanpa tepi, jadi terlihat
   seperti kotak tempelan yang tidak menyatu dengan rumput.

Padahal desain asli Modern Farm (gambar promo, dan petak 1 tile di *1_Terrains_16x16.png*
kolom 8-10, baris 12-14) adalah: **tile tanah penuh** + **rumbai rumput/tanah yang menjorok
keluar** ke tile rumput di sekitarnya.

## Cara kerja sekarang

| Layer di farm.tscn | Isi |
|---|---|
| `Ground` | Tile yang dicangkul = tile tanah **cokelat muda** asli `1_Terrains_16x16.png` (9,17), penuh 16x16. |
| `SoilWet` | Tanah yang sudah disiram = tile **asli** `Soil_Wet_1/3/4_16x16.png` (bercak gelap, sama seperti kebun di gambar promo). Variasi dipilih tetap per tile oleh `TerrainTiles.soil_wet_source()`. Tanpa modulate. |
| `SoilEdge` | Rumbai di tile rumput yang bersebelahan dengan tanah (8 arah). |
| `Decor` | Rumput hias (tidak berubah). |

`SoilEdge` memakai `Soil_Edges_16x16.png` yang **dibuat dari piksel asli** oleh
`tools/make_soil_edges.py`: script mengambil 8 tile rumbai di sekitar petak 1 tile (8..10, 16..18),
membuang piksel yang sama dengan rumput polos (jadi transparan), lalu menggabungkan semua
256 kombinasi arah. Tidak ada warna atau tekstur buatan.

## File yang diubah

| File | Fungsi yang berubah |
|---|---|
| `scripts/systems/terrain_tiles.gd` | `tile_for()` (tanah kering/basah = SOIL_COORD), `soil_edge_coords()`, `build_soil_edge_tileset()`, `build_soil_wet_tileset()`, `build_tileset()` (menambah tile SOIL_COORD) |
| `scripts/world/farm_map.gd` | `_paint_cell()` memanggil `_paint_soil_layers()` (SoilWet + SoilEdge), `_is_soil()` |
| `scenes/farm/farm.tscn` | Node baru `SoilWet` & `SoilEdge` (di bawah Decor) |
| `assets/modern_farm/tilesets/` | `modern_farm_terrain.tres` (diperbarui), `modern_farm_soil_wet.tres`, `modern_farm_soil_edge.tres` (baru) |
| `assets/modern_farm/16x16/autotiles/Soil_Edges_16x16.png` | Baru (hasil `tools/make_soil_edges.py`) |

`farm_soil.gd`, `player.gd`, inventory, tanaman, dan save tidak diubah: sistem tetap memanggil
`FarmMap.set_terrain(cell, SOIL_DRY / SOIL_WET / GRASS)`, dan `set_terrain()` menggambar ulang
tile itu dan 8 tetangganya di ketiga layer.

## Cara menguji di Godot 4
1. Buka project, tekan **F5**, pilih **New Game**.
2. Masuk kebun lewat celah pagar, pilih **Hoe** (slot 1), lalu cangkul:
   - 1 tile -> petak tanah kecil dengan rumbai rumput di sekelilingnya,
   - beberapa tile berderet atau 3x3 -> menyatu menjadi satu petak, rumbai hanya di tepi luar.
3. Pilih **Watering Can** dan siram beberapa tile -> tile berubah menjadi tanah basah bercak gelap (Soil_Wet).
4. Coba cangkul di luar kebun, di pagar, atau di jalan -> muncul pesan dan tile tidak berubah.
5. Pergi ke Village lalu kembali -> tanah tetap sama.
6. Tidur (save otomatis) -> Main Menu -> **Load** -> tanah kering/basah kembali seperti semula.

## Ganti warna tanah
Tanah sekarang memakai set **cokelat muda** (1_Terrains baris 16-18, yang dilingkari).
Untuk kembali ke versi cokelat kemerahan (baris 12-14):
1. Jalankan `python3 tools/make_soil_edges.py 9 13` (membuat ulang Soil_Edges_16x16.png).
2. Di `terrain_tiles.gd` ubah `SOIL_COORD` menjadi `Vector2i(1, 13)`.
3. Simpan ulang tileset dari `build_tileset()` dan `build_soil_wet_tileset()`.

## Tanah basah (update)
Sebelumnya tanah basah = tanah kering yang digelapkan (modulate), hasilnya terlalu gelap dan polos.
Sekarang memakai tile asli `Soil_Wet_1..4_16x16.png` dari *Props_and_Buildings* (disalin ke
`assets/modern_farm/16x16/soil/`). TileSet `modern_farm_soil_wet.tres` punya source 1-4 (satu per file).
Soil_Wet_1 paling sering dipakai, _4 sesekali, _3 jarang; _2 tidak dipakai karena hampir sama
dengan tanah kering.
