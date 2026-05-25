extends Resource
class_name PlayerStats

signal stats_changed

@export var max_health: int = 40
@export var max_magic: int = 20
@export var max_stamina: int = 25

var health: int = max_health
var magic: int = max_magic
var stamina: int = max_stamina


func reset() -> void:
	health = max_health
	magic = max_magic
	stamina = max_stamina
	stats_changed.emit()


func take_damage(amount: int) -> void:
	health = maxi(health - amount, 0)
	stats_changed.emit()


func restore_health(amount: int) -> void:
	health = mini(health + amount, max_health)
	stats_changed.emit()


func restore_magic(amount: int) -> void:
	magic = mini(magic + amount, max_magic)
	stats_changed.emit()


func restore_stamina(amount: int) -> void:
	stamina = mini(stamina + amount, max_stamina)
	stats_changed.emit()


func spend_magic(amount: int) -> bool:
	if magic < amount:
		return false

	magic -= amount
	stats_changed.emit()
	return true


func spend_stamina(amount: int) -> bool:
	if stamina < amount:
		return false

	stamina -= amount
	stats_changed.emit()
	return true
