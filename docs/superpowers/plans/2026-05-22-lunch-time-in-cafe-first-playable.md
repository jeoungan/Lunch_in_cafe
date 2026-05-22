# Lunch Time in Cafe First Playable Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a Godot 2D first playable vertical slice where customers order drinks, the player moves between six cafe stations, performs level-gated actions, asks the boss for advanced steps, assembles layered drinks, and finishes a 10-minute shift with settlement.

**Architecture:** Use a data-driven Godot 4 project. Keep core gameplay logic in pure GDScript `RefCounted` classes under `res://src/core` so it can be tested headlessly, then connect those systems to scenes under `res://scenes`. Use simple generated UI and colored panels for the first playable so mechanics can be validated before final illustrated assets are produced.

**Tech Stack:** Godot 4.x, GDScript, Godot headless script tests, `.tres`-free dictionary data for the first pass.

---

## Scope Check

The approved design contains several subsystems: station navigation, menu data, order flow, boss queue, inventory, drink assembly, gesture scoring, shift timing, and settlement. This plan keeps them in one implementation plan because the first playable needs all of them connected in one vertical slice. Each task produces a testable layer, and the final task proves the full loop with an integration test and a playable main scene.

The plan does not implement final art, multiple branches, mobile export, story chains, or deep machine-failure simulation.

## File Structure

- `project.godot`: Godot project settings and main scene path.
- `src/core/project_config.gd`: Shared constants such as shift length, stations, and initial level.
- `src/core/game_defs.gd`: Action, supply, equipment, station, category, and phase constants.
- `src/core/menu_catalog.gd`: At least 30 orderable menu definitions with required actions and visual layers.
- `src/core/player_progress.gd`: Level-to-action unlock rules and recipe gating helpers.
- `src/core/boss_queue.gd`: Boss task queue, task durations, task completion, and assist speedup.
- `src/core/order_model.gd`: Order data object with menu, requests, patience, and state.
- `src/core/order_queue.gd`: Customer order queue, patience ticking, active order lookup.
- `src/core/traffic_schedule.gd`: 10-minute shift traffic phases and spawn intervals.
- `src/core/inventory.gd`: Station supplies, restocking, consuming, and shortage checks.
- `src/core/equipment_state.gd`: Simple equipment speed, capacity, and malfunction state.
- `src/core/drink_assembly.gd`: Layered drink state and manufacturing action log.
- `src/core/quality_scorer.gd`: Quality scoring from recipe order, amounts, requests, wait time, and visual neatness.
- `src/core/gesture_analyzer.gd`: Stir, pour, whip, and topping gesture scoring.
- `src/core/shift_manager.gd`: Shift timer, phase updates, rewards, and end-of-day settlement.
- `src/core/game_state.gd`: Integration facade used by the playable scene.
- `scenes/main/Main.tscn`: First playable main scene.
- `scenes/main/main_controller.gd`: Connects UI controls to `GameState`.
- `scenes/stations/station_view.gd`: Station panel rendering and station transition logic.
- `scenes/manufacturing/ManufacturingScreen.tscn`: Focused manufacturing view.
- `scenes/manufacturing/manufacturing_screen.gd`: Drag and gesture manufacturing controller.
- `tests/test_runner.gd`: Headless test runner that auto-discovers test scripts.
- `tests/test_*.gd`: Pure GDScript tests for each subsystem.

## Test Command

Run all tests with:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected passing output:

```text
ALL TESTS PASSED
```

If the `godot` command is unavailable, install Godot 4.x or add the Godot executable directory to `PATH`, then rerun the same command.

---

### Task 1: Godot Project Skeleton and Test Runner

**Files:**
- Create: `project.godot`
- Create: `src/core/project_config.gd`
- Create: `tests/test_runner.gd`
- Create: `tests/test_project_config.gd`

- [ ] **Step 1: Write the failing project config test**

Create `tests/test_project_config.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_project_name_and_shift_length",
		"test_station_count"
	]

func test_project_name_and_shift_length() -> String:
	var config = load("res://src/core/project_config.gd").new()
	if config.APP_NAME != "Lunch Time in Cafe":
		return "APP_NAME should be Lunch Time in Cafe"
	if config.SHIFT_SECONDS != 600.0:
		return "SHIFT_SECONDS should be 600.0"
	return ""

func test_station_count() -> String:
	var config = load("res://src/core/project_config.gd").new()
	if config.STATIONS.size() != 6:
		return "There should be exactly 6 cafe stations"
	if config.STATIONS[0] != "register":
		return "First station should be register"
	if config.STATIONS[5] != "pickup_counter":
		return "Last station should be pickup_counter"
	return ""
```

- [ ] **Step 2: Add the test runner**

Create `tests/test_runner.gd`:

```gdscript
extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	var test_paths := _collect_tests("res://tests")
	for path in test_paths:
		_run_suite(path)

	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		print("TESTS FAILED: %d" % failures.size())
		quit(1)

func _collect_tests(dir_path: String) -> Array[String]:
	var paths: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		failures.append("Cannot open tests directory: %s" % dir_path)
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_runner.gd":
			paths.append("%s/%s" % [dir_path, file_name])
		file_name = dir.get_next()
	dir.list_dir_end()
	paths.sort()
	return paths

func _run_suite(path: String) -> void:
	var script := load(path)
	if script == null:
		failures.append("Cannot load test suite: %s" % path)
		return
	var suite = script.new()
	for method_name in suite.get_test_methods():
		var result: String = suite.call(method_name)
		if result != "":
			failures.append("%s::%s - %s" % [path, method_name, result])
```

- [ ] **Step 3: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `res://src/core/project_config.gd` does not exist.

- [ ] **Step 4: Add project settings and config**

Create `project.godot`:

```ini
config_version=5

[application]
config/name="Lunch Time in Cafe"
run/main_scene="res://scenes/main/Main.tscn"
config/features=PackedStringArray("4.3")

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"
```

Create `src/core/project_config.gd`:

```gdscript
extends RefCounted
class_name ProjectConfig

const APP_NAME := "Lunch Time in Cafe"
const SHIFT_SECONDS := 600.0
const INITIAL_PLAYER_LEVEL := 1

const STATIONS := [
	"register",
	"sink",
	"main_table",
	"sub_table",
	"display_fridge",
	"pickup_counter"
]
```

- [ ] **Step 5: Run the test to verify it passes**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Commit**

```bash
git add project.godot src/core/project_config.gd tests/test_runner.gd tests/test_project_config.gd
git commit -m "chore: add Godot project skeleton"
```

---

### Task 2: Domain Definitions and 30-Item Menu Catalog

**Files:**
- Create: `src/core/game_defs.gd`
- Create: `src/core/menu_catalog.gd`
- Create: `tests/test_menu_catalog.gd`

- [ ] **Step 1: Write the failing menu catalog test**

Create `tests/test_menu_catalog.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_catalog_has_at_least_30_items",
		"test_catalog_uses_required_categories",
		"test_low_level_menu_can_require_boss_action"
	]

func test_catalog_has_at_least_30_items() -> String:
	var catalog = load("res://src/core/menu_catalog.gd").new()
	var menus := catalog.get_all()
	if menus.size() < 30:
		return "Menu catalog should contain at least 30 items"
	for item in menus:
		if not item.has("id") or not item.has("name") or not item.has("required_actions"):
			return "Each menu item should include id, name, and required_actions"
	return ""

func test_catalog_uses_required_categories() -> String:
	var catalog = load("res://src/core/menu_catalog.gd").new()
	var categories := {}
	for item in catalog.get_all():
		categories[item["category"]] = true
	for category in ["coffee", "tea", "latte", "ade", "powder", "smoothie", "display", "dessert"]:
		if not categories.has(category):
			return "Missing category: %s" % category
	return ""

func test_low_level_menu_can_require_boss_action() -> String:
	var catalog = load("res://src/core/menu_catalog.gd").new()
	var americano := catalog.get_by_id("iced_americano")
	if americano.is_empty():
		return "iced_americano should exist"
	if not "pull_espresso" in americano["required_actions"]:
		return "iced_americano should require pull_espresso"
	if not "add_ice" in americano["required_actions"]:
		return "iced_americano should require add_ice"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `menu_catalog.gd` does not exist.

- [ ] **Step 3: Add domain constants**

Create `src/core/game_defs.gd`:

```gdscript
extends RefCounted
class_name GameDefs

