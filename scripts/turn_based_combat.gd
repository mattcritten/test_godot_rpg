extends Control
class_name TurnBasedCombat

signal battle_ended(player_won: bool)
signal battle_closed

@export var player_max_hp: int = 30
@export var enemy_max_hp: int = 24
@export var player_attack_damage: int = 7
@export var spell_damage: int = 11
@export var enemy_attack_damage: int = 5
@export var attack_stamina_cost: int = 4
@export var spell_magic_cost: int = 5
@export var guard_stamina_restore: int = 5

@onready var title_label: Label = %TitleLabel
@onready var player_hp_label: Label = %PlayerHpLabel
@onready var player_magic_label: Label = %PlayerMagicLabel
@onready var player_stamina_label: Label = %PlayerStaminaLabel
@onready var enemy_hp_label: Label = %EnemyHpLabel
@onready var message_label: Label = %MessageLabel
@onready var attack_button: Button = %AttackButton
@onready var spell_button: Button = %SpellButton
@onready var guard_button: Button = %GuardButton
@onready var close_button: Button = %CloseButton
@onready var player_battler: Node2D = %PlayerBattler
@onready var enemy_battler: Node2D = %EnemyBattler
@onready var action_effect_label: Label = %ActionEffectLabel

var enemy_hp: int
var enemy_name: String = "Slime"
var is_player_turn: bool = true
var is_guarding: bool = false
var battle_active: bool = false
var player_stats: PlayerStats
var player_start_position: Vector2
var enemy_start_position: Vector2
var action_effect_start_position: Vector2


func _ready() -> void:
	attack_button.pressed.connect(_on_attack_pressed)
	spell_button.pressed.connect(_on_spell_pressed)
	guard_button.pressed.connect(_on_guard_pressed)
	close_button.pressed.connect(_on_close_pressed)
	player_start_position = player_battler.position
	enemy_start_position = enemy_battler.position
	action_effect_start_position = action_effect_label.position
	hide()


func start_battle(stats: PlayerStats, new_enemy_name: String = "Slime") -> void:
	player_stats = stats
	enemy_name = new_enemy_name
	enemy_hp = enemy_max_hp
	is_player_turn = true
	is_guarding = false
	battle_active = true
	player_battler.position = player_start_position
	enemy_battler.position = enemy_start_position
	player_battler.scale = Vector2.ONE
	enemy_battler.scale = Vector2.ONE
	player_battler.modulate = Color.WHITE
	enemy_battler.modulate = Color.WHITE
	action_effect_label.position = action_effect_start_position
	action_effect_label.hide()
	show()
	title_label.text = "Battle: %s" % enemy_name
	message_label.text = "A %s blocks your path." % enemy_name
	close_button.hide()
	_set_action_buttons_enabled(true)
	_update_hp_labels()


func _on_attack_pressed() -> void:
	if not _can_take_player_action():
		return

	if not player_stats.spend_stamina(attack_stamina_cost):
		message_label.text = "You need %d stamina to attack." % attack_stamina_cost
		return

	is_player_turn = false
	_set_action_buttons_enabled(false)
	await _play_attack_animation()
	enemy_hp = maxi(enemy_hp - player_attack_damage, 0)
	message_label.text = "You hit the %s for %d damage." % [enemy_name, player_attack_damage]
	_update_hp_labels()

	if enemy_hp == 0:
		_finish_battle(true)
		return

	_start_enemy_turn()


func _on_spell_pressed() -> void:
	if not _can_take_player_action():
		return

	if not player_stats.spend_magic(spell_magic_cost):
		message_label.text = "You need %d magic to cast." % spell_magic_cost
		return

	is_player_turn = false
	_set_action_buttons_enabled(false)
	await _play_spell_animation()
	enemy_hp = maxi(enemy_hp - spell_damage, 0)
	message_label.text = "You cast a spell for %d damage." % spell_damage
	_update_hp_labels()

	if enemy_hp == 0:
		_finish_battle(true)
		return

	_start_enemy_turn()


func _on_guard_pressed() -> void:
	if not _can_take_player_action():
		return

	is_player_turn = false
	_set_action_buttons_enabled(false)
	is_guarding = true
	player_stats.restore_stamina(guard_stamina_restore)
	await _play_guard_animation()
	message_label.text = "You guard and recover %d stamina." % guard_stamina_restore
	_update_hp_labels()
	_start_enemy_turn()


func _on_close_pressed() -> void:
	hide()
	battle_closed.emit()


func _can_take_player_action() -> bool:
	return battle_active and is_player_turn


