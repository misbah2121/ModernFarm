# Modern Farm - Mengedit Peta di Editor Godot (Godot 4.5)
Semua peta TERSIMPAN di scene, jadi terlihat dan bisa diedit langsung di editor:
scenes/farm/farm.tscn, scenes/village/village.tscn, scenes/forest/forest.tscn, scenes/mine/mine.tscn
(double-click di FileSystem).

## Isi scene peta
- Ground (TileMapLayer)   : tile tanah. TileSet: assets/modern_farm/tilesets/modern_farm_terrain.tres
- Cursor                  : (Farm) kotak penanda tile target alat.
- Objects (y-sort)        : Player + semua objek (rumah, pohon, batu, ...). Objek digambar depan/belakang
                            otomatis berdasarkan posisi Y.
- Labels                  : (Village) tulisan di atas papan penunjuk.
- Areas (ReferenceRect)   : kotak yang hanya terlihat di editor.
    Farm   : FarmPlot  = lahan yang boleh dicangkul (hijau), HouseDoor = E di sini untuk tidur (kuning),
             AnimalPen = area jalan-jalan hewan ternak (merah muda).
    Village: ShopCounter = E di sini untuk membuka toko (oranye).
- Markers (Marker2D)      : titik muncul player saat datang dari peta lain (SpawnFromVillage, SpawnFromFarm, ...).
- Places (Marker2D)       : (Village, Phase 11) tempat tujuan jadwal NPC. Grup "indoor" = pintu rumah,
                            metadata "wander" (Inspector paling bawah) = jarak jalan-jalan di tempat itu.
- ExitTo... (MapExit)     : area pintu keluar (kotak biru). Atur Target Map dan Size di Inspector.
- Soil                    : (Farm) logika tanah olahan dan tanaman.

## Menggambar tanah (autotile)
1. Klik node Ground. Panel TileMap muncul di bawah.
2. Pilih tab "Terrains", pilih Terrain Set 0, lalu pilih terrain: Grass, Path, Water, Sand.
3. Pilih mode "Connect" lalu gambar dengan klik kiri. Tepinya menyambung otomatis.
   Klik kanan = hapus (tile kosong dianggap rumput oleh game, tetapi lebih rapi digambar Grass).
4. Air otomatis punya collision (player tidak bisa berjalan di air) dan bisa dipakai memancing.
5. Ukuran peta = area tile yang digambar (batas dunia & kamera mengikuti otomatis).
Jangan menggambar Soil Dry/Soil Wet di editor; tanah olahan dibuat oleh cangkul saat bermain.

## Menambah / memindah objek
- Pindah: pilih node di Objects lalu geser di viewport (atau ubah Position di Inspector).
- Tambah: drag file dari res://scenes/world/props/ (mis. tree_pine_green_big.tscn) ke node Objects.
- Duplikat: pilih objek lalu Ctrl+D.
- Hapus: pilih objek lalu Delete.
Setiap objek props: titik node = kaki objek (tengah bawah). Isinya Sprite2D + StaticBody2D (collision).
Grup objek (tab Node > Groups):
  tree       = pohon, hanya batangnya yang menghalangi cangkul.
  solid_prop = bangunan / batu / sumur, seluruh sprite menghalangi cangkul.
Bunga (flowers_*.tscn) hanya hiasan tanpa collision.

## Sumber daya (Phase 10)
res://scenes/world/resources/ berisi pohon yang bisa ditebang (tree_*), batu & bijih (rock_*), dan
barang pungut (forage_*). Root-nya memakai script ResourceNode: atur tool, hits, drop_item, respawn_days
di Inspector. Bisa ditaruh di peta mana pun (termasuk Farm) di dalam node Objects.

## Yang tetap dibuat lewat kode saat game berjalan
- NPC (Village): dari data res://data/npc/*.tres. Posisi awal = "home" di file NPC tersebut.
- Hewan ternak (Farm): dari AnimalManager (hewan yang sudah dibeli), muncul di dalam AnimalPen.
  Feeder (tempat pakan) ada di Objects dan bisa dipindah seperti objek lain.
- Tanaman, tanah olahan, cuaca, HUD, dinding batas peta.

## Player
Animasi player tersimpan di assets/modern_farm/characters/farmer_1_frames.tres.
Klik Player > AnimatedSprite2D > Sprite Frames untuk melihat semua animasi
(idle, walk, dig, water, harvest, fish_throw, fish_wait, fish_bite, fish_reel; tiap arah).
