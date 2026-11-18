# Modern Farm - Phase 10 (Forest, Mining, Ore, Minerals)
Kontrol: WASD jalan | SPACE alat (Axe / Pickaxe / pancing / cangkul) | E bicara / pungut / hewan / panen / tidur | 1-8 pilih | I tas | F2 item uji (+Axe, +Pickaxe, +Fishing Rod) | N tidur (debug).

Peta baru:
- FOREST: dari Village lewat jalan utara. Hutan lebat, sungai di utara (bisa memancing), barang pungut.
- MINE  : dari Village lewat jalan barat. Tambang terbuka penuh batu dan bijih.

Alat baru (Toko Serba Ada / Mira): Axe 250 G, Pickaxe 300 G. Animasi: ayunan kapak asli Modern_Farm.
- Axe (SPACE menghadap pohon): pohon dipukul 4-5 kali -> tumbang -> Wood 3-6.
- Pickaxe (SPACE menghadap batu):
    Batu biasa  -> Stone (kadang Crystal dari batu besar)
    Batu tembaga (oranye kecil) -> Copper Ore     Batu besi (perak) -> Iron Ore
    Batu emas (kuning)          -> Gold Ore       Batu kristal biru -> Crystal    Batu merah -> Ruby
  Makin jauh ke barat (makin dalam) makin banyak bijih langka.
- Barang pungut di Forest (tekan E): Apple, Peach, Lemon, Ranting (Wood).
Pohon, batu, dan barang pungut muncul lagi setelah beberapa hari (respawn_days).
Semua hasil bisa dijual di Toko Serba Ada (Stone, Ore, Crystal, Ruby, buah, Wood).

Catatan asset: Modern_Farm_v1.2 tidak punya ikon pickaxe, jadi ikon Pickaxe
(assets/modern_farm/icons/Icons_16x16_Tools_Pickaxe_Custom.png) digambar khusus dengan palet ikon Axe.
Ikon bijih diambil dari potongan sprite batu berwarna asli. Pickaxe memakai animasi ayunan kapak.

Belajar di editor: buka scenes/forest/forest.tscn atau scenes/mine/mine.tscn.
Sumber daya = scene di res://scenes/world/resources/ (pohon, batu, bijih, buah). Drag ke node Objects
untuk menambah. Pilih satu lalu lihat Inspector: tool, hits, drop_item, drop_min/max, bonus_item, respawn_days.
