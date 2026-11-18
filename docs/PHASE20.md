# Phase 20 – Anjing Peliharaan

Anjing Labrador coklat yang tadinya hanya pajangan di Farm sekarang **hidup**:

| Waktu / kondisi | Perilaku |
|---|---|
| Siang (06:00–20:00) | Mengikuti player di Farm (jalan / lari). Kalau player jauh, ia jalan-jalan di dekat rumahnya. Sesekali menggonggong. |
| Mangkuk terisi | Lari ke mangkuk lalu makan (animasi makan asli). |
| Malam (20:00–06:00) atau hujan | Tidur di dalam rumah anjing (animasi `Dogs_Doghouse_Sleeping` asli). |
| Saat player naik traktor | Tidak mengikuti. |

**Interaksi (tombol E):**
- E pada anjing = **elus**. +15 hati sekali sehari, muncul hati merah di atasnya, dan anjing menggonggong senang.
- E pada **mangkuk merah** di kanan rumah anjing sambil memegang **Makanan Anjing** = isi mangkuk.
  - Makanan Anjing dijual Barnaby seharga 25 Gold.
  - Anjing yang makan dapat +10 hati/hari. Kalau lupa diberi makan, −10.
- E pada rumah anjing di malam hari = "Zzz…".
- Penanda biru menunjukkan ikon hati (elus) dan mangkuk. Ikon berubah menjadi tanda dilarang kalau sudah dielus atau sudah makan.

**Hadiah kesetiaan:** mulai 3 hati, setiap pagi anjing yang kemarin makan kadang **membawa barang**: kayu, batu, ranting, bijih tembaga, benih, dan sesekali truffle. Barang muncul di depan rumah anjing (ItemPickup) disertai pesan.

## File
**Baru:**
- `scripts/animals/pet_dog.gd` (class PetDog)
- `data/items/dog_food.tres`
- `assets/modern_farm/animals/dog/` (sheet tidur + mangkuk dari pack)
- `icons/Icon_Heart_9x8.png`, `icons/Icon_Dog_Food.png`

**Diubah:**
- `scenes/world/props/dog_labrador.tscn`: sekarang CharacterBody2D + script PetDog. Instance `Objects/Dog` di `farm.tscn` tetap sama.
- `animal_manager.gd`: data anjing (nama, hati, makan, mangkuk), ikut disimpan.
- `farm_map.gd`: `dog.setup()`.
- `main.gd`: E untuk anjing, mangkuk, dan rumah anjing.
- `interact_hint.gd`
- `barnaby_ranch.tres`

**Sprite (semua asli Modern Farm):**
- `Dog_Labrador_Brown_16x16.png`: frame 48x32. y64 diam, y128 jalan, y192 lari, y256 makan, y320 gonggong.
- `Dogs_Doghouse_Sleeping_16x16.png`: frame 32x48, baris 0.
- `Dog_Bowl_Red_Empty/Full`.

Tidak ada Input Map baru. Nama anjing default **Coklat**. Untuk mengganti nama, ubah `DOG_NAMES[0]` di `animal_manager.gd`.