const STATION_REGISTER := "register"
const STATION_SINK := "sink"
const STATION_MAIN_TABLE := "main_table"
const STATION_SUB_TABLE := "sub_table"
const STATION_DISPLAY_FRIDGE := "display_fridge"
const STATION_PICKUP_COUNTER := "pickup_counter"

const ACTION_TAKE_ORDER := "take_order"
const ACTION_PREPARE_PACKAGING := "prepare_packaging"
const ACTION_ADD_ICE := "add_ice"
const ACTION_POUR_WATER := "pour_water"
const ACTION_POUR_SPARKLING_WATER := "pour_sparkling_water"
const ACTION_ADD_PREMADE_BASE := "add_premade_base"
const ACTION_DELIVER_ORDER := "deliver_order"
const ACTION_RESTOCK_SUPPLIES := "restock_supplies"
const ACTION_MEASURE_POWDER := "measure_powder"
const ACTION_DISSOLVE_POWDER := "dissolve_powder"
const ACTION_MEASURE_SYRUP := "measure_syrup"
const ACTION_POUR_MILK := "pour_milk"
const ACTION_PULL_ESPRESSO := "pull_espresso"
const ACTION_STEAM_MILK := "steam_milk"
const ACTION_PIPE_WHIPPED_CREAM := "pipe_whipped_cream"
const ACTION_ADD_TOPPING := "add_topping"
const ACTION_USE_MICROWAVE := "use_microwave"
const ACTION_USE_SMOOTHIE_MACHINE := "use_smoothie_machine"
const ACTION_FIX_BASIC_EQUIPMENT := "fix_basic_equipment"

const CATEGORY_COFFEE := "coffee"
const CATEGORY_TEA := "tea"
const CATEGORY_LATTE := "latte"
const CATEGORY_ADE := "ade"
const CATEGORY_POWDER := "powder"
const CATEGORY_SMOOTHIE := "smoothie"
const CATEGORY_DISPLAY := "display"
const CATEGORY_DESSERT := "dessert"

const PHASE_NORMAL := "normal"
const PHASE_PEAK := "peak"
const PHASE_CLOSING := "closing"

const SUPPLY_CUP := "cup"
const SUPPLY_LID := "lid"
const SUPPLY_SLEEVE := "sleeve"
const SUPPLY_HANDLE := "handle"
const SUPPLY_STRAW := "straw"
const SUPPLY_CARRIER := "carrier"
const SUPPLY_ICE := "ice"
const SUPPLY_MILK := "milk"
const SUPPLY_CREAM := "cream"
const SUPPLY_POWDER := "powder"
const SUPPLY_SYRUP := "syrup"
const SUPPLY_FRUIT_BASE := "fruit_base"
const SUPPLY_TEA := "tea"
const SUPPLY_DESSERT := "dessert"

const EQUIPMENT_ICE_MAKER := "ice_maker"
const EQUIPMENT_ESPRESSO_MACHINE := "espresso_machine"
const EQUIPMENT_FRIDGE := "fridge"
const EQUIPMENT_FREEZER := "freezer"
const EQUIPMENT_MICROWAVE := "microwave"
const EQUIPMENT_SMOOTHIE_MACHINE := "smoothie_machine"
```

- [ ] **Step 4: Add menu catalog**

Create `src/core/menu_catalog.gd`:

```gdscript
extends RefCounted
class_name MenuCatalog

const GameDefs = preload("res://src/core/game_defs.gd")

var _menus: Array[Dictionary] = []

func _init() -> void:
	_menus = [
		_menu("iced_americano", "아이스 아메리카노", GameDefs.CATEGORY_COFFEE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_DELIVER_ORDER], ["cup", "ice", "water", "espresso", "lid"]),
		_menu("hot_americano", "따뜻한 아메리카노", GameDefs.CATEGORY_COFFEE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_DELIVER_ORDER], ["cup", "hot_water", "espresso", "sleeve"]),
		_menu("iced_latte", "아이스 라떼", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "ice", "milk", "espresso", "lid"]),
		_menu("hot_latte", "따뜻한 라떼", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_STEAM_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "espresso", "steamed_milk", "foam", "sleeve"]),
		_menu("vanilla_latte", "바닐라 라떼", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "vanilla_syrup", "milk", "espresso"]),
		_menu("caramel_latte", "카라멜 라떼", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "caramel_syrup", "milk", "espresso"]),
		_menu("mocha_latte", "카페 모카", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_PULL_ESPRESSO, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_PIPE_WHIPPED_CREAM, GameDefs.ACTION_DELIVER_ORDER], ["cup", "chocolate", "espresso", "milk", "whip"]),
		_menu("cold_brew", "콜드브루", GameDefs.CATEGORY_COFFEE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_ADD_PREMADE_BASE, GameDefs.ACTION_DELIVER_ORDER], ["cup", "ice", "cold_brew", "lid"]),
		_menu("iced_tea", "아이스티", GameDefs.CATEGORY_TEA, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_ADD_PREMADE_BASE, GameDefs.ACTION_DELIVER_ORDER], ["cup", "iced_tea_base", "ice", "lid"]),
		_menu("hot_black_tea", "따뜻한 홍차", GameDefs.CATEGORY_TEA, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_DELIVER_ORDER], ["cup", "tea", "hot_water", "sleeve"]),
		_menu("milk_tea", "밀크티", GameDefs.CATEGORY_TEA, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "tea", "milk"]),
		_menu("green_tea_latte", "녹차 라떼", GameDefs.CATEGORY_POWDER, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_POWDER, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_DISSOLVE_POWDER, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "green_tea_powder", "mixed_base", "milk"]),
		_menu("chocolate_latte", "초코 라떼", GameDefs.CATEGORY_POWDER, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_POWDER, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_DISSOLVE_POWDER, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "chocolate_powder", "mixed_base", "milk"]),
		_menu("sweet_potato_latte", "고구마 라떼", GameDefs.CATEGORY_POWDER, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_POWDER, GameDefs.ACTION_POUR_WATER, GameDefs.ACTION_DISSOLVE_POWDER, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "sweet_potato_powder", "mixed_base", "milk"]),
		_menu("strawberry_latte", "딸기 라떼", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "strawberry_base", "ice", "milk"]),
		_menu("blueberry_latte", "블루베리 라떼", GameDefs.CATEGORY_LATTE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_POUR_MILK, GameDefs.ACTION_DELIVER_ORDER], ["cup", "blueberry_base", "ice", "milk"]),
		_menu("lemon_ade", "레몬 에이드", GameDefs.CATEGORY_ADE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_POUR_SPARKLING_WATER, GameDefs.ACTION_DELIVER_ORDER], ["cup", "lemon_base", "ice", "sparkling_water"]),
		_menu("grapefruit_ade", "자몽 에이드", GameDefs.CATEGORY_ADE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_POUR_SPARKLING_WATER, GameDefs.ACTION_DELIVER_ORDER], ["cup", "grapefruit_base", "ice", "sparkling_water"]),
		_menu("blue_lemon_ade", "블루 레몬 에이드", GameDefs.CATEGORY_ADE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_MEASURE_SYRUP, GameDefs.ACTION_ADD_ICE, GameDefs.ACTION_POUR_SPARKLING_WATER, GameDefs.ACTION_DELIVER_ORDER], ["cup", "blue_lemon_base", "ice", "sparkling_water"]),
		_menu("strawberry_smoothie", "딸기 스무디", GameDefs.CATEGORY_SMOOTHIE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_USE_SMOOTHIE_MACHINE, GameDefs.ACTION_PIPE_WHIPPED_CREAM, GameDefs.ACTION_DELIVER_ORDER], ["cup", "strawberry_smoothie", "whip"]),
		_menu("mango_smoothie", "망고 스무디", GameDefs.CATEGORY_SMOOTHIE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_USE_SMOOTHIE_MACHINE, GameDefs.ACTION_PIPE_WHIPPED_CREAM, GameDefs.ACTION_DELIVER_ORDER], ["cup", "mango_smoothie", "whip"]),
		_menu("yogurt_smoothie", "요거트 스무디", GameDefs.CATEGORY_SMOOTHIE, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_USE_SMOOTHIE_MACHINE, GameDefs.ACTION_ADD_TOPPING, GameDefs.ACTION_DELIVER_ORDER], ["cup", "yogurt_smoothie", "topping"]),
		_menu("plain_soda", "사이다", GameDefs.CATEGORY_DISPLAY, [GameDefs.ACTION_DELIVER_ORDER], ["bottle"]),
		_menu("orange_juice_bottle", "오렌지 주스 병음료", GameDefs.CATEGORY_DISPLAY, [GameDefs.ACTION_DELIVER_ORDER], ["bottle"]),
		_menu("milk_bottle", "우유 병음료", GameDefs.CATEGORY_DISPLAY, [GameDefs.ACTION_DELIVER_ORDER], ["bottle"]),
		_menu("cookie_pack", "쿠키 포장", GameDefs.CATEGORY_DESSERT, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_DELIVER_ORDER], ["cookie", "bag"]),
		_menu("madeleine_pack", "마들렌 포장", GameDefs.CATEGORY_DESSERT, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_DELIVER_ORDER], ["madeleine", "bag"]),
		_menu("warm_bagel", "따뜻한 베이글", GameDefs.CATEGORY_DESSERT, [GameDefs.ACTION_USE_MICROWAVE, GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_DELIVER_ORDER], ["bagel", "warm_effect", "bag"]),
		_menu("cheese_cake_slice", "치즈 케이크 조각", GameDefs.CATEGORY_DESSERT, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_DELIVER_ORDER], ["cake_slice", "box"]),
		_menu("cream_croissant", "크림 크루아상", GameDefs.CATEGORY_DESSERT, [GameDefs.ACTION_PREPARE_PACKAGING, GameDefs.ACTION_PIPE_WHIPPED_CREAM, GameDefs.ACTION_DELIVER_ORDER], ["croissant", "cream", "box"])
	]

