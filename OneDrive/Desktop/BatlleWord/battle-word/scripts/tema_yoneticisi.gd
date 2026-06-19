extends Node

const ARKAPLAN   = Color("#0D1B2A")
const MAVI       = Color("#4895EF")
const TURUNCU    = Color("#F4A261")
const YESIL      = Color("#2DC653")
const KIRMIZI    = Color("#E63946")
const BEYAZ      = Color("#FFFFFF")
const GRI        = Color("#888888")
const PANEL_BG   = Color("#162436")
const PANEL_BOR  = Color("#2A3F55")
const GIRIS_BG   = Color("#0F2235")

func _ready() -> void:
	get_tree().root.theme = _tema_olustur()

func _tema_olustur() -> Theme:
	var t = Theme.new()

	# ── Button ──────────────────────────────────────────────────
	t.set_stylebox("normal",   "Button", _buton_stil(MAVI))
	t.set_stylebox("hover",    "Button", _buton_stil(MAVI.lightened(0.18)))
	t.set_stylebox("pressed",  "Button", _buton_stil(MAVI.darkened(0.22)))
	t.set_stylebox("disabled", "Button", _buton_stil(Color("#2A2A2A")))
	t.set_stylebox("focus",    "Button", _buton_stil(MAVI))
	t.set_color("font_color",          "Button", BEYAZ)
	t.set_color("font_hover_color",    "Button", BEYAZ)
	t.set_color("font_pressed_color",  "Button", BEYAZ)
	t.set_color("font_disabled_color", "Button", GRI)
	t.set_color("font_focus_color",    "Button", BEYAZ)
	t.set_font_size("font_size", "Button", 20)

	# ── Panel / PanelContainer ───────────────────────────────────
	var panel_s = _panel_stil(PANEL_BG, PANEL_BOR, 16)
	t.set_stylebox("panel", "Panel",          panel_s)
	t.set_stylebox("panel", "PanelContainer", panel_s)

	# ── ProgressBar ──────────────────────────────────────────────
	t.set_stylebox("background", "ProgressBar", _yuvarlik_stil(Color("#1B3044"), 6))
	t.set_stylebox("fill",       "ProgressBar", _yuvarlik_stil(MAVI, 6))

	# ── LineEdit ─────────────────────────────────────────────────
	var le_s = _panel_stil(GIRIS_BG, MAVI, 12)
	le_s.content_margin_left   = 18
	le_s.content_margin_right  = 18
	le_s.content_margin_top    = 14
	le_s.content_margin_bottom = 14
	t.set_stylebox("normal", "LineEdit", le_s)
	t.set_stylebox("focus",  "LineEdit", le_s)
	t.set_color("font_color",             "LineEdit", BEYAZ)
	t.set_color("font_placeholder_color", "LineEdit", GRI)
	t.set_color("caret_color",            "LineEdit", MAVI)
	t.set_color("selection_color",        "LineEdit", MAVI)
	t.set_font_size("font_size", "LineEdit", 22)

	# ── Label ────────────────────────────────────────────────────
	t.set_color("font_color", "Label", BEYAZ)
	t.set_font_size("font_size", "Label", 18)

	# ── RichTextLabel ────────────────────────────────────────────
	t.set_color("default_color", "RichTextLabel", BEYAZ)
	t.set_font_size("normal_font_size", "RichTextLabel", 24)

	return t

# ── Yardımcı stil üreticiler ─────────────────────────────────────

func _buton_stil(renk: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = renk
	s.corner_radius_top_left    = 12
	s.corner_radius_top_right   = 12
	s.corner_radius_bottom_left = 12
	s.corner_radius_bottom_right = 12
	s.content_margin_left   = 20
	s.content_margin_right  = 20
	s.content_margin_top    = 10
	s.content_margin_bottom = 10
	return s

func _panel_stil(bg: Color, bor: Color, radius: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color    = bg
	s.border_color = bor
	s.border_width_left   = 2
	s.border_width_top    = 2
	s.border_width_right  = 2
	s.border_width_bottom = 2
	s.corner_radius_top_left    = radius
	s.corner_radius_top_right   = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left   = 16
	s.content_margin_right  = 16
	s.content_margin_top    = 16
	s.content_margin_bottom = 16
	return s

func _yuvarlik_stil(renk: Color, radius: int) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = renk
	s.corner_radius_top_left    = radius
	s.corner_radius_top_right   = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	return s

# ── Özel düğme stilleri (dışarıdan çağrılır) ─────────────────────

func oyna_buton_stili() -> StyleBoxFlat:
	return _buton_stil(TURUNCU)

func oyna_buton_hover_stili() -> StyleBoxFlat:
	return _buton_stil(TURUNCU.lightened(0.18))
