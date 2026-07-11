extends Control
class_name CafeStationView

const STATION_IDS: Array[String] = [
	"register",
	"sink",
	"main_table",
	"sub_table",
	"display_fridge",
	"pickup_counter",
]

var station_id: String = "register"
var customer_visible: bool = true
var boss_visible: bool = true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	queue_redraw()


func set_station(new_station_id: String) -> void:
	if not new_station_id in STATION_IDS:
		return
	station_id = new_station_id
	queue_redraw()


func slide_to(new_station_id: String, direction: int) -> void:
	if new_station_id == station_id or not new_station_id in STATION_IDS:
		return
	var distance := maxf(48.0, size.x * 0.06)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:x", -float(direction) * distance, 0.14)
	tween.parallel().tween_property(self, "modulate:a", 0.25, 0.14)
	tween.tween_callback(func() -> void:
		station_id = new_station_id
		position.x = float(direction) * distance
		queue_redraw()
	)
	tween.tween_property(self, "position:x", 0.0, 0.16)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.16)


func _draw() -> void:
	var view := Rect2(Vector2.ZERO, size)
	_draw_room_shell(view)
	match station_id:
		"register":
			_draw_register(view)
		"sink":
			_draw_sink(view)
		"main_table":
			_draw_main_table(view)
		"sub_table":
			_draw_sub_table(view)
		"display_fridge":
			_draw_display_fridge(view)
		"pickup_counter":
			_draw_pickup_counter(view)


func _draw_room_shell(view: Rect2) -> void:
	var wall := Color("#d9d2c4")
	var floor := Color("#7b695d")
	var ceiling := Color("#f2eee6")
	draw_rect(view, wall)
	draw_rect(Rect2(0.0, 0.0, view.size.x, view.size.y * 0.13), ceiling)
	draw_rect(Rect2(0.0, view.size.y * 0.72, view.size.x, view.size.y * 0.28), floor)
	for index in range(9):
		var x := view.size.x * float(index) / 8.0
		draw_line(Vector2(x, view.size.y * 0.72), Vector2(x - view.size.x * 0.08, view.size.y), Color("#69584f"), 1.0)
	draw_line(Vector2(0.0, view.size.y * 0.72), Vector2(view.size.x, view.size.y * 0.72), Color("#54453f"), 4.0)
	_draw_pendant(Vector2(view.size.x * 0.25, view.size.y * 0.08))
	_draw_pendant(Vector2(view.size.x * 0.72, view.size.y * 0.08))


func _draw_register(view: Rect2) -> void:
	var door := Rect2(view.size.x * 0.07, view.size.y * 0.2, view.size.x * 0.19, view.size.y * 0.51)
	draw_rect(door, Color("#35545a"))
	draw_rect(door.grow(-8.0), Color("#7eb1b3"))
	draw_rect(Rect2(door.position + Vector2(12.0, 12.0), Vector2(door.size.x - 24.0, door.size.y * 0.48)), Color("#b9dde0"))
	draw_circle(Vector2(door.end.x - 18.0, door.position.y + door.size.y * 0.58), 5.0, Color("#e7b552"))
	_draw_window(Rect2(view.size.x * 0.31, view.size.y * 0.2, view.size.x * 0.26, view.size.y * 0.3))
	_draw_plant(Vector2(view.size.x * 0.59, view.size.y * 0.7), view.size.y * 0.19)
	_draw_counter(Rect2(view.size.x * 0.25, view.size.y * 0.58, view.size.x * 0.67, view.size.y * 0.22), Color("#664536"))
	_draw_register_machine(Rect2(view.size.x * 0.61, view.size.y * 0.48, view.size.x * 0.13, view.size.y * 0.12))
	_draw_receipt_printer(Rect2(view.size.x * 0.45, view.size.y * 0.52, view.size.x * 0.1, view.size.y * 0.08))
	if customer_visible:
		_draw_character(Vector2(view.size.x * 0.18, view.size.y * 0.57), Color("#d7635e"), Color("#f0d5c3"), false)