func _start_enemy_turn() -> void:
	is_player_turn = false
	_set_action_buttons_enabled(false)
	await get_tree().create_timer(0.65).timeout

	if not battle_active:
		return

	var incoming_damage: int = enemy_attack_damage
	if is_guarding:
		incoming_damage = ceili(float(incoming_damage) * 0.5)
		is_guarding = false

	await _play_enemy_attack_animation()
	player_stats.take_damage(incoming_damage)
	message_label.text = "The %s hits you for %d damage." % [enemy_name, incoming_damage]
	_update_hp_labels()

	if player_stats.health == 0:
		_finish_battle(false)
		return

	is_player_turn = true
	_set_action_buttons_enabled(true)


func _finish_battle(player_won: bool) -> void:
	battle_active = false
	is_player_turn = false
	_set_action_buttons_enabled(false)
	close_button.show()

	if player_won:
		message_label.text = "You defeated the %s." % enemy_name
	else:
		message_label.text = "You were defeated."

	battle_ended.emit(player_won)


func _set_action_buttons_enabled(enabled: bool) -> void:
	attack_button.disabled = not enabled
	spell_button.disabled = not enabled
	guard_button.disabled = not enabled


func _update_hp_labels() -> void:
	if player_stats != null:
		player_hp_label.text = "Health: %d / %d" % [player_stats.health, player_stats.max_health]
		player_magic_label.text = "Magic: %d / %d" % [player_stats.magic, player_stats.max_magic]
		player_stamina_label.text = "Stamina: %d / %d" % [player_stats.stamina, player_stats.max_stamina]

	enemy_hp_label.text = "%s HP: %d / %d" % [enemy_name, enemy_hp, enemy_max_hp]


func _play_attack_animation() -> void:
	action_effect_label.text = "Slash!"
	action_effect_label.position = action_effect_start_position
	action_effect_label.show()

	var tween: Tween = create_tween()
	tween.tween_property(player_battler, "position", player_start_position + Vector2(130, -60), 0.16)
	tween.tween_property(enemy_battler, "modulate", Color(1, 0.35, 0.35, 1), 0.08)
	tween.tween_property(enemy_battler, "position", enemy_start_position + Vector2(24, 0), 0.06)
	tween.tween_property(enemy_battler, "position", enemy_start_position - Vector2(24, 0), 0.06)
	tween.tween_property(enemy_battler, "position", enemy_start_position, 0.06)
	tween.tween_property(enemy_battler, "modulate", Color.WHITE, 0.1)
	tween.tween_property(player_battler, "position", player_start_position, 0.18)
	await tween.finished
	action_effect_label.hide()


func _play_spell_animation() -> void:
	action_effect_label.text = "Spell!"
	action_effect_label.position = action_effect_start_position
	action_effect_label.show()

	var tween: Tween = create_tween()
	tween.tween_property(player_battler, "modulate", Color(0.55, 0.75, 1, 1), 0.12)
	tween.tween_property(action_effect_label, "position", Vector2(640, 120), 0.01)
	tween.tween_property(action_effect_label, "position", Vector2(760, 170), 0.18)
	tween.tween_property(enemy_battler, "modulate", Color(0.45, 0.65, 1, 1), 0.1)
	tween.tween_property(enemy_battler, "scale", Vector2(1.14, 1.14), 0.1)
	tween.tween_property(enemy_battler, "scale", Vector2.ONE, 0.12)
	tween.tween_property(enemy_battler, "modulate", Color.WHITE, 0.1)
	tween.tween_property(player_battler, "modulate", Color.WHITE, 0.1)
	await tween.finished
	action_effect_label.hide()


func _play_guard_animation() -> void:
	action_effect_label.text = "Guard!"
	action_effect_label.position = action_effect_start_position
	action_effect_label.show()

	var tween: Tween = create_tween()
	tween.tween_property(player_battler, "modulate", Color(0.65, 1, 0.75, 1), 0.12)
	tween.tween_property(player_battler, "scale", Vector2(1.08, 1.08), 0.12)
	tween.tween_property(player_battler, "scale", Vector2.ONE, 0.16)
	tween.tween_property(player_battler, "modulate", Color.WHITE, 0.12)
	await tween.finished
	action_effect_label.hide()


func _play_enemy_attack_animation() -> void:
	action_effect_label.text = "Enemy!"
	action_effect_label.position = action_effect_start_position
	action_effect_label.show()

	var tween: Tween = create_tween()
	tween.tween_property(enemy_battler, "position", enemy_start_position + Vector2(-120, 55), 0.18)
	tween.tween_property(player_battler, "modulate", Color(1, 0.45, 0.45, 1), 0.08)
	tween.tween_property(player_battler, "position", player_start_position - Vector2(28, 0), 0.06)
	tween.tween_property(player_battler, "position", player_start_position + Vector2(28, 0), 0.06)
	tween.tween_property(player_battler, "position", player_start_position, 0.06)
	tween.tween_property(player_battler, "modulate", Color.WHITE, 0.1)
	tween.tween_property(enemy_battler, "position", enemy_start_position, 0.16)
	await tween.finished
	action_effect_label.hide()
