class_name ItemStack
extends RefCounted
## Satu tumpukan item di satu slot inventory: jenis item + jumlah.

var item: ItemData
var count: int = 1


func _init(p_item: ItemData = null, p_count: int = 1) -> void:
	item = p_item
	count = p_count


## Sisa tempat di tumpukan ini.
func room() -> int:
	return item.max_stack - count


func same_item(other: ItemStack) -> bool:
	return other != null and other.item.id == item.id