func _menu(id: String, name: String, category: String, actions: Array, layers: Array) -> Dictionary:
	return {
		"id": id,
		"name": name,
		"category": category,
		"required_actions": actions,
		"visual_layers": layers,
		"base_price": 4500 + actions.size() * 250
	}

func get_all() -> Array[Dictionary]:
	return _menus.duplicate(true)

func get_by_id(id: String) -> Dictionary:
	for item in _menus:
		if item["id"] == id:
			return item.duplicate(true)
	return {}
```

- [ ] **Step 5: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Commit**

```bash
git add src/core/game_defs.gd src/core/menu_catalog.gd tests/test_menu_catalog.gd
git commit -m "feat: add cafe menu catalog"
```

---

### Task 3: Player Level and Action Unlock Rules

**Files:**
- Create: `src/core/player_progress.gd`
- Create: `tests/test_player_progress.gd`

- [ ] **Step 1: Write the failing progression tests**

Create `tests/test_player_progress.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_level_one_allows_basic_actions",
		"test_level_one_requires_boss_for_espresso",
		"test_level_seven_can_make_latte_actions"
	]

func test_level_one_allows_basic_actions() -> String:
	var progress = load("res://src/core/player_progress.gd").new(1)
	for action in ["take_order", "prepare_packaging", "add_ice", "pour_water", "deliver_order", "restock_supplies"]:
		if not progress.can_perform(action):
			return "Level 1 should allow %s" % action
	return ""

func test_level_one_requires_boss_for_espresso() -> String:
	var progress = load("res://src/core/player_progress.gd").new(1)
	var missing := progress.missing_actions(["prepare_packaging", "add_ice", "pour_water", "pull_espresso", "deliver_order"])
	if missing != ["pull_espresso"]:
		return "Level 1 iced americano should only miss pull_espresso, got %s" % [missing]
	return ""

func test_level_seven_can_make_latte_actions() -> String:
	var progress = load("res://src/core/player_progress.gd").new(7)
	for action in ["pull_espresso", "pour_milk", "steam_milk"]:
		if not progress.can_perform(action):
			return "Level 7 should allow %s" % action
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `player_progress.gd` does not exist.

- [ ] **Step 3: Implement player progression**

Create `src/core/player_progress.gd`:

```gdscript
extends RefCounted
class_name PlayerProgress

const GameDefs = preload("res://src/core/game_defs.gd")

var level: int = 1

func _init(starting_level: int = 1) -> void:
	level = max(1, starting_level)

func unlocked_actions() -> Array[String]:
	var actions: Array[String] = [
		GameDefs.ACTION_TAKE_ORDER,
		GameDefs.ACTION_PREPARE_PACKAGING,
		GameDefs.ACTION_ADD_ICE,
		GameDefs.ACTION_POUR_WATER,
		GameDefs.ACTION_POUR_SPARKLING_WATER,
		GameDefs.ACTION_ADD_PREMADE_BASE,
		GameDefs.ACTION_DELIVER_ORDER,
		GameDefs.ACTION_RESTOCK_SUPPLIES
	]
	if level >= 2:
		actions.append(GameDefs.ACTION_MEASURE_SYRUP)
	if level >= 3:
		actions.append(GameDefs.ACTION_POUR_MILK)
	if level >= 4:
		actions.append(GameDefs.ACTION_MEASURE_POWDER)
		actions.append(GameDefs.ACTION_DISSOLVE_POWDER)
	if level >= 5:
		actions.append(GameDefs.ACTION_USE_MICROWAVE)
	if level >= 6:
		actions.append(GameDefs.ACTION_PIPE_WHIPPED_CREAM)
		actions.append(GameDefs.ACTION_ADD_TOPPING)
	if level >= 7:
		actions.append(GameDefs.ACTION_PULL_ESPRESSO)
		actions.append(GameDefs.ACTION_STEAM_MILK)
	if level >= 8:
		actions.append(GameDefs.ACTION_USE_SMOOTHIE_MACHINE)
	if level >= 9:
		actions.append(GameDefs.ACTION_FIX_BASIC_EQUIPMENT)
	return actions

func can_perform(action: String) -> bool:
	return action in unlocked_actions()

func missing_actions(required_actions: Array) -> Array[String]:
	var missing: Array[String] = []
	for action in required_actions:
		if not can_perform(action):
			missing.append(action)
	return missing
```

- [ ] **Step 4: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/core/player_progress.gd tests/test_player_progress.gd
git commit -m "feat: add action-based player progression"
```

---

### Task 4: Boss Task Queue

**Files:**
- Create: `src/core/boss_queue.gd`
- Create: `tests/test_boss_queue.gd`

- [ ] **Step 1: Write the failing boss queue tests**

Create `tests/test_boss_queue.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_boss_processes_one_task_at_a_time",
		"test_assist_reduces_remaining_time",
		"test_completed_tasks_are_collected"
	]

func test_boss_processes_one_task_at_a_time() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.enqueue("order_2", "steam_milk")
	queue.tick(0.1)
	if queue.current_task()["order_id"] != "order_1":
		return "Boss should start first queued task"
	if queue.pending_count() != 1:
		return "One task should remain pending"
	return ""

func test_assist_reduces_remaining_time() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.tick(0.1)
	var before := queue.current_task()["remaining"]
	queue.assist_current_task(0.5)
	var after := queue.current_task()["remaining"]
	if not after < before:
		return "Assist should reduce remaining time"
	return ""

func test_completed_tasks_are_collected() -> String:
	var queue = load("res://src/core/boss_queue.gd").new()
	queue.enqueue("order_1", "pull_espresso")
	queue.tick(99.0)
	var completed := queue.collect_completed()
	if completed.size() != 1:
		return "One completed boss task expected"
	if completed[0]["action"] != "pull_espresso":
		return "Completed action should be pull_espresso"
	if queue.current_task().size() != 0:
		return "Current task should be empty after completion"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `boss_queue.gd` does not exist.

- [ ] **Step 3: Implement boss queue**

Create `src/core/boss_queue.gd`:

```gdscript
extends RefCounted
class_name BossQueue

const DURATIONS := {
	"pull_espresso": 4.0,
	"steam_milk": 5.0,
	"use_smoothie_machine": 7.0,
	"prepare_advanced_tea_base": 6.0,
	"use_locked_equipment": 6.0
}

var _pending: Array[Dictionary] = []
var _current: Dictionary = {}
var _completed: Array[Dictionary] = []

func enqueue(order_id: String, action: String) -> void:
	_pending.append({
		"order_id": order_id,
		"action": action,
		"duration": _duration_for(action),
		"remaining": _duration_for(action)
	})

func pending_count() -> int:
	return _pending.size()

func current_task() -> Dictionary:
	return _current.duplicate(true)

func tick(delta_seconds: float) -> void:
	if _current.is_empty() and not _pending.is_empty():
		_current = _pending.pop_front()
	if _current.is_empty():
		return
	_current["remaining"] = max(0.0, _current["remaining"] - delta_seconds)
	if _current["remaining"] <= 0.0:
		_completed.append(_current)
		_current = {}

func assist_current_task(strength: float) -> void:
	if _current.is_empty():
		return
	var reduction := clamp(strength, 0.0, 1.0) * _current["duration"] * 0.25
	_current["remaining"] = max(0.0, _current["remaining"] - reduction)

func collect_completed() -> Array[Dictionary]:
	var result := _completed.duplicate(true)
	_completed.clear()
	return result

func _duration_for(action: String) -> float:
	if DURATIONS.has(action):
		return DURATIONS[action]
	return 5.0
```