func _draw_sink(view: Rect2) -> void:
	_draw_tile_wall(Rect2(view.size.x * 0.05, view.size.y * 0.18, view.size.x * 0.9, view.size.y * 0.48))
	_draw_counter(Rect2(view.size.x * 0.06, view.size.y * 0.56, view.size.x * 0.56, view.size.y * 0.22), Color("#4f6768"))
	var basin := Rect2(view.size.x * 0.18, view.size.y * 0.54, view.size.x * 0.28, view.size.y * 0.11)
	draw_style_box(_box(Color("#b8c7c8"), Color("#60787a"), 3.0, 8.0), basin)
	draw_arc(Vector2(basin.end.x - 24.0, basin.position.y - 8.0), 28.0, PI, TAU, 24, Color("#63787a"), 7.0)
	draw_line(Vector2(basin.end.x + 4.0, basin.position.y - 9.0), Vector2(basin.end.x + 4.0, basin.position.y + 22.0), Color("#63787a"), 7.0)
	_draw_ice_machine(Rect2(view.size.x * 0.68, view.size.y * 0.28, view.size.x * 0.23, view.size.y * 0.5))
	_draw_shelf(Rect2(view.size.x * 0.1, view.size.y * 0.23, view.size.x * 0.46, view.size.y * 0.13), [
		Color("#b78d5e"), Color("#8c6cb0"), Color("#d6a44d"), Color("#7d9f6d")
	])


func _draw_main_table(view: Rect2) -> void:
	_draw_brick_wall(Rect2(view.size.x * 0.05, view.size.y * 0.18, view.size.x * 0.9, view.size.y * 0.46))
	_draw_counter(Rect2(view.size.x * 0.06, view.size.y * 0.59, view.size.x * 0.88, view.size.y * 0.2), Color("#5b3b31"))
	_draw_espresso_machine(Rect2(view.size.x * 0.31, view.size.y * 0.28, view.size.x * 0.36, view.size.y * 0.33))
	_draw_shelf(Rect2(view.size.x * 0.08, view.size.y * 0.27, view.size.x * 0.18, view.size.y * 0.11), [
		Color("#e7dfd1"), Color("#d7cab7"), Color("#a3b6b4")
	])
	_draw_drawers(Rect2(view.size.x * 0.12, view.size.y * 0.66, view.size.x * 0.73, view.size.y * 0.12))
	if boss_visible:
		_draw_character(Vector2(view.size.x * 0.79, view.size.y * 0.55), Color("#4d7777"), Color("#efcfb5"), true)


func _draw_sub_table(view: Rect2) -> void:
	_draw_tile_wall(Rect2(view.size.x * 0.04, view.size.y * 0.2, view.size.x * 0.92, view.size.y * 0.43))
	_draw_fridge(Rect2(view.size.x * 0.07, view.size.y * 0.26, view.size.x * 0.25, view.size.y * 0.52), false)
	_draw_counter(Rect2(view.size.x * 0.36, view.size.y * 0.58, view.size.x * 0.57, view.size.y * 0.2), Color("#695044"))
	_draw_microwave(Rect2(view.size.x * 0.57, view.size.y * 0.42, view.size.x * 0.23, view.size.y * 0.16))
	_draw_shelf(Rect2(view.size.x * 0.4, view.size.y * 0.25, view.size.x * 0.46, view.size.y * 0.12), [
		Color("#b46649"), Color("#779565"), Color("#d3a44f"), Color("#8c6fa7"), Color("#5d8394")
	])
	_draw_freezer_bins(Rect2(view.size.x * 0.4, view.size.y * 0.64, view.size.x * 0.14, view.size.y * 0.13))


