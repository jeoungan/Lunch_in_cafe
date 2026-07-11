extends Control
class_name CupComposer

signal layer_changed(layers: Array[String])

const CUP_TEXTURE_PATH := "res://assets/generated/drinks/layers/empty_clear_plastic_cup.png"
const REQUIRED_LAYERS: Array[String] = ["cup", "water", "ice", "espresso", "lid", "sleeve"]

var _cup_texture: Texture2D = null
var _layers: Array[String] = []
var _water_level: float = 0.0
var _espresso_mix: float = 0.0
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CUP_TEXTURE_PATH):
		_cup_texture = load(CUP_TEXTURE_PATH) as Texture2D
	resized.connect(queue_redraw)
	queue_redraw()


func reset() -> void:
	_layers.clear()
	_water_level = 0.0
	_espresso_mix = 0.0
	_pulse = 0.0
	queue_redraw()
	layer_changed.emit(layers())


func apply_layer(layer: String) -> bool:
	if not layer in REQUIRED_LAYERS or layer in _layers:
		return false
	_layers.append(layer)
	match layer:
		"water":
			_animate_value("_water_level", 0.36, 0.32)
		"ice":
			_animate_value("_water_level", 0.5, 0.24)
		"espresso":
			_animate_value("_espresso_mix", 1.0, 0.65)
		_:
			_bump()
	queue_redraw()
	layer_changed.emit(layers())
	return true


func has_layer(layer: String) -> bool:
	return layer in _layers


func layers() -> Array[String]:
	return _layers.duplicate()


func progress_ratio() -> float:
	return float(_layers.size()) / float(REQUIRED_LAYERS.size())


func is_complete() -> bool:
	return _layers == REQUIRED_LAYERS


func _animate_value(property_name: String, target: float, duration: float) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, property_name, target, duration)
	tween.parallel().tween_method(func(_value: float) -> void: queue_redraw(), 0.0, 1.0, duration)


func _bump() -> void:
	_pulse = 1.0
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_pulse", 0.0, 0.28)
	tween.parallel().tween_method(func(_value: float) -> void: queue_redraw(), 0.0, 1.0, 0.28)


func _draw() -> void:
	var cup_rect := _cup_rect()
	var scale_bump := 1.0 + _pulse * 0.025
	var center := cup_rect.get_center()
	var bumped := Rect2(center - cup_rect.size * scale_bump * 0.5, cup_rect.size * scale_bump)
	_draw_ellipse(Vector2(center.x, bumped.end.y + 8.0), Vector2(bumped.size.x * 0.28, 10.0), Color(0.12, 0.1, 0.08, 0.18))

	if not has_layer("cup"):
		_draw_empty_slot(bumped)
		return

	if _cup_texture != null:
		draw_texture_rect(_cup_texture, bumped, false, Color(1.0, 1.0, 1.0, 0.96))
	else:
		_draw_fallback_cup(bumped)
	if has_layer("water"):
		_draw_liquid(bumped)
	if has_layer("ice"):
		_draw_ice(bumped)
	if has_layer("espresso"):
		_draw_espresso_clouds(bumped)

	if has_layer("lid"):
		_draw_lid(bumped)
	if has_layer("sleeve"):
		_draw_sleeve(bumped)
	_draw_glints(bumped)


func _cup_rect() -> Rect2:
	var target_height := minf(size.y * 0.88, 300.0)
	var target_width := target_height
	return Rect2(
		Vector2((size.x - target_width) * 0.5, (size.y - target_height) * 0.5),
		Vector2(target_width, target_height)
	)


func _draw_empty_slot(rect: Rect2) -> void:
	var outline := Color(0.35, 0.45, 0.46, 0.45)
	draw_arc(Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.2), rect.size.x * 0.22, PI, TAU, 30, outline, 3.0)
	draw_line(Vector2(rect.position.x + rect.size.x * 0.28, rect.position.y + rect.size.y * 0.2), Vector2(rect.position.x + rect.size.x * 0.36, rect.position.y + rect.size.y * 0.8), outline, 3.0)
	draw_line(Vector2(rect.end.x - rect.size.x * 0.28, rect.position.y + rect.size.y * 0.2), Vector2(rect.end.x - rect.size.x * 0.36, rect.position.y + rect.size.y * 0.8), outline, 3.0)
	draw_arc(Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.8), rect.size.x * 0.14, 0.0, PI, 24, outline, 3.0)
	for index in range(8):
		var angle := TAU * float(index) / 8.0
		var dot := rect.get_center() + Vector2(cos(angle) * rect.size.x * 0.32, sin(angle) * rect.size.y * 0.38)
		draw_circle(dot, 2.0, outline)


func _draw_liquid(rect: Rect2) -> void:
	var top_y := rect.position.y + rect.size.y * (0.78 - _water_level * 0.78)
	var bottom_y := rect.position.y + rect.size.y * 0.78
	var top_half := rect.size.x * (0.16 + _water_level * 0.07)
	var bottom_half := rect.size.x * 0.14
	var center_x := rect.get_center().x
	var water := Color("#79c9df")
	var coffee := Color("#714329")
	var fill := water.lerp(coffee, _espresso_mix * 0.82)
	var liquid := PackedVector2Array([
		Vector2(center_x - top_half, top_y),
		Vector2(center_x + top_half, top_y),
		Vector2(center_x + bottom_half, bottom_y),
		Vector2(center_x - bottom_half, bottom_y),
	])
	draw_colored_polygon(liquid, fill)
	_draw_ellipse(Vector2(center_x, top_y), Vector2(top_half, maxf(3.0, rect.size.y * 0.018)), fill.lightened(0.13))
	draw_line(Vector2(center_x - top_half * 0.92, top_y), Vector2(center_x + top_half * 0.92, top_y), Color(1.0, 1.0, 1.0, 0.38), 2.0)


