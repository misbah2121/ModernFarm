# Phase 21 – Map v3 seperti Video + Rumput Detail + Efek

Video referensi yang kamu kirim adalah video promo Modern Farm. Semua elemennya dibuat ulang memakai aset pack Modern Farm v1.2.

## 1. Rumput detail (seperti video)
- Layer baru **GrassDetail** (TileMapLayer, tepat di atas `Ground`) mengisi setiap tile rumput dengan bilah rumput pixel art:
  - petak **rumput lebat gelap**,
  - petak **rumput terang**,
  - rumpun jarang / sedang,
  - **bunga kecil** (putih, kuning, pink, biru),
  - **rumpun tinggi**.
- Jalan tanah juga diberi **kerikil samar dan tunas rumput** kecil seperti di video.
- Pola dibuat dengan `FastNoiseLite` (seed tetap), jadi petak gelap dan terang membentuk area alami, bukan acak per tile.
- Rumput otomatis hilang saat tanah dicangkul.
- Atlas `assets/modern_farm/tilesets/grass_detail_16x16.png` dibuat oleh `tools/make_grass_detail.py` dari **palet rumput asli pack**.
- **Shader angin** `assets/shaders/grass_wind.gdshader`:
  - Rumput bergoyang pelan, maksimal 1 piksel agar tetap pixel art.
  - Rumput **menyibak saat dilewati player atau anjing**.
  - Rumput hias lama di layer `Decor` ikut bergoyang.
- Atur di Inspector `GrassDetail`: `noise_seed` (pola lain) dan `density` (kerimbunan).

## 2. Map v3
- **Hutan pinus diganti pohon oak bulat besar** (Trees_Oak_Green / Blue_Green, ukuran Huge / Big / Medium). Hutan jadi rimbun dan berlapis seperti video.
- Ada pohon oak tambahan di sekitar sumur, di antara kebun, dan di utara kandang.
- **Deretan pohon buah dewasa** (lemon, apel, jeruk, persik) di tepi halaman. Ini pohon buah asli (Phase 15) yang bisa dipanen. Muncul di game baru maupun save lama (sekali).
- **Kandang Stable dengan atap tembus pandang**, sama seperti di video:
  - Gambar memakai `Stable_Example_Outside` dan `Stable_Example_Inside` dari pack.
  - Saat player masuk lewat **pintu kiri bawah**, atap memudar dan isi kandang terlihat (lantai kayu, kotak tanaman, palung air, jerami). Atap muncul lagi saat player keluar.
  - Area jalan-jalan hewan (AnimalPen) dipersempit ke sisi kiri kandang.

## 3. Efek
| Efek | Keterangan |
|---|---|
| **Pohon tembus pandang** | Saat player berdiri di belakang tajuk pohon, pohon menjadi transparan (45%). |
| **Pohon bergoyang** | Memakai sheet "Shake" asli. Pohon bergoyang sesekali tertiup angin dan saat player lewat di dekat batang. |
| **Tetes air** | `Water_Drop_Outlined` asli melayang di atas tanaman yang belum disiram hari ini, seperti di video. Hilang setelah disiram. |
| **Daun gugur** | Pohon di sekitar layar sesekali menjatuhkan daun pada siang hari. |
| **Kunang-kunang** | Malam hari (19:00–05:00) muncul titik cahaya hijau-kuning yang beterbangan (PointLight2D). |
| Rumput bergoyang / menyibak | Lihat bagian 1. |

## File
**Baru:**
- `scripts/world/grass_detail.gd`
- `assets/shaders/grass_wind.gdshader`
- `tools/make_grass_detail.py`, `assets/modern_farm/tilesets/grass_detail_16x16.png`
- `scripts/world/tree_prop.gd`
- `scripts/world/stable_building.gd`, `scenes/world/props/stable.tscn`
- `scripts/effects/farm_ambience.gd`
- `scenes/world/props/tree_oak_green_huge.tscn`, `tree_oak_bluegreen_huge.tscn`, `tree_oak_bluegreen_big.tscn`, `tree_oak_bluegreen_medium.tscn`
- Asset: `objects/trees/Trees_Oak_*`, `buildings/stable/*`, `effects/Water_Drop_Outlined_16x16.png`

**Diubah:**
- `scenes/farm/farm.tscn`:
  - node `GrassDetail` baru,
  - pinus → oak,
  - pohon tambahan,
  - `Stable`,
  - AnimalPen dipersempit.
- `scenes/world/props/tree_*.tscn`: memakai script TreeProp.
- `farm_map.gd`: GrassDetail, FarmAmbience, kebun buah awal, rumput menyibak.
- `farm_soil.gd`: `thirsty_cells()`.
- `main.gd`: `orchard_given` disimpan.

Tidak ada Input Map baru. Untuk melihat semuanya, sebaiknya mulai **New Game** (save lama tetap bisa dimuat).