func _draw_display_fridge(view: Rect2) -> void:
	_draw_window(Rect2(view.size.x * 0.06, view.size.y * 0.18, view.size.x * 0.24, view.size.y * 0.26))
	_draw_fridge(Rect2(view.size.x * 0.08, view.size.y * 0.31, view.size.x * 0.4, view.size.y * 0.47), true)
	_draw_blender_station(Rect2(view.size.x * 0.59, view.size.y * 0.35, view.size.x * 0.25, view.size.y * 0.43))
	_draw_plant(Vector2(view.size.x * 0.91, view.size.y * 0.72), view.size.y * 0.18)


func _draw_pickup_counter(view: Rect2) -> void:
	_draw_window(Rect2(view.size.x * 0.08, view.size.y * 0.19, view.size.x * 0.27, view.size.y * 0.28))
	_draw_pickup_sign(Rect2(view.size.x * 0.42, view.size.y * 0.23, view.size.x * 0.23, view.size.y * 0.1))
	_draw_counter(Rect2(view.size.x * 0.05, view.size.y * 0.58, view.size.x * 0.9, view.size.y * 0.22), Color("#694638"))
	_draw_tray(Rect2(view.size.x * 0.27, view.size.y * 0.53, view.size.x * 0.22, view.size.y * 0.06))
	_draw_straw_station(Rect2(view.size.x * 0.7, view.size.y * 0.43, view.size.x * 0.16, view.size.y * 0.15))
	_draw_syrup_bottles(Rect2(view.size.x * 0.55, view.size.y * 0.46, view.size.x * 0.11, view.size.y * 0.12))


func _draw_counter(rect: Rect2, color: Color) -> void:
	draw_style_box(_box(color.lightened(0.08), color.darkened(0.24), 3.0, 5.0), rect)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.16)), color.lightened(0.22))
	for index in range(1, 5):
		var x := rect.position.x + rect.size.x * float(index) / 5.0
		draw_line(Vector2(x, rect.position.y + rect.size.y * 0.18), Vector2(x, rect.end.y), color.darkened(0.12), 1.0)


func _draw_window(rect: Rect2) -> void:
	draw_style_box(_box(Color("#acd4d5"), Color("#52696a"), 4.0, 3.0), rect)
	draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y), Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y), Color("#e9f3ef"), 3.0)
	draw_line(Vector2(rect.position.x, rect.position.y + rect.size.y * 0.58), Vector2(rect.end.x, rect.position.y + rect.size.y * 0.58), Color("#e9f3ef"), 3.0)
	draw_circle(rect.position + rect.size * Vector2(0.23, 0.22), 12.0, Color("#f4c45f"))


func _draw_pendant(center: Vector2) -> void:
	draw_line(center - Vector2(0.0, 60.0), center, Color("#514740"), 3.0)
	draw_polygon(PackedVector2Array([
		center + Vector2(-24.0, 0.0),
		center + Vector2(24.0, 0.0),
		center + Vector2(14.0, 22.0),
		center + Vector2(-14.0, 22.0),
	]), PackedColorArray([Color("#43565b")]))
	draw_circle(center + Vector2(0.0, 24.0), 9.0, Color("#f3cf78"))


func _draw_character(center: Vector2, shirt: Color, skin: Color, apron: bool) -> void:
	_draw_ellipse(center + Vector2(0.0, 56.0), Vector2(36.0, 10.0), Color(0.15, 0.12, 0.1, 0.24))
	draw_circle(center - Vector2(0.0, 47.0), 27.0, Color("#463b38"))
	draw_circle(center - Vector2(0.0, 39.0), 23.0, skin)
	draw_circle(center + Vector2(-8.0, -41.0), 2.4, Color("#3f3633"))
	draw_circle(center + Vector2(8.0, -41.0), 2.4, Color("#3f3633"))
	draw_arc(center + Vector2(0.0, -32.0), 7.0, 0.25, PI - 0.25, 10, Color("#9d5d55"), 2.0)
	draw_style_box(_box(shirt, shirt.darkened(0.2), 2.0, 18.0), Rect2(center + Vector2(-32.0, -12.0), Vector2(64.0, 78.0)))
	if apron:
		draw_polygon(PackedVector2Array([
			center + Vector2(-21.0, 5.0),
			center + Vector2(21.0, 5.0),
			center + Vector2(28.0, 63.0),
			center + Vector2(-28.0, 63.0),
		]), PackedColorArray([Color("#e8dfcf")]))


