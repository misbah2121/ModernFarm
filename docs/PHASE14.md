# Phase 14: Crafting & Mesin

## Cara main
| Tombol | Fungsi |
|---|---|
| **C** (HP: tombol **BUAT**) | Buka menu Kerajinan. Klik resep, lalu klik **BUAT** (atau W/S + E). |
| **SPACE** sambil memegang mesin | Pasang mesin di tile depan player (hanya di Farm, di rumput / tanah jalan). |
| **E** di depan mesin | Sprinkler: info. Cheese Machine: masukkan Milk / ambil Cheese. Peti: buka isi peti. |
| **Pickaxe / Axe** ke mesin | Ambil kembali mesin ke tas (Peti harus kosong; isi Cheese Machine ikut kembali). |

Mesin harus ada di **hotbar** (slot 1-8) agar bisa dipilih lalu dipasang.

## Resep (data/recipes/*.tres)
| Hasil | Bahan | Fungsi |
|---|---|---|
| Sprinkler | 3 Copper Ore + 1 Iron Ore | Tiap pagi menyiram 4 tile tanah olahan (atas, bawah, kiri, kanan). |
| Peti Kayu | 25 Wood | Menyimpan 24 tumpukan barang. |
| Cheese Machine | 20 Wood + 10 Stone + 2 Iron Ore | 1 Milk -> 1 Cheese dalam 3 jam game. |

Debug: **F2** sekarang juga memberi Wood, Stone, Copper Ore, Iron Ore.

## File baru
| File | Isi |
|---|---|
| `scripts/crafting/recipe_data.gd` | Resource `RecipeData`: result, result_count, ingredients[], amounts[], order. `check()`, `craft()`. |
| `scripts/crafting/placed_object.gd` | Dasar semua mesin: `footprint` (tile yang ditempati), `interact()`, `on_day_started()`, simpan/muat. |
| `scripts/crafting/sprinkler.gd` + `scenes/crafting/sprinkler.tscn` | Animasi dari `Sprinkler_Anim_16x16.png` (frame 48x48). |
| `scripts/crafting/cheese_machine.gd` + `scenes/crafting/cheese_machine.tscn` | Animasi dari `Cheese_Machine_Anim_16x16.png` (frame 64x48), footprint 3 tile. |
| `scripts/crafting/storage_chest.gd` + `scenes/crafting/storage_chest.tscn` | Trunk_Closed_1 / Trunk_Open_1, footprint 2 tile. |
| `scripts/ui/craft_panel.gd` (HUD/CraftPanel) | Menu Kerajinan. |
| `scripts/ui/chest_panel.gd` (HUD/ChestPanel) | Isi peti (atas) + tas (bawah). Klik kiri = setumpuk, klik kanan = 1. |
| `data/items/sprinkler.tres`, `cheese_machine.tres`, `storage_chest.tres` | Kategori baru **Mesin** (`ItemData.Category.MACHINE`), field baru `placeable` (scene objek). |

## File yang diubah
| File | Perubahan |
|---|---|
| `scripts/inventory/item_data.gd` | Kategori `MACHINE` ("Mesin"), `@export var placeable: PackedScene`, `is_placeable()`. |
| `scripts/player/player.gd` | Signal `place_requested(item, cell)`: SPACE sambil memegang mesin. |
| `scripts/world/farm_map.gd` | `can_place()`, `place_object()`, `object_at()`, `remove_object()`, `placed_to_save()/placed_from_save()`. Tile mesin tidak bisa dicangkul. |
| `scripts/farming/farm_soil.gd` | `water_cell(cell)` untuk Sprinkler. |
| `scripts/systems/main.gd` | Pasang / ambil mesin, E pada mesin, panel Craft & Peti, simpan `placed`. Bantuan F1: "C buat". |
| `scripts/systems/game_manager.gd` | Input Map action **craft** = C (didaftarkan otomatis). |
| `scripts/ui/touch_controls.gd` | Tombol **BUAT**. |
| `scripts/inventory/inventory_manager.gd` | Item debug F2 + bahan kerajinan. |

## Ikon
Sprinkler memakai sprite asli 16x16. Ikon Cheese Machine (`Icons_16x16_Craft_Cheese_Machine.png`) dan
Peti (`Icons_16x16_Craft_Chest.png`) dibuat dari sprite asli pack (dipotong lalu diperkecil 2:1), karena pack
tidak punya ikon 16x16 untuk keduanya.

## Menambah resep baru
1. Buat item baru di `data/items/` (isi `placeable` jika bisa dipasang).
2. Duplikat salah satu file `data/recipes/*.tres`, ganti `result`, `ingredients`, `amounts`, `order`.
Resep otomatis muncul di menu Kerajinan.
