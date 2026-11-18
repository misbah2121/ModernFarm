# Modern Farm - Phase 7 (Shop, Buying, Selling, Economy)
Kontrol: WASD jalan | E bicara / buka toko / panen / tidur | 1-8 pilih | SPACE alat | I tas | F2 item uji | N tidur (debug).

Gold awal: 500 (pojok kanan atas, "GOLD: 500"). Gold tidak pernah bisa negatif.
Toko Serba Ada (kios kuning di alun-alun Village, pemilik: Mira). Cara membuka:
- Berdiri di depan konter kios (ada papan "TOKO [E]"), tekan E, atau
- Bicara dengan Mira -> pilih "Belanja di Toko Serba Ada".

Panel toko (waktu berhenti selama terbuka):
- Tab BELI: klik kiri = beli 1, klik kanan = beli 5. Alat (Axe, Fishing Rod) hanya bisa dibeli 1 kali.
- Tab JUAL: klik kiri = jual 1, klik kanan = jual setumpuk, tombol "Jual semua hasil panen".
  Alat tidak bisa dijual (digambar redup).
- A / D = ganti tab, roda mouse = gulir, ESC atau I = tutup.

Barang toko = res://data/shop/general_store.tres (daftar id item). Harga beli = ItemData.buy_price,
harga jual = ItemData.sell_price. Toko baru = file .tres ShopData baru + isi `shop` di NpcData pemiliknya.
Axe & Fishing Rod sudah bisa dibeli, fungsinya aktif di Phase 10 & Phase 8.
