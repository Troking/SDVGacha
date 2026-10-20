extends Sprite3D

@onready var viewport: SubViewport = $SubViewport
@onready var progress_bar: ProgressBar = $SubViewport/ProgressBar

func _ready() -> void:
	texture = viewport.get_texture()
	# Style the HP bar with vivid red and dark border
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	bg_style.border_color = Color(1.0, 1.0, 1.0, 1.0)
	bg_style.border_width_bottom = 2
	bg_style.border_width_top = 2
	bg_style.border_width_left = 2
	bg_style.border_width_right = 2
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.95, 0.15, 0.2, 1.0) # Bright red
	fill_style.corner_radius_top_left = 5
	fill_style.corner_radius_top_right = 5
	fill_style.corner_radius_bottom_left = 5
	fill_style.corner_radius_bottom_right = 5

	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)

func update_hp(current: int, max_val: int) -> void:
	if progress_bar:
		progress_bar.max_value = max_val
		progress_bar.value = current
