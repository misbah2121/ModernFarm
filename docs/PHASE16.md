# Phase 16: Masuk Gudang (Barn Interior)

## Cara main
* Jalan ke **pintu barn** (pintu kiri bawah barn di kandang) -> layar memudar -> masuk ke dalam gudang.
* Di dalam: tumpukan jerami, karung, tempat makan & minum hewan, kaleng susu, kotak telur,
  dan **2 Peti Gudang** (ChestA, ChestB, masing-masing 24 slot). **E** di depan peti = buka isi peti.
* Keluar: jalan ke **pintu bawah** gudang -> kembali tepat di depan pintu barn.
* **M** (peta dunia) di dalam gudang menunjukkan lokasi **Farm**.
* Isi peti gudang & posisi player (jika menyimpan di dalam gudang) ikut tersimpan.

## Struktur scene `scenes/interiors/barn.tscn` (script `scripts/world/interior_map.gd`)
```
Barn (Node2D, InteriorMap)   map_name="barn", world_location="farm", room_size=(240,272)
├─ Background (ColorRect)    latar gelap di luar ruangan
├─ Room (Node2D)             Upper / Middle1 / Middle2 / Bottom = Hayloft_*_Inside (asset Modern Farm)
├─ Walls (StaticBody2D)      Back, Left, Right, BottomLeft, BottomRight, BelowDoor (kotak tabrakan)
├─ Objects (Y Sort)          Player, ChestA, ChestB, jerami, karung, manger, trough, milk can, egg box
├─ Markers/SpawnFromFarm     titik muncul saat masuk
└─ ExitToFarm (MapExit)      pintu keluar (target_map = "farm")
```
Kamera dikunci di tengah ruangan (ruangan lebih kecil dari layar 640x360).

## Perubahan file
| File | Perubahan |
|---|---|
| `scripts/world/interior_map.gd` (baru) | Peta dalam ruangan umum: kamera tengah, spawn, `chest_at()`, simpan/muat isi peti. Bisa dipakai lagi untuk rumah. |
| `scenes/interiors/barn.tscn` (baru) | Isi gudang. |
| `scenes/farm/farm.tscn` | Node baru `ExitToBarn` (MapExit di pintu barn) + `Markers/SpawnFromBarn`. |
| `scripts/world/farm_map.gd` | `get_spawn()` memakai marker `SpawnFrom<Nama>` (Village tetap default). |
| `scripts/systems/main.gd` | Peta "barn" di `MAP_SCENES`; E di dalam ruangan (`_on_interior_interact`); peta dunia memakai `world_location`; simpan `interiors`. |
| `scenes/world/props/*` (baru) | raw_bale_big/small, milk_can_1/2, sack_jute, hay_dry_pile, box_load, egg_box, manger_vertical, trough_vertical. |

## Menambah ruangan baru (mis. rumah)
1. Duplikat `barn.tscn`, ganti gambar di `Room`, kotak `Walls`, isi `Objects`, dan `map_name`.
2. Tambahkan ke `MAP_SCENES` di `main.gd`.
3. Di peta luar, tambahkan `MapExit` (target_map = nama ruangan) + `Markers/SpawnFrom<Nama>`.
