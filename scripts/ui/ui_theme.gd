extends RefCounted
class_name IronveilUITheme

## Shared visual language for IRONVEIL UI
## Target: clean modern industrial / terminal aesthetic
## that sits well with Sea-of-Stars quality pixel art
## (crisp, readable, warm brass accents, not muddy).

const BG_DEEP := Color(0.04, 0.055, 0.06, 0.94)
const BG_PANEL := Color(0.055, 0.07, 0.075, 0.92)
const BG_MODAL := Color(0.03, 0.04, 0.045, 0.97)
const BG_ACCENT_STRIP := Color(0.12, 0.09, 0.04, 0.95)

const BORDER_SOFT := Color(0.28, 0.32, 0.30, 0.75)
const BORDER_BRASS := Color(0.72, 0.55, 0.28, 0.95)
const BORDER_BRASS_DIM := Color(0.48, 0.38, 0.20, 0.85)
const BORDER_DANGER := Color(0.75, 0.28, 0.22, 0.9)

const TEXT_PRIMARY := Color(0.92, 0.93, 0.90, 1.0)
const TEXT_SECONDARY := Color(0.70, 0.74, 0.70, 1.0)
const TEXT_ACCENT := Color(0.95, 0.78, 0.38, 1.0)
const TEXT_GOOD := Color(0.45, 0.85, 0.55, 1.0)
const TEXT_WARN := Color(0.95, 0.72, 0.30, 1.0)
const TEXT_BAD := Color(0.95, 0.40, 0.35, 1.0)

const BAR_HEALTH := Color(0.78, 0.28, 0.28, 1.0)
const BAR_STAMINA := Color(0.35, 0.65, 0.95, 1.0)
const BAR_HUNGER := Color(0.85, 0.62, 0.28, 1.0)
const BAR_BOSS := Color(0.85, 0.22, 0.28, 1.0)

static func panel_style(modal: bool = false, danger: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BG_MODAL if modal else BG_PANEL
	if danger:
		style.border_color = BORDER_DANGER
	else:
		style.border_color = BORDER_BRASS if modal else BORDER_SOFT
	style.set_border_width_all(2 if modal else 1)
	var radius: int = 8 if modal else 6
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.set_content_margin_all(18.0 if modal else 12.0)
	# subtle inner feel
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4 if modal else 2
	style.shadow_offset = Vector2(0, 2)
	return style

static func prompt_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.07, 0.94)
	style.border_color = BORDER_BRASS
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(12.0)
	return style

static func notification_style(kind: String = "info") -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.07, 0.95)
	match kind:
		"error":
			style.border_color = BORDER_DANGER
		"success":
			style.border_color = Color(0.30, 0.70, 0.40, 0.95)
		_:
			style.border_color = BORDER_BRASS_DIM
	style.set_border_width_all(2)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.set_content_margin_all(14.0)
	return style

static func button_style(hover: bool = false, pressed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if pressed:
		style.bg_color = Color(0.18, 0.14, 0.08, 0.98)
		style.border_color = BORDER_BRASS
	elif hover:
		style.bg_color = Color(0.12, 0.11, 0.08, 0.96)
		style.border_color = BORDER_BRASS
	else:
		style.bg_color = Color(0.07, 0.08, 0.08, 0.94)
		style.border_color = BORDER_SOFT
	style.set_border_width_all(1)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.set_content_margin_all(10.0)
	return style

static func apply_label_colors(label: Label, accent: bool = false, secondary: bool = false) -> void:
	if accent:
		label.add_theme_color_override("font_color", TEXT_ACCENT)
	elif secondary:
		label.add_theme_color_override("font_color", TEXT_SECONDARY)
	else:
		label.add_theme_color_override("font_color", TEXT_PRIMARY)

static func apply_rich_defaults(rtl: RichTextLabel) -> void:
	rtl.add_theme_color_override("default_color", TEXT_PRIMARY)
	rtl.bbcode_enabled = true