- [ ] **Step 4: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/core/boss_queue.gd tests/test_boss_queue.gd
git commit -m "feat: add boss task queue"
```

---

### Task 5: Orders, Requests, and Traffic Schedule

**Files:**
- Create: `src/core/order_model.gd`
- Create: `src/core/order_queue.gd`
- Create: `src/core/traffic_schedule.gd`
- Create: `tests/test_order_flow.gd`

- [ ] **Step 1: Write the failing order flow tests**

Create `tests/test_order_flow.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_traffic_schedule_matches_shift_design",
		"test_order_patience_decreases",
		"test_to_go_request_is_recorded"
	]

func test_traffic_schedule_matches_shift_design() -> String:
	var schedule = load("res://src/core/traffic_schedule.gd").new()
	if schedule.phase_at(30.0)["name"] != "normal":
		return "0:30 should be normal"
	if schedule.phase_at(90.0)["name"] != "peak":
		return "1:30 should be peak"
	if schedule.phase_at(240.0)["name"] != "normal":
		return "4:00 should be normal"
	if schedule.phase_at(420.0)["name"] != "peak":
		return "7:00 should be peak"
	if schedule.phase_at(570.0)["name"] != "closing":
		return "9:30 should be closing"
	return ""

func test_order_patience_decreases() -> String:
	var queue = load("res://src/core/order_queue.gd").new()
	queue.add_order("order_1", "iced_americano", ["to_go"], 30.0)
	queue.tick(5.0)
	var order := queue.get_order("order_1")
	if order["patience_remaining"] != 25.0:
		return "Patience should decrease from 30 to 25"
	return ""

func test_to_go_request_is_recorded() -> String:
	var order = load("res://src/core/order_model.gd").new("order_1", "iced_tea", ["to_go"], 40.0)
	if not order.has_request("to_go"):
		return "Order should include to_go request"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because order flow files do not exist.

- [ ] **Step 3: Implement order model**

Create `src/core/order_model.gd`:

```gdscript
extends RefCounted
class_name OrderModel

var id: String
var menu_id: String
var requests: Array[String]
var patience_total: float
var patience_remaining: float
var state: String = "waiting"
var elapsed: float = 0.0

func _init(order_id: String, ordered_menu_id: String, order_requests: Array[String], patience: float) -> void:
	id = order_id
	menu_id = ordered_menu_id
	requests = order_requests.duplicate()
	patience_total = patience
	patience_remaining = patience

func tick(delta_seconds: float) -> void:
	elapsed += delta_seconds
	patience_remaining = max(0.0, patience_remaining - delta_seconds)
	if patience_remaining <= 0.0 and state == "waiting":
		state = "angry"

func has_request(request: String) -> bool:
	return request in requests

func to_dict() -> Dictionary:
	return {
		"id": id,
		"menu_id": menu_id,
		"requests": requests.duplicate(),
		"patience_total": patience_total,
		"patience_remaining": patience_remaining,
		"state": state,
		"elapsed": elapsed
	}
```

- [ ] **Step 4: Implement order queue and traffic schedule**

Create `src/core/order_queue.gd`:

```gdscript
extends RefCounted
class_name OrderQueue

const OrderModel = preload("res://src/core/order_model.gd")

var _orders: Array[OrderModel] = []

func add_order(order_id: String, menu_id: String, requests: Array[String], patience: float) -> void:
	_orders.append(OrderModel.new(order_id, menu_id, requests, patience))

func tick(delta_seconds: float) -> void:
	for order in _orders:
		order.tick(delta_seconds)

func get_order(order_id: String) -> Dictionary:
	for order in _orders:
		if order.id == order_id:
			return order.to_dict()
	return {}

func active_orders() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for order in _orders:
		if order.state != "delivered":
			result.append(order.to_dict())
	return result

func mark_delivered(order_id: String) -> void:
	for order in _orders:
		if order.id == order_id:
			order.state = "delivered"
			return
```

Create `src/core/traffic_schedule.gd`:

```gdscript
extends RefCounted
class_name TrafficSchedule

const PHASES := [
	{"name": "normal", "start": 0.0, "end": 60.0, "spawn_interval": 18.0, "patience": 55.0},
	{"name": "peak", "start": 60.0, "end": 180.0, "spawn_interval": 8.0, "patience": 38.0},
	{"name": "normal", "start": 180.0, "end": 360.0, "spawn_interval": 16.0, "patience": 50.0},
	{"name": "peak", "start": 360.0, "end": 540.0, "spawn_interval": 7.0, "patience": 34.0},
	{"name": "closing", "start": 540.0, "end": 600.0, "spawn_interval": 14.0, "patience": 42.0}
]

func phase_at(elapsed_seconds: float) -> Dictionary:
	for phase in PHASES:
		if elapsed_seconds >= phase["start"] and elapsed_seconds < phase["end"]:
			return phase.duplicate(true)
	return PHASES[PHASES.size() - 1].duplicate(true)
```

- [ ] **Step 5: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Commit**

```bash
git add src/core/order_model.gd src/core/order_queue.gd src/core/traffic_schedule.gd tests/test_order_flow.gd
git commit -m "feat: add order queue and traffic schedule"
```

---

### Task 6: Station Inventory and Equipment State

**Files:**
- Create: `src/core/inventory.gd`
- Create: `src/core/equipment_state.gd`
- Create: `tests/test_inventory_equipment.gd`

- [ ] **Step 1: Write the failing inventory and equipment tests**

Create `tests/test_inventory_equipment.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_inventory_consumes_station_supply",
		"test_inventory_restock_caps_at_capacity",
		"test_equipment_malfunction_slows_work"
	]

func test_inventory_consumes_station_supply() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	if not inventory.consume("sink", "ice", 3):
		return "Sink should have initial ice"
	if inventory.amount("sink", "ice") != 37:
		return "Sink ice should decrease from 40 to 37"
	return ""

func test_inventory_restock_caps_at_capacity() -> String:
	var inventory = load("res://src/core/inventory.gd").new()
	inventory.consume("pickup_counter", "straw", 99)
	inventory.restock("pickup_counter", "straw", 200)
	if inventory.amount("pickup_counter", "straw") != 80:
		return "Pickup counter straw should cap at 80"
	return ""

func test_equipment_malfunction_slows_work() -> String:
	var equipment = load("res://src/core/equipment_state.gd").new("ice_maker", 1.0, 100)
	equipment.set_malfunction(true)
	if equipment.speed_multiplier() != 0.5:
		return "Malfunctioning equipment should run at half speed"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because inventory and equipment files do not exist.

- [ ] **Step 3: Implement inventory**

Create `src/core/inventory.gd`:

```gdscript
extends RefCounted
class_name Inventory

var _stock := {
	"register": {"soda": 12, "coffee_beans": 20},
	"sink": {"ice": 40, "powder": 24, "cup": 30, "lid": 30},
	"main_table": {"milk": 30, "fruit_base": 24, "syrup": 24, "cup": 20},
	"sub_table": {"tea": 20, "dessert": 16, "frozen_base": 18},
	"display_fridge": {"bottle": 18, "cake": 10, "smoothie_base": 16},
	"pickup_counter": {"straw": 80, "sleeve": 60, "handle": 40, "carrier": 20}
}

var _capacity := {
	"register": {"soda": 12, "coffee_beans": 20},
	"sink": {"ice": 40, "powder": 24, "cup": 30, "lid": 30},
	"main_table": {"milk": 30, "fruit_base": 24, "syrup": 24, "cup": 20},
	"sub_table": {"tea": 20, "dessert": 16, "frozen_base": 18},
	"display_fridge": {"bottle": 18, "cake": 10, "smoothie_base": 16},
	"pickup_counter": {"straw": 80, "sleeve": 60, "handle": 40, "carrier": 20}
}

func amount(station: String, supply: String) -> int:
	if not _stock.has(station) or not _stock[station].has(supply):
		return 0
	return _stock[station][supply]

