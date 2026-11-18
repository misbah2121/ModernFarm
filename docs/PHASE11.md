# Modern Farm - Phase 11 (Quest, Events, NPC Schedule)
Kontrol: WASD jalan | E bicara / toko / hewan / pungut / tidur | J daftar tugas | I tas | SPACE alat | N tidur (debug).

TUGAS (QuestManager, data: res://data/quests/*.tres)
- Bicara dengan NPC -> pilihan "Tugas: ..." = terima tugas.
- Jenis: HARVEST (panen), FISH (tangkap ikan), GATHER (kumpulkan dari pohon/batu/barang pungut/hewan),
  DELIVER (bawa item ke pemberi tugas -> pilihan "Serahkan: ...").
- Tugas yang tercapai: kembali ke pemberi tugas -> "Laporkan tugas: ..." -> hadiah (Gold, item, friendship).
- J = daftar tugas + kalender acara. Pelacak 2 tugas aktif tampil di kiri atas.
  Panen Pertama (Lila) | Telur untuk Mira | Kayu Bakar (Barnaby) | Pemancing Pemula (Toby)
  Tembaga untuk Pagar (Barnaby, setelah Kayu Bakar) | Pai Labu Nenek (Mira, musim gugur)
  Kristal Berkilau (Lila, setelah Panen Pertama) | Ikan Merah Legendaris (Toby, setelah Pemancing Pemula)

ACARA KALENDER (EventManager, data: res://data/events/*.tres) - pengumuman muncul pagi hari:
  Spring 1 Hari Pertama | Spring 13 Festival Bunga (NPC berkumpul di alun-alun, friendship bicara 2x)
  Summer 1 Kiriman Benih (+5 Corn Seeds) | Summer 11 Hari Nelayan (ikan dijual 1.5x)
  Autumn 16 Festival Panen (berkumpul, hasil panen 1.25x) | Winter 25 Malam Bintang (berkumpul, +100 Gold, friendship 3x)

JADWAL NPC (NpcData.schedule / rain_schedule, format "HH:MM NamaTempat")
- NPC berjalan sendiri antar tempat (jalur AStarGrid2D menghindari bangunan & air), masuk rumah malam hari.
- Saat hujan memakai rain_schedule. Saat acara berkumpul, semua NPC ke alun-alun 09:00-20:00.
- Toko punya jam buka: Toko Serba Ada 09:00-17:00, Peternakan Barnaby 08:00-18:00.
- Tempat = Marker2D di scenes/village/village.tscn > Places (grup "indoor" = pintu rumah,
  metadata "wander" = jarak jalan-jalan). Pindahkan marker di editor untuk mengubah rute NPC.
