extends Node2D

const HEALTH_POTION_ICON: Texture2D = preload("res://assets/icons/health_potion.svg")
const MANA_POTION_ICON: Texture2D = preload("res://assets/icons/mana_potion.svg")
const STAMINA_SNACK_ICON: Texture2D = preload("res://assets/icons/stamina_snack.svg")

@onready var player: CharacterBody2D = %Player
@onready var enemy_area: Area2D = %EnemyArea
@onready var enemy_visual: Node2D = %EnemyVisual
@onready var prompt_label: Label = %PromptLabel
@onready var battle_ui: TurnBasedCombat = %BattleUI
@onready var stats_label: Label = %StatsLabel
@onready var inventory_button: Button = %InventoryTitle
@onready var inventory_menu: PanelContainer = %InventoryMenu
@onready var inventory_list: ItemList = %InventoryList
@onready var use_item_button: Button = %UseItemButton
@onready var close_inventory_button: Button = %CloseInventoryButton
@onready var pickup_message_label: Label = %PickupMessageLabel
@onready var health_pickup: Area2D = %HealthPickup
@onready var magic_pickup: Area2D = %MagicPickup
@onready var stamina_pickup: Area2D = %StaminaPickup

var can_start_battle: bool = false
var enemy_defeated: bool = false
var player_stats: PlayerStats = PlayerStats.new()
var inventory: Inventory = Inventory.new()
var selected_item_id: StringName = &""


func _ready() -> void:
	enemy_area.body_entered.connect(_on_enemy_area_body_entered)
	enemy_area.body_exited.connect(_on_enemy_area_body_exited)
	battle_ui.battle_ended.connect(_on_battle_ended)
	battle_ui.battle_closed.connect(_on_battle_closed)
	player_stats.stats_changed.connect(_update_stats_label)
	inventory.inventory_changed.connect(_update_inventory_list)
	inventory_button.pressed.connect(_on_inventory_button_pressed)
	inventory_list.item_selected.connect(_on_inventory_item_selected)
	use_item_button.pressed.connect(_on_use_item_pressed)
	close_inventory_button.pressed.connect(_on_close_inventory_pressed)
	health_pickup.body_entered.connect(_on_health_pickup_body_entered)
	magic_pickup.body_entered.connect(_on_magic_pickup_body_entered)
	stamina_pickup.body_entered.connect(_on_stamina_pickup_body_entered)
	prompt_label.hide()
	pickup_message_label.hide()
	inventory_menu.hide()
	_add_starter_items()
	_update_stats_label()
	_update_inventory_list()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_accept") and can_start_battle and not battle_ui.battle_active:
		_start_battle()


func _start_battle() -> void:
	can_start_battle = false
	prompt_label.hide()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	battle_ui.start_battle(player_stats, "Slime")


func _on_enemy_area_body_entered(body: Node2D) -> void:
	if body != player or enemy_defeated:
		return

	can_start_battle = true
	prompt_label.show()


func _on_enemy_area_body_exited(body: Node2D) -> void:
	if body != player:
		return

	can_start_battle = false
	prompt_label.hide()


func _on_battle_ended(player_won: bool) -> void:
	if player_won:
		enemy_defeated = true
		enemy_area.set_deferred("monitoring", false)
		enemy_visual.hide()


func _on_battle_closed() -> void:
	if player_stats.health == 0:
		player_stats.reset()

	player.set_physics_process(true)

	if not enemy_defeated:
		can_start_battle = true
		prompt_label.show()


func _on_inventory_item_selected(index: int) -> void:
	selected_item_id = inventory_list.get_item_metadata(index) as StringName


func _on_inventory_button_pressed() -> void:
	inventory_menu.show()


func _on_close_inventory_pressed() -> void:
	inventory_menu.hide()


func _on_use_item_pressed() -> void:
	if selected_item_id == &"":
		_show_pickup_message("Select an item first.")
		return

	if inventory.use_item(selected_item_id, player_stats):
		_show_pickup_message("Used item.")
		if inventory.is_empty():
			inventory_menu.hide()
	else:
		selected_item_id = &""
		_show_pickup_message("That item is gone.")


func _on_health_pickup_body_entered(body: Node2D) -> void:
	if body == player:
		_collect_pickup(health_pickup, _make_item(&"health_potion", "Health Potion", InventoryItem.EffectType.RESTORE_HEALTH, 15))


func _on_magic_pickup_body_entered(body: Node2D) -> void:
	if body == player:
		_collect_pickup(magic_pickup, _make_item(&"mana_potion", "Mana Potion", InventoryItem.EffectType.RESTORE_MAGIC, 10))


func _on_stamina_pickup_body_entered(body: Node2D) -> void:
	if body == player:
		_collect_pickup(stamina_pickup, _make_item(&"stamina_snack", "Stamina Snack", InventoryItem.EffectType.RESTORE_STAMINA, 12))


func _collect_pickup(pickup: Area2D, item: InventoryItem) -> void:
	inventory.add_item(item)
	pickup.set_deferred("monitoring", false)
	pickup.hide()
	_show_pickup_message("Picked up %s." % item.display_name)


func _add_starter_items() -> void:
	inventory.add_item(_make_item(&"health_potion", "Health Potion", InventoryItem.EffectType.RESTORE_HEALTH, 15), 1)


func _make_item(item_id: StringName, display_name: String, effect_type: InventoryItem.EffectType, amount: int) -> InventoryItem:
	var item: InventoryItem = InventoryItem.new()
	item.item_id = item_id
	item.display_name = display_name
	item.effect_type = effect_type
	item.effect_amount = amount
	return item


func _update_stats_label() -> void:
	stats_label.text = "Health %d/%d\nMagic %d/%d\nStamina %d/%d" % [
		player_stats.health,
		player_stats.max_health,
		player_stats.magic,
		player_stats.max_magic,
		player_stats.stamina,
		player_stats.max_stamina,
	]


func _update_inventory_list() -> void:
	inventory_list.clear()

	for item: InventoryItem in inventory.get_items():
		inventory_list.add_item("%s x%d" % [item.display_name, item.quantity])
		var item_index: int = inventory_list.get_item_count() - 1
		inventory_list.set_item_metadata(item_index, item.item_id)
		inventory_list.set_item_icon(item_index, _get_item_icon(item.item_id))

	use_item_button.disabled = inventory.is_empty()

	if inventory.is_empty():
		selected_item_id = &""


func _show_pickup_message(message: String) -> void:
	pickup_message_label.text = message
	pickup_message_label.show()


func _get_item_icon(item_id: StringName) -> Texture2D:
	if item_id == &"health_potion":
		return HEALTH_POTION_ICON

	if item_id == &"mana_potion":
		return MANA_POTION_ICON

	if item_id == &"stamina_snack":
		return STAMINA_SNACK_ICON

	return null
