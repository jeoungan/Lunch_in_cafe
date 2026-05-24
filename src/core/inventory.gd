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
	return int(_stock[station][supply])

func consume(station: String, supply: String, count: int) -> bool:
	if count <= 0:
		return false
	if amount(station, supply) < count:
		return false
	_stock[station][supply] = int(_stock[station][supply]) - count
	return true

func restock(station: String, supply: String, count: int, capacity_count: int = -1) -> void:
	if count <= 0:
		return
	if not _stock.has(station):
		_stock[station] = {}
		_capacity[station] = {}
	if not _stock[station].has(supply):
		_stock[station][supply] = 0
		_capacity[station][supply] = capacity_count if capacity_count > 0 else count
	var max_amount: int = int(_capacity[station][supply])
	_stock[station][supply] = min(max_amount, int(_stock[station][supply]) + count)

func is_low(station: String, supply: String) -> bool:
	if not _capacity.has(station) or not _capacity[station].has(supply):
		return true
	return amount(station, supply) <= int(ceil(float(_capacity[station][supply]) * 0.25))