func _draw_register_machine(rect: Rect2) -> void:
	draw_style_box(_box(Color("#29383c"), Color("#172428"), 2.0, 7.0), rect)
	draw_rect(rect.grow(-8.0), Color("#7ea8a7"))
	draw_line(Vector2(rect.position.x + 10.0, rect.end.y), Vector2(rect.position.x + 4.0, rect.end.y + 18.0), Color("#29383c"), 5.0)


func _draw_receipt_printer(rect: Rect2) -> void:
	draw_style_box(_box(Color("#ede9df"), Color("#9b968d"), 2.0, 5.0), rect)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.26, -rect.size.y * 0.65), Vector2(rect.size.x * 0.5, rect.size.y * 0.72)), Color("#fffdf5"))
	for index in range(3):
		var y := rect.position.y - rect.size.y * 0.48 + float(index) * 6.0
		draw_line(Vector2(rect.position.x + rect.size.x * 0.34, y), Vector2(rect.end.x - rect.size.x * 0.34, y), Color("#b8b1a7"), 1.0)


func _draw_tile_wall(rect: Rect2) -> void:
	draw_rect(rect, Color("#dce5e1"))
	var tile := maxf(34.0, rect.size.y / 5.0)
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("#bdcbc6"), 1.0)
		x += tile
	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("#bdcbc6"), 1.0)
		y += tile


func _draw_brick_wall(rect: Rect2) -> void:
	draw_rect(rect, Color("#c7aa91"))
	var row_height := maxf(28.0, rect.size.y / 6.0)
	for row in range(7):
		var y := rect.position.y + float(row) * row_height
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), Color("#aa8974"), 1.0)
		var offset := row_height if row % 2 == 1 else 0.0
		var x := rect.position.x - offset
		while x <= rect.end.x:
			draw_line(Vector2(x, y), Vector2(x, minf(y + row_height, rect.end.y)), Color("#aa8974"), 1.0)
			x += row_height * 2.0


func _draw_shelf(rect: Rect2, colors: Array[Color]) -> void:
	draw_rect(Rect2(rect.position + Vector2(0.0, rect.size.y * 0.78), Vector2(rect.size.x, rect.size.y * 0.18)), Color("#6b4d3f"))
	var item_width := rect.size.x / maxf(1.0, float(colors.size()))
	for index in range(colors.size()):
		var item := Rect2(rect.position + Vector2(float(index) * item_width + 5.0, rect.size.y * 0.1), Vector2(item_width - 10.0, rect.size.y * 0.68))
		draw_style_box(_box(colors[index], colors[index].darkened(0.2), 1.5, 4.0), item)


func _draw_ice_machine(rect: Rect2) -> void:
	draw_style_box(_box(Color("#d9e4e3"), Color("#627879"), 3.0, 8.0), rect)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.12, rect.size.y * 0.13), Vector2(rect.size.x * 0.76, rect.size.y * 0.24)), Color("#8fbabc"))
	draw_line(Vector2(rect.position.x + rect.size.x * 0.2, rect.position.y + rect.size.y * 0.58), Vector2(rect.end.x - rect.size.x * 0.2, rect.position.y + rect.size.y * 0.58), Color("#6f8585"), 4.0)
	draw_circle(rect.position + Vector2(rect.size.x * 0.5, rect.size.y * 0.48), 5.0, Color("#5a7071"))


