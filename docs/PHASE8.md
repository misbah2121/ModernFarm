# Modern Farm - Phase 8 (Fishing)
Kontrol: WASD jalan | 1-8 pilih | SPACE alat / pancing | E bicara / toko / panen / tidur / pancing | I tas | F2 item uji (+Fishing Rod) | N tidur (debug).

Cara memancing:
1. Beli Fishing Rod (500 Gold) di Toko Serba Ada, atau tekan F2 untuk uji.
2. Pilih Fishing Rod di hotbar, berdiri di tepi air (sungai Farm, kolam Farm, sungai Village) dan hadapkan ke air
   (air harus 1-2 tile di depan; kotak kursor menunjukkan tile target).
3. Tekan SPACE atau E -> lempar pancing -> tunggu.
4. Saat muncul "!" tekan SPACE / E dalam 1 detik.
5. Mini game: TAHAN SPACE / E / klik kiri untuk menaikkan zona hijau, lepas untuk turun.
   Jaga ikan di dalam zona sampai meteran kanan penuh. Meteran kosong = ikan lolos. ESC = menyerah.
Menekan SPACE / E / ESC sebelum "!" = tarik pancing (batal). Jam berhenti selama mini game.

Tangkapan (res://data/fish/, FishData):
- Blue Fish (Biasa, 30 G) semua musim | Green Fish (Biasa, 45 G) spring & summer
- Orange Fish (Langka, 80 G) summer & autumn, siang, hanya sungai Village
- Red Fish (Sangat Langka, 160 G) hanya saat hujan / badai
- Old Boot & Driftwood (Sampah) langsung didapat tanpa mini game.
Semua ikan bisa dijual di toko. Ikan baru = ItemData baru di data/items/ + FishData baru di data/fish/.