func consume(station: String, supply: String, count: int) -> bool:
	if amount(station, supply) < count:
		return false
	_stock[station][supply] -= count
	return true

func restock(station: String, supply: String, count: int) -> void:
	if not _stock.has(station):
		_stock[station] = {}
		_capacity[station] = {}
	if not _stock[station].has(supply):
		_stock[station][supply] = 0
		_capacity[station][supply] = count
	var max_amount: int = _capacity[station][supply]
	_stock[station][supply] = min(max_amount, _stock[station][supply] + count)

func is_low(station: String, supply: String) -> bool:
	if not _capacity.has(station) or not _capacity[station].has(supply):
		return true
	return amount(station, supply) <= int(ceil(_capacity[station][supply] * 0.25))
```

- [ ] **Step 4: Implement equipment state**

Create `src/core/equipment_state.gd`:

```gdscript
extends RefCounted
class_name EquipmentState

var id: String
var base_speed: float
var capacity: int
var malfunctioning: bool = false
var level: int = 1

func _init(equipment_id: String, starting_speed: float, starting_capacity: int) -> void:
	id = equipment_id
	base_speed = starting_speed
	capacity = starting_capacity

func set_malfunction(value: bool) -> void:
	malfunctioning = value

func speed_multiplier() -> float:
	var upgrade_bonus := 1.0 + float(level - 1) * 0.1
	var malfunction_penalty := 0.5 if malfunctioning else 1.0
	return base_speed * upgrade_bonus * malfunction_penalty

func upgrade() -> void:
	level += 1
	capacity += 10
```

- [ ] **Step 5: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Commit**

```bash
git add src/core/inventory.gd src/core/equipment_state.gd tests/test_inventory_equipment.gd
git commit -m "feat: add station inventory and equipment state"
```

---

### Task 7: Layered Drink Assembly and Quality Scoring

**Files:**
- Create: `src/core/drink_assembly.gd`
- Create: `src/core/quality_scorer.gd`
- Create: `tests/test_drink_quality.gd`

- [ ] **Step 1: Write the failing drink quality tests**

Create `tests/test_drink_quality.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_drink_layers_preserve_order",
		"test_quality_penalizes_missing_request",
		"test_quality_allows_recovery_action"
	]

func test_drink_layers_preserve_order() -> String:
	var drink = load("res://src/core/drink_assembly.gd").new("iced_americano")
	drink.apply_action("add_ice", "ice", 1.0)
	drink.apply_action("pour_water", "water", 1.0)
	if drink.layers() != ["ice", "water"]:
		return "Drink layers should preserve applied order"
	return ""

func test_quality_penalizes_missing_request() -> String:
	var scorer = load("res://src/core/quality_scorer.gd").new()
	var score := scorer.score({
		"required_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"performed_actions": ["prepare_packaging", "add_ice", "deliver_order"],
		"requests": ["to_go"],
		"satisfied_requests": [],
		"wait_ratio": 0.2,
		"visual_neatness": 1.0
	})
	if score["total"] >= 90:
		return "Missing to_go request should reduce score below 90"
	return ""

func test_quality_allows_recovery_action() -> String:
	var drink = load("res://src/core/drink_assembly.gd").new("green_tea_latte")
	drink.apply_action("measure_powder", "powder", 1.0)
	drink.add_recovery("stir_again")
	if not "stir_again" in drink.recoveries():
		return "Recovery action should be recorded"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because drink files do not exist.

- [ ] **Step 3: Implement drink assembly**

Create `src/core/drink_assembly.gd`:

```gdscript
extends RefCounted
class_name DrinkAssembly

var menu_id: String
var _layers: Array[String] = []
var _performed_actions: Array[String] = []
var _amounts: Dictionary = {}
var _recoveries: Array[String] = []

func _init(starting_menu_id: String) -> void:
	menu_id = starting_menu_id

func apply_action(action: String, layer: String, amount: float) -> void:
	_performed_actions.append(action)
	if layer != "":
		_layers.append(layer)
	_amounts[action] = amount

func add_recovery(recovery_id: String) -> void:
	_recoveries.append(recovery_id)

func layers() -> Array[String]:
	return _layers.duplicate()

func performed_actions() -> Array[String]:
	return _performed_actions.duplicate()

func recoveries() -> Array[String]:
	return _recoveries.duplicate()

func amount_for(action: String) -> float:
	if _amounts.has(action):
		return _amounts[action]
	return 0.0
```

- [ ] **Step 4: Implement quality scorer**

Create `src/core/quality_scorer.gd`:

```gdscript
extends RefCounted
class_name QualityScorer

func score(input: Dictionary) -> Dictionary:
	var required: Array = input.get("required_actions", [])
	var performed: Array = input.get("performed_actions", [])
	var requests: Array = input.get("requests", [])
	var satisfied: Array = input.get("satisfied_requests", [])
	var wait_ratio: float = clamp(input.get("wait_ratio", 0.0), 0.0, 1.0)
	var visual_neatness: float = clamp(input.get("visual_neatness", 1.0), 0.0, 1.0)

	var recipe_score := _recipe_score(required, performed)
	var request_score := _request_score(requests, satisfied)
	var wait_score := 100.0 - wait_ratio * 35.0
	var visual_score := visual_neatness * 100.0
	var total := recipe_score * 0.4 + request_score * 0.25 + wait_score * 0.2 + visual_score * 0.15

	return {
		"total": int(round(clamp(total, 0.0, 100.0))),
		"recipe": int(round(recipe_score)),
		"requests": int(round(request_score)),
		"wait": int(round(wait_score)),
		"visual": int(round(visual_score))
	}

func _recipe_score(required: Array, performed: Array) -> float:
	if required.is_empty():
		return 100.0
	var correct := 0
	for index in range(min(required.size(), performed.size())):
		if required[index] == performed[index]:
			correct += 1
	return float(correct) / float(required.size()) * 100.0

func _request_score(requests: Array, satisfied: Array) -> float:
	if requests.is_empty():
		return 100.0
	var correct := 0
	for request in requests:
		if request in satisfied:
			correct += 1
	return float(correct) / float(requests.size()) * 100.0
```

- [ ] **Step 5: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Commit**

```bash
git add src/core/drink_assembly.gd src/core/quality_scorer.gd tests/test_drink_quality.gd
git commit -m "feat: add layered drink quality model"
```

---

### Task 8: Gesture Analysis for Stirring, Pouring, Whipping, and Topping

**Files:**
- Create: `src/core/gesture_analyzer.gd`
- Create: `tests/test_gesture_analyzer.gd`

- [ ] **Step 1: Write the failing gesture tests**

Create `tests/test_gesture_analyzer.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_stir_detects_circular_motion",
		"test_pour_amount_uses_hold_time",
		"test_whip_path_neatness_rewards_smooth_path"
	]

func test_stir_detects_circular_motion() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var points := [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)]
	var score := analyzer.score_stir(points)
	if score < 0.75:
		return "Circular stir should score at least 0.75"
	return ""

func test_pour_amount_uses_hold_time() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var amount := analyzer.pour_amount(1.5, 2.0)
	if amount < 0.74 or amount > 0.76:
		return "1.5s hold against 2.0s target should be about 0.75"
	return ""

func test_whip_path_neatness_rewards_smooth_path() -> String:
	var analyzer = load("res://src/core/gesture_analyzer.gd").new()
	var path := [Vector2(0, 0), Vector2(20, 3), Vector2(40, 5), Vector2(60, 4)]
	var score := analyzer.score_whip_path(path)
	if score < 0.8:
		return "Smooth whip path should score at least 0.8"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `gesture_analyzer.gd` does not exist.

- [ ] **Step 3: Implement gesture analyzer**

Create `src/core/gesture_analyzer.gd`:

```gdscript
extends RefCounted
class_name GestureAnalyzer

func score_stir(points: Array[Vector2]) -> float:
	if points.size() < 5:
		return 0.0
	var center := Vector2.ZERO
	for point in points:
		center += point
	center /= float(points.size())

	var angle_total := 0.0
	var last_angle := (points[0] - center).angle()
	for index in range(1, points.size()):
		var angle := (points[index] - center).angle()
		angle_total += abs(wrapf(angle - last_angle, -PI, PI))
		last_angle = angle
	return clamp(angle_total / TAU, 0.0, 1.0)

func pour_amount(hold_seconds: float, target_seconds: float) -> float:
	if target_seconds <= 0.0:
		return 0.0
	return clamp(hold_seconds / target_seconds, 0.0, 1.25)

