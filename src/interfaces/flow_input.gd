class_name FlowInput
extends AeroInputProvider
## Interface for AeroBeat Flow gameplay input providers.
##
## Flow remains a camera-first AeroBeat gameplay mode in v1. This contract keeps
## the signal shape useful for future providers, but its default framing should be
## read through camera-based motion interpretation first, not controller-first or
## sword-sim parity.
##
## Providers should emit the signals they can confidently infer from tracked body
## motion. Future non-camera implementations may reuse the same contract.

# ============================================================================
# SIGNALS: FLOW GESTURE DETECTION
# ============================================================================

## Emitted when a directional flow slice gesture is detected.
## @param direction: Slice direction - "left", "right", "up", or "down"
## @param angle: Estimated hand/arm motion angle in degrees
signal slice_detected(direction: StringName, angle: float)

# ============================================================================
# SIGNALS: STANCE & POSITION (Shared with Boxing)
# ============================================================================

## Emitted when player assumes standard stance (left side forward).
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
