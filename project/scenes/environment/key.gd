extends Sprite

onready var _interaction_indicator: Sprite = $key_interaction_indicator



func _on_InteractableArea2D_InteractionIndicatorStateChanged(interactable, indicator_visible):
	_interaction_indicator.visible = indicator_visible


func _on_InteractableArea2D_InteractionStarted(interactable, interactor):
	pass # Replace with function body.
	InventoryMgr.add_item(InventoryMgr.InventoryItems.KEY)
	queue_free()
