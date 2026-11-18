extends CanvasLayer
## Efek cuaca di atas dunia: hujan (CPUParticles2D) dan kilat saat Storm.
## Belum ada asset hujan di Modern_Farm, jadi garis hujan dibuat dari tekstur kecil lewat kode.

const VIEW_W := 640.0

var _rain: CPUParticles2D
var _flash: ColorRect
var _flash_timer: Timer


func _ready() -> void:
	_rain = CPUParticles2D.new()
	_rain.position = Vector2(VIEW_W / 2.0, -10.0)
	_rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_rain.emission_rect_extents = Vector2(VIEW_W / 2.0 + 60.0, 1.0)
	_rain.direction = Vector2(-0.15, 1.0)
	_rain.spread = 2.0
	_rain.gravity = Vector2.ZERO
	_rain.initial_velocity_min = 300.0
	_rain.initial_velocity_max = 340.0
	_rain.lifetime = 1.3
	_rain.preprocess = 1.3
	_rain.texture = _make_streak()
	_rain.modulate = Color(0.75, 0.85, 1.0, 0.7)
	_rain.emitting = false
	add_child(_rain)

	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)

	_flash_timer = Timer.new()
	_flash_timer.one_shot = true
	_flash_timer.timeout.connect(_on_flash_timer)
	add_child(_flash_timer)

	TimeManager.weather_changed.connect(_apply)
	_apply(TimeManager.weather)


func _apply(weather: int) -> void:
	var raining := weather == TimeManager.Weather.RAIN or weather == TimeManager.Weather.STORM
	_rain.amount = 260 if weather == TimeManager.Weather.STORM else 120
	_rain.emitting = raining
	if weather == TimeManager.Weather.STORM:
		_flash_timer.start(randf_range(3.0, 7.0))
	else:
		_flash_timer.stop()


func _on_flash_timer() -> void:
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.45, 0.05)
	tween.tween_property(_flash, "color:a", 0.0, 0.25)
	_flash_timer.start(randf_range(4.0, 9.0))


func _make_streak() -> ImageTexture:
	var img := Image.create(1, 5, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