func score_whip_path(points: Array[Vector2]) -> float:
	if points.size() < 3:
		return 0.0
	var direction_changes := 0
	var last_direction := (points[1] - points[0]).normalized()
	for index in range(2, points.size()):
		var direction := (points[index] - points[index - 1]).normalized()
		if last_direction.dot(direction) < 0.65:
			direction_changes += 1
		last_direction = direction
	var penalty := float(direction_changes) / float(points.size() - 2)
	return clamp(1.0 - penalty, 0.0, 1.0)

func score_topping_distribution(points: Array[Vector2], target_rect: Rect2) -> float:
	if points.is_empty():
		return 0.0
	var inside := 0
	for point in points:
		if target_rect.has_point(point):
			inside += 1
	return float(inside) / float(points.size())
```

- [ ] **Step 4: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/core/gesture_analyzer.gd tests/test_gesture_analyzer.gd
git commit -m "feat: add manufacturing gesture analysis"
```

---

### Task 9: Shift Manager and End-of-Day Settlement

**Files:**
- Create: `src/core/shift_manager.gd`
- Create: `tests/test_shift_manager.gd`

- [ ] **Step 1: Write the failing shift manager tests**

Create `tests/test_shift_manager.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_shift_ends_at_ten_minutes",
		"test_rewards_include_money_experience_and_reputation",
		"test_phase_updates_from_schedule"
	]

func test_shift_ends_at_ten_minutes() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.tick(600.0)
	if not shift.is_finished():
		return "Shift should finish after 600 seconds"
	return ""

func test_rewards_include_money_experience_and_reputation() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.record_delivery({"total": 92}, 5500)
	var settlement := shift.settlement()
	if settlement["money"] <= 0:
		return "Settlement should include money"
	if settlement["experience"] <= 0:
		return "Settlement should include experience"
	if settlement["reputation"] <= 0:
		return "Settlement should include reputation"
	return ""

func test_phase_updates_from_schedule() -> String:
	var shift = load("res://src/core/shift_manager.gd").new()
	shift.tick(70.0)
	if shift.current_phase()["name"] != "peak":
		return "70 seconds should be first peak"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `shift_manager.gd` does not exist.

- [ ] **Step 3: Implement shift manager**

Create `src/core/shift_manager.gd`:

```gdscript
extends RefCounted
class_name ShiftManager

const ProjectConfig = preload("res://src/core/project_config.gd")
const TrafficSchedule = preload("res://src/core/traffic_schedule.gd")

var elapsed: float = 0.0
var money: int = 0
var experience: int = 0
var reputation: int = 0
var delivered_count: int = 0
var discarded_count: int = 0
var _schedule := TrafficSchedule.new()

func tick(delta_seconds: float) -> void:
	elapsed = min(ProjectConfig.SHIFT_SECONDS, elapsed + delta_seconds)

func is_finished() -> bool:
	return elapsed >= ProjectConfig.SHIFT_SECONDS

func current_phase() -> Dictionary:
	return _schedule.phase_at(elapsed)

func record_delivery(score: Dictionary, base_price: int) -> void:
	var total_score: int = score.get("total", 0)
	var quality_ratio := float(total_score) / 100.0
	money += int(round(float(base_price) * quality_ratio))
	experience += 5 + int(round(quality_ratio * 10.0))
	reputation += int(round((quality_ratio - 0.5) * 4.0))
	delivered_count += 1

func record_discard() -> void:
	discarded_count += 1
	reputation -= 1

func settlement() -> Dictionary:
	return {
		"money": money,
		"experience": experience,
		"reputation": reputation,
		"delivered_count": delivered_count,
		"discarded_count": discarded_count,
		"elapsed": elapsed
	}
```

- [ ] **Step 4: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/core/shift_manager.gd tests/test_shift_manager.gd
git commit -m "feat: add shift settlement system"
```

---

### Task 10: Integrated Game State Facade

**Files:**
- Create: `src/core/game_state.gd`
- Create: `tests/test_game_state.gd`

- [ ] **Step 1: Write the failing game state tests**

Create `tests/test_game_state.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_game_state_spawns_order",
		"test_level_one_routes_missing_action_to_boss",
		"test_delivered_order_records_settlement"
	]

func test_game_state_spawns_order() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.spawn_order("iced_americano", ["to_go"])
	if game.active_orders().size() != 1:
		return "Game state should spawn one order"
	return ""

func test_level_one_routes_missing_action_to_boss() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.spawn_order("iced_americano", [])
	var route := game.route_unavailable_actions("order_1")
	if route != ["pull_espresso"]:
		return "Level 1 should route pull_espresso to boss, got %s" % [route]
	return ""

func test_delivered_order_records_settlement() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.spawn_order("iced_tea", [])
	game.perform_action("order_1", "prepare_packaging", "cup", 1.0)
	game.perform_action("order_1", "add_ice", "ice", 1.0)
	game.perform_action("order_1", "add_premade_base", "iced_tea_base", 1.0)
	game.perform_action("order_1", "deliver_order", "lid", 1.0)
	var result := game.deliver("order_1", [])
	if result["score"]["total"] <= 0:
		return "Delivered order should return a positive score"
	if game.settlement()["delivered_count"] != 1:
		return "Settlement should record one delivered order"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because `game_state.gd` does not exist.

- [ ] **Step 3: Implement game state**

Create `src/core/game_state.gd`:

```gdscript
extends RefCounted
class_name GameState

const MenuCatalog = preload("res://src/core/menu_catalog.gd")
const PlayerProgress = preload("res://src/core/player_progress.gd")
const BossQueue = preload("res://src/core/boss_queue.gd")
const OrderQueue = preload("res://src/core/order_queue.gd")
const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const QualityScorer = preload("res://src/core/quality_scorer.gd")
const ShiftManager = preload("res://src/core/shift_manager.gd")

var catalog := MenuCatalog.new()
var progress := PlayerProgress.new(1)
var boss_queue := BossQueue.new()
var order_queue := OrderQueue.new()
var shift := ShiftManager.new()
var assemblies: Dictionary = {}
var _next_order_number := 1

func spawn_order(menu_id: String, requests: Array[String]) -> String:
	var order_id := "order_%d" % _next_order_number
	_next_order_number += 1
	var phase := shift.current_phase()
	order_queue.add_order(order_id, menu_id, requests, phase["patience"])
	assemblies[order_id] = DrinkAssembly.new(menu_id)
	return order_id

func active_orders() -> Array[Dictionary]:
	return order_queue.active_orders()

func route_unavailable_actions(order_id: String) -> Array[String]:
	var order := order_queue.get_order(order_id)
	if order.is_empty():
		return []
	var menu := catalog.get_by_id(order["menu_id"])
	var missing := progress.missing_actions(menu["required_actions"])
	for action in missing:
		boss_queue.enqueue(order_id, action)
	return missing

func perform_action(order_id: String, action: String, layer: String, amount: float) -> bool:
	if not assemblies.has(order_id):
		return false
	if not progress.can_perform(action):
		return false
	assemblies[order_id].apply_action(action, layer, amount)
	return true

func deliver(order_id: String, satisfied_requests: Array[String]) -> Dictionary:
	var order := order_queue.get_order(order_id)
	if order.is_empty() or not assemblies.has(order_id):
		return {}
	var menu := catalog.get_by_id(order["menu_id"])
	var assembly: DrinkAssembly = assemblies[order_id]
	var wait_ratio: float = 1.0 - (order["patience_remaining"] / order["patience_total"])
	var score := QualityScorer.new().score({
		"required_actions": menu["required_actions"],
		"performed_actions": assembly.performed_actions(),
		"requests": order["requests"],
		"satisfied_requests": satisfied_requests,
		"wait_ratio": wait_ratio,
		"visual_neatness": 1.0
	})
	shift.record_delivery(score, menu["base_price"])
	order_queue.mark_delivered(order_id)
	return {"order_id": order_id, "score": score}

func tick(delta_seconds: float) -> void:
	shift.tick(delta_seconds)
	order_queue.tick(delta_seconds)
	boss_queue.tick(delta_seconds)

func settlement() -> Dictionary:
	return shift.settlement()
