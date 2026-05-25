from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text()


def test_required_scene_nodes_exist() -> None:
    main_scene = read("scenes/main.tscn")
    battle_scene = read("scenes/battle_ui.tscn")

    for node_name in [
        "StatsLabel",
        "InventoryList",
        "UseItemButton",
        "PickupMessageLabel",
        "HealthPickup",
        "MagicPickup",
        "StaminaPickup",
    ]:
        assert f'name="{node_name}"' in main_scene

    for node_name in [
        "PlayerHpLabel",
        "PlayerMagicLabel",
        "PlayerStaminaLabel",
        "EnemyHpLabel",
        "AttackButton",
        "SpellButton",
        "GuardButton",
        "CloseButton",
    ]:
        assert f'name="{node_name}"' in battle_scene


def test_scripts_reference_existing_systems() -> None:
    main_script = read("scripts/main.gd")
    combat_script = read("scripts/turn_based_combat.gd")

    assert "PlayerStats.new()" in main_script
    assert "Inventory.new()" in main_script
    assert "stats_changed.connect" in main_script
    assert "inventory_changed.connect" in main_script
    assert ".changed.connect" not in main_script
    assert "inventory.use_item" in main_script
    assert "battle_ui.start_battle(player_stats" in main_script
    assert "player_stats.spend_magic" in combat_script
    assert "player_stats.spend_stamina" in combat_script
    assert "player_stats.take_damage" in combat_script


def test_keycodes_use_key_enum() -> None:
    controller_script = read("scripts/top_down_player_controller.gd")

    assert "Array[int]" not in controller_script
    assert "keycode: int" not in controller_script
    assert "Array[Key]" in controller_script
    assert "keycode: Key" in controller_script


if __name__ == "__main__":
    tests = [
        test_required_scene_nodes_exist,
        test_scripts_reference_existing_systems,
        test_keycodes_use_key_enum,
    ]

    for test in tests:
        test()
        print(f"PASS {test.__name__}")
