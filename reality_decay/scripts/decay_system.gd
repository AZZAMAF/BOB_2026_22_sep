## decay_system.gd
## Standalone decay calculation helpers + glitch level mapping.
## Not an autoload — referenced by UIManager and DistrictManager for mapping.
extends RefCounted

# ─── Glitch Level ────────────────────────────────────────────────────────────
enum GlitchLevel { CLEAR, MINOR, MAJOR, HEAVY }

## Returns a GlitchLevel enum based on how far a district has decayed.
## decay_pct is the DECAY amount (100 - stability).
static func get_glitch_level(stability: float) -> GlitchLevel:
	var decay: float = 100.0 - stability
	if decay < 25.0:
		return GlitchLevel.CLEAR
	elif decay < 50.0:
		return GlitchLevel.MINOR
	elif decay < 75.0:
		return GlitchLevel.MAJOR
	else:
		return GlitchLevel.HEAVY

## Returns a modulate Color for the district quad based on glitch level.
static func get_glitch_color(stability: float) -> Color:
	var decay: float = 100.0 - stability
	if decay < 25.0:
		return Color.WHITE
	elif decay < 50.0:
		return Color(1.0, 0.95, 0.8)           # Warm tint
	elif decay < 75.0:
		return Color(1.0, 0.7, 0.4)            # Orange distortion
	else:
		return Color(1.0, 0.2, 0.2)            # Red flash

## Returns a glitch UV offset magnitude (pixels) for shaders/CanvasItem offset.
static func get_glitch_offset(stability: float) -> float:
	var decay: float = 100.0 - stability
	if decay < 25.0:
		return 0.0
	elif decay < 50.0:
		return randf_range(0.0, 2.0)
	elif decay < 75.0:
		return randf_range(0.0, 5.0)
	else:
		return randf_range(0.0, 10.0)

## Returns an audio distortion amount 0.0–1.0
static func get_audio_distortion(stability: float) -> float:
	return clamp((100.0 - stability) / 100.0, 0.0, 1.0)

## Returns whether a district should flash red (heavy corruption).
static func should_flash_red(stability: float) -> bool:
	return (100.0 - stability) >= 75.0
