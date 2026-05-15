class_name AeroUiInteractionTypes
extends RefCounted
## Stable taxonomy values for AeroBeat's normalized UI interaction contract.
##
## Keep this surface compact and reviewable. Device/surface-specific expansion
## should happen through new adapters or helper components, not by mutating the
## core payload shape.

# ==========================================================================
# SOURCE TYPES
# ==========================================================================

const SOURCE_TYPE_MOUSE: StringName = &"mouse"
const SOURCE_TYPE_TOUCH: StringName = &"touch"
const SOURCE_TYPE_XR: StringName = &"xr"
const SOURCE_TYPE_UNKNOWN: StringName = &"unknown"

const SOURCE_TYPES: Array[StringName] = [
	SOURCE_TYPE_MOUSE,
	SOURCE_TYPE_TOUCH,
	SOURCE_TYPE_XR,
	SOURCE_TYPE_UNKNOWN
]

# ==========================================================================
# SOURCE VARIANTS
# ==========================================================================

const SOURCE_VARIANT_SCREEN_MOUSE: StringName = &"screen_mouse"
const SOURCE_VARIANT_SCREEN_TOUCH: StringName = &"screen_touch"
const SOURCE_VARIANT_XR_RAY: StringName = &"xr_ray"
const SOURCE_VARIANT_XR_DIRECT: StringName = &"xr_direct"
const SOURCE_VARIANT_UNKNOWN: StringName = &"unknown"

const SOURCE_VARIANTS: Array[StringName] = [
	SOURCE_VARIANT_SCREEN_MOUSE,
	SOURCE_VARIANT_SCREEN_TOUCH,
	SOURCE_VARIANT_XR_RAY,
	SOURCE_VARIANT_XR_DIRECT,
	SOURCE_VARIANT_UNKNOWN
]

# ==========================================================================
# SURFACE TYPES
# ==========================================================================

const SURFACE_TYPE_SCREEN_2D: StringName = &"screen_2d"
const SURFACE_TYPE_WORLD_3D: StringName = &"world_3d"
const SURFACE_TYPE_HYBRID_3D_GUI: StringName = &"hybrid_3d_gui"

const SURFACE_TYPES: Array[StringName] = [
	SURFACE_TYPE_SCREEN_2D,
	SURFACE_TYPE_WORLD_3D,
	SURFACE_TYPE_HYBRID_3D_GUI
]

# ==========================================================================
# PHASES
# ==========================================================================

const PHASE_HOVER_ENTER: StringName = &"hover_enter"
const PHASE_HOVER_MOVE: StringName = &"hover_move"
const PHASE_HOVER_EXIT: StringName = &"hover_exit"
const PHASE_PRESS_BEGIN: StringName = &"press_begin"
const PHASE_PRESS_HOLD: StringName = &"press_hold"
const PHASE_DRAG_BEGIN: StringName = &"drag_begin"
const PHASE_DRAG_MOVE: StringName = &"drag_move"
const PHASE_DRAG_END: StringName = &"drag_end"
const PHASE_PRESS_END: StringName = &"press_end"
const PHASE_CANCEL: StringName = &"cancel"

const PHASES: Array[StringName] = [
	PHASE_HOVER_ENTER,
	PHASE_HOVER_MOVE,
	PHASE_HOVER_EXIT,
	PHASE_PRESS_BEGIN,
	PHASE_PRESS_HOLD,
	PHASE_DRAG_BEGIN,
	PHASE_DRAG_MOVE,
	PHASE_DRAG_END,
	PHASE_PRESS_END,
	PHASE_CANCEL
]

# ==========================================================================
# BUTTON / CONTACT TAXONOMY
# ==========================================================================

const BUTTON_PRIMARY: StringName = &"primary"
const BUTTON_SECONDARY: StringName = &"secondary"
const BUTTON_TERTIARY: StringName = &"tertiary"
const BUTTON_CONTACT: StringName = &"contact"
const BUTTON_TRIGGER: StringName = &"trigger"
const BUTTON_UNKNOWN: StringName = &"unknown"

const BUTTONS: Array[StringName] = [
	BUTTON_PRIMARY,
	BUTTON_SECONDARY,
	BUTTON_TERTIARY,
	BUTTON_CONTACT,
	BUTTON_TRIGGER,
	BUTTON_UNKNOWN
]

static func is_valid_source_type(value: StringName) -> bool:
	return SOURCE_TYPES.has(value)

static func is_valid_source_variant(value: StringName) -> bool:
	return SOURCE_VARIANTS.has(value)

static func is_valid_surface_type(value: StringName) -> bool:
	return SURFACE_TYPES.has(value)

static func is_valid_phase(value: StringName) -> bool:
	return PHASES.has(value)

static func is_valid_button(value: StringName) -> bool:
	return BUTTONS.has(value)

static func normalize_mouse_button(mouse_button_index: MouseButton) -> StringName:
	match mouse_button_index:
		MOUSE_BUTTON_LEFT:
			return BUTTON_PRIMARY
		MOUSE_BUTTON_RIGHT:
			return BUTTON_SECONDARY
		MOUSE_BUTTON_MIDDLE:
			return BUTTON_TERTIARY
		_:
			return BUTTON_UNKNOWN
