extends Resource
class_name InventoryItem

enum EffectType {
	RESTORE_HEALTH,
	RESTORE_MAGIC,
	RESTORE_STAMINA,
}

@export var item_id: StringName
@export var display_name: String = "Item"
@export var effect_type: EffectType = EffectType.RESTORE_HEALTH
@export var effect_amount: int = 10
@export var quantity: int = 1


func apply_to(stats: PlayerStats) -> void:
	match effect_type:
		EffectType.RESTORE_HEALTH:
			stats.restore_health(effect_amount)
		EffectType.RESTORE_MAGIC:
			stats.restore_magic(effect_amount)
		EffectType.RESTORE_STAMINA:
			stats.restore_stamina(effect_amount)
