# Phase 23 – Semua Ternak + Warna Acak + Anak Hewan

## 1. Hewan baru di Peternakan Barnaby
Semua sprite memakai sheet asli pack (`Animals_16x16`).

| Hewan | Kandang | Harga | Kegunaan |
|---|---|---|---|
| **Ayam Jago** (Rooster) | Coop | 700 | Selama ada ayam jago yang kenyang: ayam kadang bertelur **Telur Emas** (±12%), **anak ayam bisa menetas**, dan hewan Coop lain dapat +3 hati-poin setiap pagi. |
| **Kelinci** (Rabbit) | Coop | 800 | **Bulu Kelinci** setiap 3 hari (ambil dengan tangan / E). |
| **Kambing** (Goat) | Barn | 1000 | **Susu Kambing** setiap 2 hari. |
| **Keledai** (Donkey) | Barn | 1500 | Penolong: setiap pagi (jika kemarin makan) membawa **3 Animal Feed** ke tempat pakan. |

Kapasitas kandang naik: **Coop 8**, **Barn 6** (anak hewan ikut dihitung).

### Produk & resep baru
| Item | Cara dapat | Harga jual |
|---|---|---|
| Susu Kambing | dari kambing | 65 |
| **Keju Kambing** | Cheese Machine: pegang Susu Kambing + E (3 jam) | 160 |
| Bulu Kelinci | dari kelinci | 150 |
| **Benang Bulu** | Kerajinan (C): 2 Bulu Kelinci + 1 Wool | 450 |
| Telur Emas | ayam (perlu ayam jago) | 350 |
| **Omelet Emas** | Dapur: Telur Emas + Keju Kambing. Energi +150, buff jalan cepat + mudah memancing 4 jam | 650 |

Cheese Machine sekarang menerima **Milk** (→ Cheese) dan **Susu Kambing** (→ Keju Kambing). Bahan yang sedang diproses ikut tersimpan.

## 2. Warna acak saat membeli
Setiap hewan yang dibeli mendapat warna acak dari sheet pack:
- Ayam & ayam jago: 7 warna (Putih, Coklat, Coklat Muda, Hitam-Coklat, Emas, Abu-abu, Kuning)
- Sapi: 2 warna
- Domba: 5 warna
- Babi: 5 warna
- Bebek: 4 warna
- Kambing: 4 warna
- Kelinci: 6 warna
- Keledai: 4 warna

Warna ditampilkan saat membeli dan saat mengelus (contoh: "Molly (Chicken Emas)"). Warna ikut tersimpan. Hewan dari save lama tetap memakai warna lamanya.

## 3. Anak hewan
- Setiap pagi, satu jenis hewan berpeluang **15%** melahirkan 1 anak jika:
  - ada **2 hewan dewasa** sejenis yang kemarin makan,
  - keduanya punya **hati ≥ 2**,
  - kandangnya masih ada tempat.
- Ayam butuh **1 ayam + 1 ayam jago**.
- Maksimal satu kelahiran per hari. Muncul pesan "Seekor anak … lahir di kandang!".
- Sprite anak memakai sheet asli: Anak Sapi, Anak Kambing, Anak Domba, Anak Babi, Anak Keledai, Anak Bebek, Anak Kelinci, Anak Ayam. Warnanya biasanya mengikuti induk.
- Anak hewan lebih kecil dan lebih lambat, tidak menghasilkan produk, tapi bisa dielus dan ikut makan.
- Setelah beberapa hari (ayam/bebek/kelinci 4, domba/babi/kambing 5, sapi/keledai 6) anak **tumbuh dewasa** otomatis. Anak ayam kadang tumbuh menjadi **ayam jago** (25%).

## Perbaikan
Hewan tidak lagi bergerombol bergerak bersamaan saat banyak hewan dimuat sekaligus. Sebelumnya semua hewan mendapat seed acak yang sama.

## File
**Baru:**
- `data/animals/goat.tres`, `rabbit.tres`, `donkey.tres`, `rooster.tres`
- `data/items/goat_milk.tres`, `goat_cheese.tres`, `rabbit_fur.tres`, `yarn.tres`, `golden_egg.tres`, `golden_omelet.tres`
- `data/recipes/yarn.tres`, `cook_golden_omelet.tres`
- Asset:
  - `assets/modern_farm/animals/<jenis>/` (sheet warna & anak)
  - `icons/Icon_Goat_Milk`, `Icon_Goat_Cheese`, `Icon_Golden_Egg`, `Icon_Yarn`, `Icon_Dish_Golden_Omelet`, `Icons_16x16_Resources_Wool_Grey`

**Diubah:**
- `scripts/animals/animal_data.gd`: bonus, penolong, varian, data anak, helper `sheet_for()` / `rows_for()`
- `scripts/animals/animal_manager.gd`: warna acak, kelahiran, tumbuh dewasa, Telur Emas, keledai, ayam jago, sinyal `message`, simpan `variant/baby/age/bonus`
- `scripts/animals/farm_animal.gd`: sprite per warna/anak, bangun ulang saat tumbuh, frame kosong dilewati, kaki otomatis
- `scripts/crafting/cheese_machine.gd`: Susu Kambing → Keju Kambing
- `scripts/systems/main.gd`: toast `AnimalManager.message`
- `scripts/ui/shop_panel.gd`: pesan beli menampilkan warna
- `scripts/ui/interact_hint.gd`: ikon hasil mesin keju
- `scripts/farming/farm_workers.gd`: pekerja ikut mengambil Telur Emas
- `data/animals/*.tres` (lama): daftar warna + anak
- `data/shop/barnaby_ranch.tres`: 4 hewan baru

Tidak ada Input Map baru. Tidak ada node baru di scene. Semua hewan tetap dibuat lewat kode oleh FarmMap.
