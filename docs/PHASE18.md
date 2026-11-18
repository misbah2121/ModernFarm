# Phase 18 – Hasil Ternak, Dapur, Grafik Seperti Referensi, Barang Jatuh

## 1. Hasil ternak
**Babi → Truffle**
* Setiap pagi, babi yang kemarin makan berpeluang **35% + 3% per hati** menemukan Truffle.
* Truffle **tergeletak di tanah kandang**. Datangi saja, nanti terbang masuk tas. Truffle tetap ada walau game disimpan/dimuat, maksimal 8 di tanah.
* Data: `data/animals/pig.tres` → `forage_item = truffle`, `forage_chance = 0.35` (bisa diubah di Inspector).

**Bebek (baru)**
* Dijual Barnaby: 600 Gold, tinggal di Coop.
* Bertelur **Telur Bebek setiap 2 hari** jika makan. Ambil dengan E, sama seperti ayam.
* Sprite: `Duck_White_16x16.png` asli pack (frame 32x32: baris 1 diam, 2 jalan, 3 makan).

## 2. Memasak di Dapur
* **Kompor Batu** (`Stone_Oven_1_16x16.png`) sudah terpasang otomatis di dekat rumah. Ini berlaku untuk game baru dan save lama.
* Bisa juga dibuat sendiri di panel Kerajinan (C): 20 Stone + 15 Wood, lalu pasang dengan SPACE.
* **E di depan Kompor Batu** membuka panel **DAPUR**. Klik **MASAK** dan asap keluar dari cerobong.

| Masakan | Bahan | Energi | Bonus |
|---|---|---|---|
| Ikan Bakar | Blue Fish + Onion | +45 | Mudah memancing 2 jam |
| Sup Sayur | Carrot + Radish + Onion | +70 | – |
| Sup Ikan | Green Fish + Tomato + Milk | +80 | Mudah memancing 4 jam |
| Omelet Keju | Egg + Cheese | +60 | – |
| Baguette | 2 Corn | +30 | – |
| Roti Jagung | 2 Corn + Egg + Milk | +70 | Jalan cepat 2 jam |
| Pai Labu | Pumpkin + Egg + Milk | +90 | Jalan cepat 4 jam |
| Omelet Truffle | Truffle + Telur Bebek + Cheese | +100 | Jalan cepat + mudah memancing 5 jam |

Kopi (beli di toko) sekarang juga memberi bonus Jalan cepat 1,5 jam.

**Bonus makanan**
* **Jalan cepat:** kecepatan jalan ×1,35.
* **Mudah memancing:**
  * waktu tunggu ikan ×0,55;
  * waktu menyentak pancing ×1,8;
  * zona hijau mini game +12 px.
* Makanan berbonus tetap bisa dimakan walau stamina penuh.
* Bonus aktif tampil di kanan atas (BuffLabel, biru muda) dan ikut tersimpan.

## 3. Grafik seperti gambar referensi
* **Penanda interaksi:** kotak biru berisi ikon, tombol di pojok, dan panah memantul ke bawah, muncul di atas benda yang dihadap:
  * Pohon: ikon Axe + tombol spasi. Batu/bijih: ikon Pickaxe + tombol spasi.
  * Tanaman siap panen: ikon hasil + **E**. Tanaman belum siap: **tanda dilarang merah**.
  * Dapur: sup + E. Peti: tas + E. Tempat pakan: karung pakan.
  * Mesin keju: susu / keju, atau dilarang selama masih memproses.
  * Pohon buah: buah + E. NPC: E.
  * Pancing di depan air: ikon pancing tepat di titik jatuh pelampung.
* **Bayangan elips** di kaki player, NPC, hewan, dan barang jatuh.
* **Kilau kecil biru-putih** di rumput farm. Muncul siang hari saja, tidak muncul saat hujan.