func _draw_espresso_machine(rect: Rect2) -> void:
	draw_style_box(_box(Color("#6f7d7e"), Color("#303d40"), 4.0, 10.0), rect)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.08, rect.size.y * 0.12), Vector2(rect.size.x * 0.84, rect.size.y * 0.24)), Color("#9ea9a7"))
	for index in range(3):
		draw_circle(rect.position + Vector2(rect.size.x * (0.28 + float(index) * 0.22), rect.size.y * 0.24), 7.0, Color("#d8c071"))
	for index in range(2):
		var x := rect.position.x + rect.size.x * (0.37 + float(index) * 0.27)
		draw_line(Vector2(x, rect.position.y + rect.size.y * 0.55), Vector2(x, rect.end.y + rect.size.y * 0.18), Color("#2d393b"), 7.0)
		draw_line(Vector2(x - rect.size.x * 0.12, rect.position.y + rect.size.y * 0.62), Vector2(x + rect.size.x * 0.09, rect.position.y + rect.size.y * 0.62), Color("#2d393b"), 7.0)


func _draw_drawers(rect: Rect2) -> void:
	for index in range(4):
		var drawer := Rect2(rect.position + Vector2(float(index) * rect.size.x / 4.0, 0.0), Vector2(rect.size.x / 4.0 - 4.0, rect.size.y))
		draw_style_box(_box(Color("#a8795d").lightened(float(index) * 0.025), Color("#654533"), 2.0, 3.0), drawer)
		draw_line(drawer.get_center() - Vector2(12.0, 8.0), drawer.get_center() + Vector2(12.0, -8.0), Color("#44352d"), 3.0)


func _draw_fridge(rect: Rect2, glass: bool) -> void:
	var fill := Color("#799da0") if glass else Color("#cad5d3")
	draw_style_box(_box(fill, Color("#4e6466"), 4.0, 8.0), rect)
	if glass:
		draw_rect(rect.grow(-10.0), Color(0.55, 0.79, 0.8, 0.72))
		for index in range(1, 4):
			var y := rect.position.y + rect.size.y * float(index) / 4.0
			draw_line(Vector2(rect.position.x + 10.0, y), Vector2(rect.end.x - 10.0, y), Color("#e6f0eb"), 3.0)
		for row in range(3):
			for column in range(4):
				var bottle := Rect2(rect.position + Vector2(20.0 + float(column) * rect.size.x * 0.2, 24.0 + float(row) * rect.size.y * 0.23), Vector2(rect.size.x * 0.1, rect.size.y * 0.13))
				draw_rect(bottle, [Color("#d46457"), Color("#e8b955"), Color("#6b9894"), Color("#8d75a8")][column])
	else:
		draw_line(Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + 8.0), Vector2(rect.position.x + rect.size.x * 0.5, rect.end.y - 8.0), Color("#8d9d9b"), 2.0)
		draw_line(Vector2(rect.position.x + rect.size.x * 0.43, rect.position.y + rect.size.y * 0.25), Vector2(rect.position.x + rect.size.x * 0.43, rect.position.y + rect.size.y * 0.48), Color("#667876"), 5.0)


func _draw_microwave(rect: Rect2) -> void:
	draw_style_box(_box(Color("#d2d3cd"), Color("#62645f"), 3.0, 6.0), rect)
	draw_rect(Rect2(rect.position + Vector2(9.0, 9.0), Vector2(rect.size.x * 0.67, rect.size.y - 18.0)), Color("#3d4b4d"))
	draw_circle(rect.position + Vector2(rect.size.x * 0.85, rect.size.y * 0.38), 6.0, Color("#c6a952"))
	draw_circle(rect.position + Vector2(rect.size.x * 0.85, rect.size.y * 0.65), 6.0, Color("#788480"))


func _draw_freezer_bins(rect: Rect2) -> void:
	for index in range(2):
		var bin := Rect2(rect.position + Vector2(float(index) * rect.size.x * 0.52, 0.0), Vector2(rect.size.x * 0.46, rect.size.y))
		draw_style_box(_box(Color("#afc9cc"), Color("#698589"), 2.0, 5.0), bin)
		draw_line(Vector2(bin.position.x + 8.0, bin.position.y + 10.0), Vector2(bin.end.x - 8.0, bin.position.y + 10.0), Color("#e5eeee"), 3.0)


