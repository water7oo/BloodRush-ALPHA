extends ProgressBar

@onready var fill_style = get("theme_override_styles/fill")

var fullHPColor = Color(0.624, 0.839, 0.012, 1.0)
var lowHPColor = Color(0.937, 0.192, 0.0, 1.0)

func _process(delta: float) -> void:
	if value <= max_value / 3.0:
		fill_style.bg_color = lowHPColor
	else:
		fill_style.bg_color = fullHPColor