## 4. Barang jatuh memakai asset Pickup
Barang sekarang **melompat keluar ke tanah** memakai `Pickup_*_16x16.png` asli pack, memantul, lalu **terbang ke player** saat didekati:
* kayu dari pohon (`Pickup_Resource_1`), batu / bijih;
* hasil panen (Carrot, Onion, Pumpkin, Radish, Tomato, Corn);
* buah dari pohon buah (Apple, Banana, Lemon, Orange, Peach);
* truffle dari babi.

Kalau tas penuh, barang tetap di tanah dan muncul pesan. Ikan, Boot, dan Branch juga punya gambar pickup (`pickup_texture`). Item tanpa gambar pickup memakai icon-nya.

## 5. File
**Baru:**
* `scripts/world/item_pickup.gd` (ItemPickup)
* `scripts/crafting/kitchen_stove.gd` dan `scenes/crafting/kitchen_stove.tscn`
* `scripts/ui/interact_hint.gd` (InteractHint)
* `scripts/effects/grass_sparkles.gd` (GrassSparkles)
* `data/animals/duck.tres`
* Item:
  * `data/items/truffle.tres`, `duck_egg.tres`, `kitchen_stove.tres`
  * `data/items/grilled_fish.tres`, `veg_soup.tres`, `fish_soup.tres`, `cheese_omelet.tres`
  * `data/items/corn_bread.tres`, `pumpkin_pie.tres`, `truffle_omelet.tres`
* Resep:
  * `data/recipes/kitchen_stove.tres`
  * `data/recipes/cook_*.tres` (8 resep)
* Asset: `objects/pickups/*`, `objects/kitchen/Stone_Oven_1_16x16.png`, `animals/Duck_White_16x16.png`, beberapa icon di `icons/`.

**Diubah:**
* `item_data.gd`: `pickup_texture`, `buff`, `buff_minutes`
* `recipe_data.gd`: `station`
* `craft_panel.gd`: export `station` / `title` / `verb`, keterangan bonus
* `game_manager.gd`: bonus makanan
* `player.gd`: kecepatan bonus, bayangan
* `fishing_controller.gd`, `fishing_minigame.gd`: bonus memancing
* `animal_data.gd`, `animal_manager.gd`: truffle
* `farm_animal.gd`, `npc.gd`: bayangan
* `farm_map.gd`: truffle, kompor awal, kilau
* `resource_node.gd`, `farm_soil.gd`, `fruit_tree.gd`: barang jatuh
* `main.gd`
* `scenes/main/main.tscn`
* `pig.tres`, `coffee.tres`, `barnaby_ranch.tres`

**Node baru di `scenes/main/main.tscn`:**
* `HUD/CookPanel`: Control, script `craft_panel.gd`. Inspector: Station = cook, Title = DAPUR, Verb = MASAK.
* `HUD/BuffLabel`: Label, kanan atas.
* `HintLayer`: CanvasLayer dengan Follow Viewport aktif, supaya ikut kamera tetapi tidak ikut gelap di malam hari.
  * `HintLayer/InteractHint`: Node2D, script `interact_hint.gd`.

Tidak ada Input Map baru. Semua fitur lama tetap ada.

## Catatan asset
Pack Modern Farm **tidak punya** gambar truffle maupun gambar masakan (sup, ikan bakar, omelet). Karena itu:
* Truffle digambar sendiri, ukuran 16x16 dengan palet pack.
* Ikan Bakar dibuat dari `Pickup_Fishing_Orange_Fish` yang diwarnai ulang dan diberi garis panggangan.
* Sup Sayur dan Sup Ikan berupa mangkuk gambar sendiri.
* Omelet Keju dan Omelet Truffle digambar sendiri.

Roti Jagung dan Pai Labu memakai `Bread_Pot_1/2_Stone_Oven` asli pack. Telur Bebek memakai `Egg_Big_16x16` asli pack. Ikon-ikon ini bisa diganti kapan saja lewat field `icon` di file `.tres`.
