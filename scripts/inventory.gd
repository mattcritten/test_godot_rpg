extends RefCounted
class_name Inventory

signal inventory_changed

var items: Array[InventoryItem] = []


func add_item(item: InventoryItem, amount: int = 1) -> void:
	if item.item_id == &"" or amount <= 0:
		return

	var existing_item: InventoryItem = _find_item(item.item_id)
	if existing_item != null:
		existing_item.quantity += amount
	else:
		var stored_item: InventoryItem = InventoryItem.new()
		stored_item.item_id = item.item_id
		stored_item.display_name = item.display_name
		stored_item.effect_type = item.effect_type
		stored_item.effect_amount = item.effect_amount
		stored_item.quantity = amount
		items.append(stored_item)

	inventory_changed.emit()


func use_item(item_id: StringName, stats: PlayerStats) -> bool:
	var item: InventoryItem = _find_item(item_id)
	if item == null:
		return false

	if item.quantity <= 0:
		items.erase(item)
		inventory_changed.emit()
		return false

	item.apply_to(stats)
	item.quantity -= 1

	if item.quantity <= 0:
		items.erase(item)

	inventory_changed.emit()
	return true


func get_items() -> Array[InventoryItem]:
	items.sort_custom(_sort_items_by_name)
	return items


func is_empty() -> bool:
	return items.is_empty()


func _find_item(item_id: StringName) -> InventoryItem:
	for item: InventoryItem in items:
		if item.item_id == item_id:
			return item

	return null


func _sort_items_by_name(left: InventoryItem, right: InventoryItem) -> bool:
	return left.display_name < right.display_name