```

- [ ] **Step 4: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 5: Commit**

```bash
git add src/core/game_state.gd tests/test_game_state.gd
git commit -m "feat: integrate first playable game state"
```

---

### Task 11: Main Scene and Six Station Navigation

**Files:**
- Create: `scenes/main/Main.tscn`
- Create: `scenes/main/main_controller.gd`
- Create: `scenes/stations/station_view.gd`
- Create: `tests/test_station_navigation.gd`

- [ ] **Step 1: Write the failing station navigation test**

Create `tests/test_station_navigation.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_station_view_cycles_right_and_left",
		"test_main_scene_can_be_loaded"
	]

func test_station_view_cycles_right_and_left() -> String:
	var view = load("res://scenes/stations/station_view.gd").new()
	view.go_right()
	if view.current_station_id() != "sink":
		return "Right from register should move to sink"
	view.go_left()
	if view.current_station_id() != "register":
		return "Left from sink should move to register"
	return ""

func test_main_scene_can_be_loaded() -> String:
	var scene := load("res://scenes/main/Main.tscn")
	if scene == null:
		return "Main scene should load"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because scene files do not exist.

- [ ] **Step 3: Implement station view**

Create `scenes/stations/station_view.gd`:

```gdscript
extends Control
class_name StationView

const ProjectConfig = preload("res://src/core/project_config.gd")

var station_index: int = 0

func current_station_id() -> String:
	return ProjectConfig.STATIONS[station_index]

func go_left() -> void:
	station_index = max(0, station_index - 1)

func go_right() -> void:
	station_index = min(ProjectConfig.STATIONS.size() - 1, station_index + 1)

func station_title() -> String:
	var names := {
		"register": "계산대 안쪽",
		"sink": "싱크대",
		"main_table": "메인 책상",
		"sub_table": "서브 책상",
		"display_fridge": "큰 냉장고",
		"pickup_counter": "카운터"
	}
	return names[current_station_id()]
```

- [ ] **Step 4: Implement main scene controller**

Create `scenes/main/main_controller.gd`:

```gdscript
extends Control

const GameState = preload("res://src/core/game_state.gd")
const StationView = preload("res://scenes/stations/station_view.gd")

var game := GameState.new()
var station_view := StationView.new()

@onready var station_label: Label = %StationLabel
@onready var order_list: ItemList = %OrderList
@onready var phase_label: Label = %PhaseLabel

func _ready() -> void:
	add_child(station_view)
	station_view.visible = false
	game.spawn_order("iced_americano", ["to_go"])
	_refresh()

func _process(delta: float) -> void:
	game.tick(delta)
	_refresh()

func _on_left_pressed() -> void:
	station_view.go_left()
	_refresh()

func _on_right_pressed() -> void:
	station_view.go_right()
	_refresh()

func _on_spawn_order_pressed() -> void:
	game.spawn_order("iced_tea", [])
	_refresh()

func _refresh() -> void:
	station_label.text = station_view.station_title()
	phase_label.text = "Phase: %s" % game.shift.current_phase()["name"]
	order_list.clear()
	for order in game.active_orders():
		order_list.add_item("%s / %.0fs" % [order["menu_id"], order["patience_remaining"]])
```

- [ ] **Step 5: Create main scene**

Create `scenes/main/Main.tscn`:

```text
[gd_scene load_steps=2 format=3 uid="uid://lunch_time_main"]

[ext_resource type="Script" path="res://scenes/main/main_controller.gd" id="1_main_controller"]

[node name="Main" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_main_controller")

[node name="Background" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
color = Color(0.93, 0.88, 0.78, 1)

[node name="StationLabel" type="Label" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 40.0
offset_top = 30.0
offset_right = 400.0
offset_bottom = 80.0
text = "계산대 안쪽"

[node name="PhaseLabel" type="Label" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 40.0
offset_top = 82.0
offset_right = 400.0
offset_bottom = 120.0
text = "Phase: normal"

[node name="LeftButton" type="Button" parent="."]
layout_mode = 0
offset_left = 40.0
offset_top = 620.0
offset_right = 140.0
offset_bottom = 680.0
text = "<"

[node name="RightButton" type="Button" parent="."]
layout_mode = 0
offset_left = 160.0
offset_top = 620.0
offset_right = 260.0
offset_bottom = 680.0
text = ">"

[node name="SpawnOrderButton" type="Button" parent="."]
layout_mode = 0
offset_left = 280.0
offset_top = 620.0
offset_right = 470.0
offset_bottom = 680.0
text = "주문 추가"

[node name="OrderList" type="ItemList" parent="."]
unique_name_in_owner = true
layout_mode = 0
offset_left = 900.0
offset_top = 40.0
offset_right = 1240.0
offset_bottom = 680.0

[connection signal="pressed" from="LeftButton" to="." method="_on_left_pressed"]
[connection signal="pressed" from="RightButton" to="." method="_on_right_pressed"]
[connection signal="pressed" from="SpawnOrderButton" to="." method="_on_spawn_order_pressed"]
```

- [ ] **Step 6: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 7: Commit**

```bash
git add scenes/main/Main.tscn scenes/main/main_controller.gd scenes/stations/station_view.gd tests/test_station_navigation.gd
git commit -m "feat: add six-station main scene"
```

---

### Task 12: Manufacturing Screen Interaction Hooks

**Files:**
- Create: `scenes/manufacturing/ManufacturingScreen.tscn`
- Create: `scenes/manufacturing/manufacturing_screen.gd`
- Create: `tests/test_manufacturing_screen.gd`

- [ ] **Step 1: Write the failing manufacturing screen tests**

Create `tests/test_manufacturing_screen.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_screen_records_dragged_layer",
		"test_screen_records_stir_score",
		"test_scene_can_be_loaded"
	]

func test_screen_records_dragged_layer() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "iced_americano")
	screen.apply_drag("add_ice", "ice", 1.0)
	if screen.current_layers() != ["ice"]:
		return "Dragged ice should add ice layer"
	return ""

func test_screen_records_stir_score() -> String:
	var screen = load("res://scenes/manufacturing/manufacturing_screen.gd").new()
	screen.start_order("order_1", "green_tea_latte")
	screen.apply_stir([Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1), Vector2(1, 0)])
	if screen.last_gesture_score() < 0.75:
		return "Circular stir should be recorded as a strong gesture"
	return ""

func test_scene_can_be_loaded() -> String:
	var scene := load("res://scenes/manufacturing/ManufacturingScreen.tscn")
	if scene == null:
		return "Manufacturing screen scene should load"
	return ""
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: FAIL because manufacturing scene files do not exist.

- [ ] **Step 3: Implement manufacturing controller**

Create `scenes/manufacturing/manufacturing_screen.gd`:

```gdscript
extends Control
class_name ManufacturingScreen

const DrinkAssembly = preload("res://src/core/drink_assembly.gd")
const GestureAnalyzer = preload("res://src/core/gesture_analyzer.gd")

var order_id: String = ""
var assembly: DrinkAssembly
var analyzer := GestureAnalyzer.new()
var _last_gesture_score: float = 0.0

func start_order(new_order_id: String, menu_id: String) -> void:
	order_id = new_order_id
	assembly = DrinkAssembly.new(menu_id)

func apply_drag(action: String, layer: String, amount: float) -> void:
	if assembly == null:
		return
	assembly.apply_action(action, layer, amount)

func apply_stir(points: Array[Vector2]) -> void:
	_last_gesture_score = analyzer.score_stir(points)
	if assembly != null:
		assembly.apply_action("dissolve_powder", "mixed_base", _last_gesture_score)

func apply_pour(action: String, layer: String, hold_seconds: float, target_seconds: float) -> void:
	var amount := analyzer.pour_amount(hold_seconds, target_seconds)
	if assembly != null:
		assembly.apply_action(action, layer, amount)

func apply_whip(points: Array[Vector2]) -> void:
	_last_gesture_score = analyzer.score_whip_path(points)
	if assembly != null:
		assembly.apply_action("pipe_whipped_cream", "whip", _last_gesture_score)

func current_layers() -> Array[String]:
	if assembly == null:
		return []
	return assembly.layers()

func last_gesture_score() -> float:
	return _last_gesture_score
```

- [ ] **Step 4: Create manufacturing scene**

Create `scenes/manufacturing/ManufacturingScreen.tscn`:

```text
[gd_scene load_steps=2 format=3 uid="uid://manufacturing_screen"]

[ext_resource type="Script" path="res://scenes/manufacturing/manufacturing_screen.gd" id="1_manufacturing"]

