extends Node


signal inventory_updated()


enum InventoryItems {
	KEY = 1
}


var inventory_items := []


func add_item(item_id: int) -> void:
	inventory_items.append(item_id)
	emit_signal("inventory_updated")


func remove_item(item_id: int) -> void:
	inventory_items.erase(item_id)
	emit_signal("inventory_updated")


func has_item(item_id: int) -> bool:
	return inventory_items.has(item_id)



func _on_GameStateHelper_loading_data(data):
	emit_signal("inventory_updated")