func _draw_ice(rect: Rect2) -> void:
	var center_x := rect.get_center().x
	var surface_y := rect.position.y + rect.size.y * (0.78 - _water_level * 0.78)
	var cube_size := rect.size.x * 0.075
	var offsets: Array[Vector2] = [
		Vector2(-cube_size * 1.5, cube_size * 0.2),
		Vector2(-cube_size * 0.25, cube_size * 0.55),
		Vector2(cube_size * 1.0, cube_size * 0.1),
		Vector2(cube_size * 0.45, cube_size * 1.5),
	]
	for index in range(offsets.size()):
		var center: Vector2 = Vector2(center_x, surface_y) + offsets[index]
		var skew := 0.18 if index % 2 == 0 else -0.12
		var points := PackedVector2Array([
			center + Vector2(-cube_size, -cube_size * 0.7),
			center + Vector2(cube_size * (1.0 + skew), -cube_size),
			center + Vector2(cube_size, cube_size * 0.75),
			center + Vector2(-cube_size * (1.0 - skew), cube_size),
		])
		draw_colored_polygon(points, Color(0.86, 0.97, 1.0, 0.72))
		draw_polyline(points, Color(0.55, 0.78, 0.86, 0.78), 2.0)
		draw_line(center - Vector2(cube_size * 0.45, cube_size * 0.3), center + Vector2(cube_size * 0.35, -cube_size * 0.48), Color(1.0, 1.0, 1.0, 0.72), 2.0)


func _draw_espresso_clouds(rect: Rect2) -> void:
	var transition := 1.0 - _espresso_mix
	if transition <= 0.02:
		return
	var center_x := rect.get_center().x
	var top_y := rect.position.y + rect.size.y * (0.78 - _water_level * 0.78)
	var brown := Color(0.38, 0.18, 0.09, 0.18 + transition * 0.3)
	for index in range(7):
		var spread := rect.size.x * 0.04 * float(index)
		var x := center_x + sin(float(index) * 1.7) * spread
		var y := top_y + rect.size.y * (0.025 + float(index) * 0.045)
		draw_circle(Vector2(x, y), rect.size.x * (0.055 + float(index % 3) * 0.012), brown)
	draw_line(Vector2(center_x, rect.position.y + rect.size.y * 0.23), Vector2(center_x, top_y + rect.size.y * 0.08), Color(0.29, 0.13, 0.06, 0.72 * transition), maxf(3.0, rect.size.x * 0.02))


func _draw_lid(rect: Rect2) -> void:
	var center := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.205)
	var width := rect.size.x * 0.25
	var lid_height := rect.size.y * 0.035
	var top_center := center - Vector2(0.0, lid_height * 1.7)
	var shell := PackedVector2Array([
		center + Vector2(-width, 0.0),
		center + Vector2(width, 0.0),
		top_center + Vector2(width * 0.78, 0.0),
		top_center + Vector2(-width * 0.78, 0.0),
	])
	draw_colored_polygon(shell, Color(0.91, 0.95, 0.94, 0.72))
	_draw_ellipse(top_center, Vector2(width * 0.78, lid_height * 0.55), Color(0.97, 0.99, 0.98, 0.9))
	_draw_ellipse(center, Vector2(width, lid_height * 0.7), Color(0.86, 0.92, 0.91, 0.86))
	draw_polyline(shell, Color("#647779"), 3.0)


func _draw_sleeve(rect: Rect2) -> void:
	var center_x := rect.get_center().x
	var top_y := rect.position.y + rect.size.y * 0.49
	var bottom_y := rect.position.y + rect.size.y * 0.68
	var points := PackedVector2Array([
		Vector2(center_x - rect.size.x * 0.205, top_y),
		Vector2(center_x + rect.size.x * 0.205, top_y),
		Vector2(center_x + rect.size.x * 0.175, bottom_y),
		Vector2(center_x - rect.size.x * 0.175, bottom_y),
	])
	draw_colored_polygon(points, Color("#bd825b"))
	draw_polyline(points, Color("#704c36"), 3.0)
	draw_circle(Vector2(center_x, (top_y + bottom_y) * 0.5), rect.size.x * 0.035, Color("#f0d39a"))


func _draw_glints(rect: Rect2) -> void:
	if not has_layer("cup"):
		return
	var left := rect.position + Vector2(rect.size.x * 0.36, rect.size.y * 0.29)
	draw_line(left, left + Vector2(-rect.size.x * 0.025, rect.size.y * 0.17), Color(1.0, 1.0, 1.0, 0.72), 3.0)
	draw_circle(left - Vector2(4.0, 7.0), 3.0, Color(1.0, 1.0, 1.0, 0.9))


func _draw_fallback_cup(rect: Rect2) -> void:
	var outline := Color(0.72, 0.84, 0.84, 0.92)
	var center_x: float = rect.get_center().x
	var top_y: float = rect.position.y + rect.size.y * 0.18
	var bottom_y: float = rect.position.y + rect.size.y * 0.82
	draw_arc(Vector2(center_x, top_y), rect.size.x * 0.25, 0.0, TAU, 40, outline, 4.0)
	draw_line(Vector2(center_x - rect.size.x * 0.25, top_y), Vector2(center_x - rect.size.x * 0.14, bottom_y), outline, 4.0)
	draw_line(Vector2(center_x + rect.size.x * 0.25, top_y), Vector2(center_x + rect.size.x * 0.14, bottom_y), outline, 4.0)
	_draw_ellipse(Vector2(center_x, bottom_y), Vector2(rect.size.x * 0.14, rect.size.y * 0.025), Color(0.75, 0.88, 0.88, 0.34))


func _draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in range(36):
		var angle := TAU * float(index) / 36.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