func _draw_blender_station(rect: Rect2) -> void:
	_draw_counter(Rect2(rect.position + Vector2(0.0, rect.size.y * 0.58), Vector2(rect.size.x, rect.size.y * 0.42)), Color("#5b4540"))
	draw_style_box(_box(Color("#59686a"), Color("#344245"), 3.0, 7.0), Rect2(rect.position + Vector2(rect.size.x * 0.2, rect.size.y * 0.43), Vector2(rect.size.x * 0.6, rect.size.y * 0.2)))
	draw_polygon(PackedVector2Array([
		rect.position + Vector2(rect.size.x * 0.32, rect.size.y * 0.05),
		rect.position + Vector2(rect.size.x * 0.68, rect.size.y * 0.05),
		rect.position + Vector2(rect.size.x * 0.76, rect.size.y * 0.43),
		rect.position + Vector2(rect.size.x * 0.24, rect.size.y * 0.43),
	]), PackedColorArray([Color(0.7, 0.88, 0.88, 0.78)]))
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.29, 0.0), Vector2(rect.size.x * 0.42, rect.size.y * 0.06)), Color("#59686a"))


func _draw_pickup_sign(rect: Rect2) -> void:
	draw_style_box(_box(Color("#e7b956"), Color("#6f4f37"), 3.0, 5.0), rect)
	for index in range(3):
		var x := rect.position.x + rect.size.x * (0.3 + float(index) * 0.2)
		draw_circle(Vector2(x, rect.get_center().y), 4.0, Color("#72523a"))


func _draw_tray(rect: Rect2) -> void:
	draw_style_box(_box(Color("#bd9360"), Color("#674c34"), 2.0, 6.0), rect)
	draw_rect(rect.grow(-6.0), Color("#8a6746"))


func _draw_straw_station(rect: Rect2) -> void:
	draw_style_box(_box(Color("#e8e1d2"), Color("#7d7165"), 2.0, 7.0), Rect2(rect.position + Vector2(0.0, rect.size.y * 0.36), Vector2(rect.size.x, rect.size.y * 0.64)))
	for index in range(8):
		var x := rect.position.x + 10.0 + float(index) * (rect.size.x - 20.0) / 7.0
		draw_line(Vector2(x, rect.position.y), Vector2(x + 2.0, rect.position.y + rect.size.y * 0.58), [Color("#d36d63"), Color("#5c8e92"), Color("#d5af53")][index % 3], 3.0)


func _draw_syrup_bottles(rect: Rect2) -> void:
	for index in range(3):
		var bottle := Rect2(rect.position + Vector2(float(index) * rect.size.x * 0.34, rect.size.y * 0.23), Vector2(rect.size.x * 0.28, rect.size.y * 0.77))
		draw_style_box(_box([Color("#81523f"), Color("#c07a49"), Color("#a95e5d")][index], Color("#4e3933"), 1.0, 3.0), bottle)
		draw_line(Vector2(bottle.get_center().x, bottle.position.y), Vector2(bottle.get_center().x, rect.position.y), Color("#3e3734"), 3.0)


func _draw_plant(base: Vector2, height: float) -> void:
	draw_polygon(PackedVector2Array([
		base + Vector2(-18.0, 0.0),
		base + Vector2(18.0, 0.0),
		base + Vector2(12.0, height * 0.28),
		base + Vector2(-12.0, height * 0.28),
	]), PackedColorArray([Color("#9f6f4d")]))
	draw_line(base - Vector2(0.0, 2.0), base - Vector2(0.0, height * 0.62), Color("#4d6b4d"), 5.0)
	for offset in [Vector2(-20.0, -height * 0.45), Vector2(19.0, -height * 0.55), Vector2(-10.0, -height * 0.72), Vector2(15.0, -height * 0.8)]:
		draw_circle(base + offset, height * 0.12, Color("#6f9767"))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)


func _box(fill: Color, border: Color, border_width: float, radius: float) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(int(border_width))
	style.set_corner_radius_all(int(radius))
	return style
