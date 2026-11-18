# Modern Farm - Phase 9 (Animals, Barn, Coop, Animal Products)
Kontrol: WASD jalan | E bicara / toko / panen / hewan / tidur | 1-8 pilih | SPACE alat / pancing | I tas | F2 item uji (+10 Animal Feed) | N tidur (debug).

Membeli hewan: bicara dengan Barnaby di Village -> "Belanja di Peternakan Barnaby".
  Chicken 400 G (Coop, telur tiap hari) | Cow 1200 G (Barn, susu tiap hari)
  Sheep 900 G (Barn, wol tiap 3 hari, butuh Shears) | Pig 600 G (Barn, belum ada produk)
  Animal Feed 20 G | Shears 300 G. Barnaby juga membeli Egg, Milk, Wool.
Kapasitas: Coop 4 ayam, Barn 4 hewan besar. Hewan langsung muncul di kandang terbuka (AnimalPen)
di selatan Barn & Coop pada peta Farm.

Merawat hewan (tombol E sambil menghadap hewan):
- Produk siap (icon melayang di atas kepala) -> E = ambil (Sheep: pegang Shears).
- Selain itu E = elus (+15 friendship, sekali sehari) dan lihat status (hati, kenyang/lapar).
Makan:
- Hari Sunny/Cloudy dan bukan Winter: hewan merumput sendiri (gratis).
- Hujan/badai/Winter: tiap hewan mengambil 1 Animal Feed dari tempat pakan (Feeder) tiap pagi.
  Isi tempat pakan: pegang Animal Feed, hadap Feeder, tekan E (maks. 12).
- Hewan yang makan hari ini menghasilkan produk besok pagi. Tidak makan = friendship -20, tidak berproduksi.

Data: res://data/animals/*.tres (AnimalData). Hewan baru = file AnimalData baru + id di
res://data/shop/barnaby_ranch.tres (animals). Kandang terbuka = Areas/AnimalPen di farm.tscn (bisa diubah di editor).
