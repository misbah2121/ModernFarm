class_name ToolData
extends Resource
## Data alat / bungkus benih (Resource). File .tres ada di res://data/tools/.
## Dipakai sementara sebagai isi hotbar; Phase 5 menggantinya dengan Inventory.

## FISHING_ROD (Phase 8) ditangani FishingController, bukan FarmSoil.
## AXE / PICKAXE (Phase 10) memukul ResourceNode (pohon / batu), ditangani Main.
enum Kind { HOE, WATERING_CAN, SEEDS, FISHING_ROD, AXE, PICKAXE }

@export var id: String = ""
@export var tool_name: String = ""
@export var kind: Kind = Kind.HOE
@export var icon: Texture2D
## Disimpan untuk sistem stamina (belum dipakai di Phase 2).
@export var stamina_cost: int = 0
## Nama animasi player: &"dig", &"water", atau kosong (instan, tanpa animasi).
@export var animation: StringName = &""
## Jangkauan dalam tile di depan player (Phase 2 hanya memakai 1).
@export var tool_range: int = 1
## Frame animasi saat efek alat terjadi (mengenai tanah).
@export var hit_frame: int = 0
## Hanya untuk kind == SEEDS.
@export var crop: CropData
