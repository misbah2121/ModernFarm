class_name FarmBoard
extends PlacedObject
## Phase 19: PAPAN FARM (Sign_2_16x16.png dari pack). E di depannya = buka panel Papan Farm
## (HUD/FarmBoardPanel): rekrut / berhentikan pekerja dan perbaiki / upgrade traktor.
## Sudah terpasang di dekat rumah saat game baru; bisa dibuat lagi (C) lalu dipasang dengan SPACE.


func interact() -> String:
	return "Papan Farm: tekan E untuk mengatur pekerja dan traktor."


func display_name() -> String:
	return "Papan Farm"