[node name="ManufacturingScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("1_manufacturing")

[node name="WorkArea" type="ColorRect" parent="."]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -260.0
offset_top = -260.0
offset_right = 260.0
offset_bottom = 260.0
grow_horizontal = 2
grow_vertical = 2
color = Color(0.98, 0.95, 0.9, 1)

[node name="CupPreview" type="ColorRect" parent="WorkArea"]
layout_mode = 0
offset_left = 190.0
offset_top = 100.0
offset_right = 330.0
offset_bottom = 420.0
color = Color(0.86, 0.92, 1, 0.85)

[node name="InstructionLabel" type="Label" parent="."]
layout_mode = 0
offset_left = 40.0
offset_top = 36.0
offset_right = 900.0
offset_bottom = 80.0
text = "드래그와 제스처로 음료를 조립합니다."
```

- [ ] **Step 5: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Commit**

```bash
git add scenes/manufacturing/ManufacturingScreen.tscn scenes/manufacturing/manufacturing_screen.gd tests/test_manufacturing_screen.gd
git commit -m "feat: add manufacturing interaction screen"
```

---

### Task 13: First Playable Integration Smoke Test

**Files:**
- Create: `tests/test_first_playable_flow.gd`
- Modify: `scenes/main/main_controller.gd`

- [ ] **Step 1: Write the failing first playable flow test**

Create `tests/test_first_playable_flow.gd`:

```gdscript
extends RefCounted

func get_test_methods() -> Array[String]:
	return [
		"test_level_one_americano_boss_help_flow",
		"test_shift_can_tick_through_peak_and_settle"
	]

func test_level_one_americano_boss_help_flow() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.spawn_order("iced_americano", ["to_go"])
	var boss_actions := game.route_unavailable_actions("order_1")
	if boss_actions != ["pull_espresso"]:
		return "Level 1 iced americano should request espresso from boss"
	if not game.perform_action("order_1", "prepare_packaging", "cup", 1.0):
		return "Player should prepare packaging"
	if not game.perform_action("order_1", "add_ice", "ice", 1.0):
		return "Player should add ice"
	if not game.perform_action("order_1", "pour_water", "water", 1.0):
		return "Player should pour water"
	game.boss_queue.tick(99.0)
	var completed := game.boss_queue.collect_completed()
	if completed.size() != 1:
		return "Boss should complete espresso task"
	game.assemblies["order_1"].apply_action("pull_espresso", "espresso", 1.0)
	game.perform_action("order_1", "deliver_order", "lid", 1.0)
	var result := game.deliver("order_1", ["to_go"])
	if result["score"]["total"] < 80:
		return "Assisted americano should score at least 80"
	return ""

func test_shift_can_tick_through_peak_and_settle() -> String:
	var game = load("res://src/core/game_state.gd").new()
	game.tick(420.0)
	if game.shift.current_phase()["name"] != "peak":
		return "420 seconds should be second peak"
	game.tick(180.0)
	if not game.shift.is_finished():
		return "Shift should finish at 600 seconds"
	var settlement := game.settlement()
	if not settlement.has("money") or not settlement.has("experience") or not settlement.has("reputation"):
		return "Settlement should include money, experience, and reputation"
	return ""
```

- [ ] **Step 2: Run the test to verify any integration issue**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected before fixes: FAIL if action order, boss completion, or score integration is inconsistent.

- [ ] **Step 3: Update main controller with playable action buttons**

Modify `scenes/main/main_controller.gd` so the whole file is:

```gdscript
extends Control

const GameState = preload("res://src/core/game_state.gd")
const StationView = preload("res://scenes/stations/station_view.gd")

var game := GameState.new()
var station_view := StationView.new()
var selected_order_id: String = "order_1"

@onready var station_label: Label = %StationLabel
@onready var order_list: ItemList = %OrderList
@onready var phase_label: Label = %PhaseLabel

func _ready() -> void:
	add_child(station_view)
	station_view.visible = false
	game.spawn_order("iced_americano", ["to_go"])
	_refresh()

func _process(delta: float) -> void:
	game.tick(delta)
	_refresh()

func _on_left_pressed() -> void:
	station_view.go_left()
	_refresh()

func _on_right_pressed() -> void:
	station_view.go_right()
	_refresh()

func _on_spawn_order_pressed() -> void:
	selected_order_id = game.spawn_order("iced_tea", [])
	_refresh()

func _on_basic_step_pressed() -> void:
	game.perform_action(selected_order_id, "prepare_packaging", "cup", 1.0)
	game.perform_action(selected_order_id, "add_ice", "ice", 1.0)
	game.perform_action(selected_order_id, "pour_water", "water", 1.0)
	_refresh()

func _on_boss_help_pressed() -> void:
	game.route_unavailable_actions(selected_order_id)
	_refresh()

func _on_deliver_pressed() -> void:
	game.perform_action(selected_order_id, "deliver_order", "lid", 1.0)
	game.deliver(selected_order_id, ["to_go"])
	_refresh()

func _refresh() -> void:
	station_label.text = station_view.station_title()
	phase_label.text = "Phase: %s / Money: %d" % [game.shift.current_phase()["name"], game.settlement()["money"]]
	order_list.clear()
	for order in game.active_orders():
		order_list.add_item("%s / %.0fs / %s" % [order["menu_id"], order["patience_remaining"], order["state"]])
```

- [ ] **Step 4: Add action buttons to the main scene**

Modify `scenes/main/Main.tscn` by adding these nodes before the `[node name="OrderList"` block:

```text
[node name="BasicStepButton" type="Button" parent="."]
layout_mode = 0
offset_left = 500.0
offset_top = 620.0
offset_right = 680.0
offset_bottom = 680.0
text = "기본 제조"

[node name="BossHelpButton" type="Button" parent="."]
layout_mode = 0
offset_left = 700.0
offset_top = 620.0
offset_right = 880.0
offset_bottom = 680.0
text = "사장님 요청"

[node name="DeliverButton" type="Button" parent="."]
layout_mode = 0
offset_left = 900.0
offset_top = 620.0
offset_right = 1080.0
offset_bottom = 680.0
text = "전달"
```

Add these connections after the existing connection lines:

```text
[connection signal="pressed" from="BasicStepButton" to="." method="_on_basic_step_pressed"]
[connection signal="pressed" from="BossHelpButton" to="." method="_on_boss_help_pressed"]
[connection signal="pressed" from="DeliverButton" to="." method="_on_deliver_pressed"]
```

- [ ] **Step 5: Run the tests**

Run:

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

Expected: `ALL TESTS PASSED`

- [ ] **Step 6: Run the playable scene**

Run:

```bash
godot --path .
```

Expected: A 1280x720 game window opens. The player can change stations with `<` and `>`, spawn an order, perform basic steps, request boss help, and deliver an order. The order list and money value update.

- [ ] **Step 7: Commit**

```bash
git add scenes/main/main_controller.gd scenes/main/Main.tscn tests/test_first_playable_flow.gd
git commit -m "feat: connect first playable cafe loop"
```

---

## Self-Review

### Spec Coverage

- Godot 2D project foundation: Task 1.
- PC-first, touch-compatible drag/gesture direction: Tasks 8 and 12.
- Six station scene transitions: Task 11.
- Customer order queue and patience: Task 5.
- At least 30 menu data entries: Task 2.
- Action-based player level restrictions: Task 3.
- Boss task queue: Task 4.
- Layered drink assembly: Task 7.
- Drag-and-drop and core gestures: Tasks 8 and 12.
- Drink and simple dessert orders: Task 2.
- Supply restocking: Task 6.
- To-go packaging request: Tasks 5, 7, 10, and 13.
- Quality scoring and partial recovery: Task 7.
- 10-minute day with two realistic peak windows: Tasks 5 and 9.
- End-of-day settlement: Task 9.
- Money, experience, reputation, and equipment upgrade hooks: Tasks 6 and 9.

### Empty-Step Scan

Each code-changing task includes concrete file contents or exact modification blocks, a test command, expected output, and a commit command. The plan avoids empty future-work markers and avoids steps that ask the implementer to invent missing details.

### Type Consistency

The same IDs are used across tasks:

- Station IDs: `register`, `sink`, `main_table`, `sub_table`, `display_fridge`, `pickup_counter`.
- Core action IDs: `prepare_packaging`, `add_ice`, `pour_water`, `pull_espresso`, `deliver_order`.
- Order IDs generated by `GameState`: `order_1`, `order_2`, increasing by one.
- Menu lookup uses `MenuCatalog.get_by_id(id)` and returns dictionaries with `id`, `name`, `category`, `required_actions`, `visual_layers`, and `base_price`.
