# Modern Farm - Phase 5 (Inventory, Hotbar, Items)
Kontrol: WASD jalan | 1-8 / , / . pilih slot | SPACE pakai item | E panen / tidur | I buka-tutup inventory | ESC tutup inventory | F2 item uji (debug) | N tidur (debug).

Inventory 24 slot (8 x 3). Baris pertama = hotbar. Di panel inventory:
- Klik kiri: ambil / taruh / tukar / gabung tumpukan.
- Klik kanan: ambil setengah / taruh satu.
- Slot BUANG (kanan bawah): hapus item yang dipegang (alat tidak bisa dibuang).
Waktu berhenti dan player diam selama inventory terbuka.

Benih berkurang 1 tiap berhasil ditanam. Panen masuk ke tas sebagai item (Carrot, Radish, dst). Jika tas penuh, panen ditolak.
Item baru = tambah file .tres di res://data/items/ (ItemData), otomatis terdaftar.
