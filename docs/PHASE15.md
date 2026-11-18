# Phase 15: Pohon Buah

## Cara main
1. Beli bibit di **Toko Serba Ada (Mira)**: Bibit Lemon, Persik, Pisang, Apel, Jeruk.
2. Taruh bibit di hotbar, hadap ke rumput kosong di Farm, tekan **SPACE** = tanam.
   Pohon butuh ruang 3 tile lebar (tidak bisa berdempetan) dan tidak perlu disiram.
3. Bibit dewasa dalam **7 hari**. Pada musimnya pohon berbuah: buah muda -> **2 hari** -> matang.
4. **E** di pohon matang = panen **3 buah**, lalu pohon berbuah lagi 2 hari kemudian.
5. **Axe**: bibit kembali ke tas; pohon dewasa ditebang menjadi **6 Wood**. (Pickaxe tidak bisa.)

| Pohon | Musim berbuah | Harga bibit | Buah |
|---|---|---|---|
| Lemon | Spring | 250 | Lemon |
| Persik | Summer | 300 | Peach |
| Pisang | Summer | 280 | Banana (baru) |
| Apel | Autumn | 300 | Apple |
| Jeruk | Winter | 320 | Orange (baru) |

Debug **F2** juga memberi 2 Bibit Apel + 2 Bibit Lemon.

## File
| File | Isi |
|---|---|
| `scripts/farming/fruit_tree.gd` | `FruitTree` (turunan `PlacedObject`): umur, buah (NONE/UNRIPE/RIPE), panen, goyang, simpan/muat. |
| `scenes/trees/fruit_tree_*.tscn` (5) | Node2D + Sprite2D + StaticBody2D (batang). Variabel export: `tree_key`, `fruit_id`, `season`, `footprint (-1,-1,3,2)`. |
| `data/items/sapling_*.tres` (5) | Kategori Benih, `placeable` = scene pohon. Ikon dari sprite Fruit_Tree_Small (diperkecil 2:1). |
| `data/items/orange.tres`, `banana.tres` | Buah baru (ikon asli Icons_16x16_Crops). |
| `assets/modern_farm/objects/fruit_trees/` | Sprite asli: Small, Fruitless, Unripe, Ripe untuk 5 pohon. |

## File yang diubah
| File | Perubahan |
|---|---|
| `scripts/crafting/placed_object.gd` | Hook baru `accepts_tool()`, `returns_self()`, `display_name()`. |
| `scripts/systems/main.gd` | `_pick_up_placed(obj, tool_kind)`; pesan "ditanam" untuk bibit. |
| `data/shop/general_store.tres` | Bibit pohon dijual Mira. |
| `scripts/inventory/inventory_manager.gd` | Item debug F2 + bibit. |

Pohon memakai sistem pasang objek dari Phase 14 (FarmMap.place_object), jadi otomatis tersimpan di save
(`placed`: umur & status buah) dan tile-nya tidak bisa dicangkul.
