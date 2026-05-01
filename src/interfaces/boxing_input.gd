class_name BoxingInput
extends AeroInputProvider
## Interface for AeroBeat Boxing gameplay input providers.
##
## Boxing is an active camera-first gameplay mode in v1. This contract preserves
## richer gesture hooks for future providers, but callers should not assume that
## every signal below is universally available from every current implementation.
##
## Hand-driven punches, stance, and readable camera motion are the primary v1
## gameplay focus. Lower-body and specialty actions remain optional,
## provider-dependent, and future-facing.

# ============================================================================
# SIGNALS: STANCE & POSITION
# ============================================================================

## Emitted when player assumes standard boxing stance (left side forward).
signal stance_orthodox

## Emitted when player assumes southpaw stance (right side forward).
signal stance_southpaw

## Emitted when player location changes.
## @param zone: "left", "center", or "right"
signal location_changed(zone: StringName)

## Emitted when player height changes.
## @param type: "stand" or "squat"
signal height_changed(type: StringName)

# ============================================================================
# SIGNALS: OFFENSIVE - PUNCHES
# ============================================================================

## Emitted when left punch (jab/straight) is detected.
## @param power: Punch power from 0.0 to 1.0
signal punch_left(power: float)

## Emitted when right punch (jab/straight) is detected.
## @param power: Punch power from 0.0 to 1.0
signal punch_right(power: float)

## Emitted when left uppercut is detected.
## @param power: Uppercut power from 0.0 to 1.0
signal uppercut_left(power: float)

## Emitted when right uppercut is detected.
## @param power: Uppercut power from 0.0 to 1.0
signal uppercut_right(power: float)

## Emitted when left cross is detected.
## @param power: Cross power from 0.0 to 1.0
signal cross_left(power: float)

## Emitted when right cross is detected.
## @param power: Cross power from 0.0 to 1.0
signal cross_right(power: float)

## Emitted when left hook is detected.
## @param power: Hook power from 0.0 to 1.0
signal hook_left(power: float)

## Emitted when right hook is detected.
## @param power: Hook power from 0.0 to 1.0
signal hook_right(power: float)

# ============================================================================
# SIGNALS: DEFENSIVE
# ============================================================================

## Emitted when player raises guard (block start).
signal block_start

## Emitted when player lowers guard (block end).
signal block_end

## Emitted when head weave to left is detected.
signal weave_left

## Emitted when head weave to right is detected.
signal weave_right

## Emitted when combined duck and weave to left is detected.
signal duck_weave_left

## Emitted when combined duck and weave to right is detected.
signal duck_weave_right

# ============================================================================
# SIGNALS: OPTIONAL / FUTURE-FACING EXTENSIONS
# ============================================================================

## Emitted when left knee strike is detected by a provider with lower-body support.
## @param power: Strike power from 0.0 to 1.0
signal knee_strike_left(power: float)

## Emitted when right knee strike is detected by a provider with lower-body support.
## @param power: Strike power from 0.0 to 1.0
signal knee_strike_right(power: float)

## Emitted when left leg lift is detected by a provider with lower-body support.
signal leg_lift_left

## Emitted when right leg lift is detected by a provider with lower-body support.
signal leg_lift_right

## Emitted when player begins running in place in future/provider-specific modes.
signal run_start

## Emitted when player stops running in place in future/provider-specific modes.
signal run_end

# ============================================================================
# CAPABILITY CHECK
# ============================================================================

## Override to report optional boxing capabilities.
## Gesture recognition remains the expected hand-driven gameplay surface for
## boxing, while lower-body and other richer hooks stay false until a concrete
## provider explicitly advertises them.
func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION:
			return true
		_:
			return false
