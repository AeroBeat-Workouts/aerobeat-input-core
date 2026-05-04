class_name FlowInput
extends AeroInputProvider
## Interface for AeroBeat Flow gameplay input providers.
##
## Flow is a camera-first gameplay mode in v1. This contract defines the stable
## gameplay-facing intent surface detectors should emit into.
##
## Important v1 rules:
## - slice placement is the pass-through location the chart authored
## - slice direction is the intended follow-through guidance after that contact
## - placement and direction are different semantics and must not be blurred
## - authored stance semantics like orthodox / southpaw are not tracked input events
## - warn_* / reward_* remain authored Flow semantics, not separate provider gestures
## - run_in_place is a legitimate authored Flow beat, but not a tracked provider event in the first pass
## - state-like movement intents use start/end style signals
##
## Raw pose / observation data remains provider-side and optional; it does not
## replace this gameplay intent contract.

# ============================================================================
# SIGNALS: FLOW MOTION-FAMILY INTENTS
# ============================================================================

## Emitted when a left-handed swing family intent is detected.
## @param placement: Authored pass-through location for the beat family
## @param direction: Authored follow-through guidance for the beat family
signal swing_left(placement: StringName, direction: StringName)

## Emitted when a right-handed swing family intent is detected.
## @param placement: Authored pass-through location for the beat family
## @param direction: Authored follow-through guidance for the beat family
signal swing_right(placement: StringName, direction: StringName)

## Emitted when a left-handed trail family intent is detected.
## @param placement: Authored pass-through location for the beat family
## @param direction: Authored follow-through guidance for the beat family
signal trail_left(placement: StringName, direction: StringName)

## Emitted when a right-handed trail family intent is detected.
## @param placement: Authored pass-through location for the beat family
## @param direction: Authored follow-through guidance for the beat family
signal trail_right(placement: StringName, direction: StringName)

# ============================================================================
# SIGNALS: MOVEMENT / STATE INTENTS
# ============================================================================

## Emitted when the player begins a squat.
signal squat_start

## Emitted when the player ends a squat.
signal squat_end

## Emitted when the player begins leaning left.
signal lean_left_start

## Emitted when the player stops leaning left.
signal lean_left_end

## Emitted when the player begins leaning right.
signal lean_right_start

## Emitted when the player stops leaning right.
signal lean_right_end

## Emitted when the player begins a left sidestep.
signal sidestep_left_start

## Emitted when the player completes or exits a left sidestep.
signal sidestep_left_end

## Emitted when the player begins a right sidestep.
signal sidestep_right_start

## Emitted when the player completes or exits a right sidestep.
signal sidestep_right_end

# ============================================================================
# CAPABILITY CHECK
# ============================================================================

## Override to report optional flow gesture support.
## Unsupported optional capabilities default to false until a concrete provider
## advertises them explicitly.
func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION:
			return true
		_:
			return false
