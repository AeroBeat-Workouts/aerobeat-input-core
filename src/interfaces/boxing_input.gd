class_name BoxingInput
extends AeroInputProvider
## Interface for AeroBeat Boxing gameplay input providers.
##
## Boxing is an active camera-first gameplay mode in v1. This contract defines
## the gameplay-facing intent events detectors should emit into.
##
## Important v1 rules:
## - straight punches are punch_left / punch_right
## - guard is the canonical defensive wording
## - authored chart semantics like orthodox / southpaw are not tracked input events
## - run_in_place is not part of the first implementation pass
## - state-like movement intents use start/end style signals
##
## Raw pose, observation streams, and richer provider-specific body data remain
## optional and provider-side. They do not replace this gameplay intent surface.

# ============================================================================
# SIGNALS: OFFENSIVE INTENTS
# ============================================================================

## Emitted when a left straight punch intent is detected.
## @param power: Punch power from 0.0 to 1.0
signal punch_left(power: float)

## Emitted when a right straight punch intent is detected.
## @param power: Punch power from 0.0 to 1.0
signal punch_right(power: float)

## Emitted when a left uppercut intent is detected.
## @param power: Uppercut power from 0.0 to 1.0
signal uppercut_left(power: float)

## Emitted when a right uppercut intent is detected.
## @param power: Uppercut power from 0.0 to 1.0
signal uppercut_right(power: float)

## Emitted when a left hook intent is detected.
## @param power: Hook power from 0.0 to 1.0
signal hook_left(power: float)

## Emitted when a right hook intent is detected.
## @param power: Hook power from 0.0 to 1.0
signal hook_right(power: float)

# ============================================================================
# SIGNALS: DEFENSIVE / STATE INTENTS
# ============================================================================

## Emitted when the player enters guard.
signal guard_start

## Emitted when the player exits guard.
signal guard_end

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
# SIGNALS: OPTIONAL / FUTURE-FACING LOWER-BODY EXTENSIONS
# ============================================================================

## Emitted when a left knee strike is detected by a provider with lower-body support.
## @param power: Strike power from 0.0 to 1.0
signal knee_strike_left(power: float)

## Emitted when a right knee strike is detected by a provider with lower-body support.
## @param power: Strike power from 0.0 to 1.0
signal knee_strike_right(power: float)

## Emitted when the player begins lifting the left leg.
signal leg_lift_left_start

## Emitted when the player stops lifting the left leg.
signal leg_lift_left_end

## Emitted when the player begins lifting the right leg.
signal leg_lift_right_start

## Emitted when the player stops lifting the right leg.
signal leg_lift_right_end

# ============================================================================
# CAPABILITY CHECK
# ============================================================================

## Override to report optional boxing capabilities.
## Gesture recognition remains the expected gameplay-facing surface for boxing,
## while lower-body and other richer hooks stay false until a concrete provider
## explicitly advertises them.
func has_capability(capability: Capability) -> bool:
	match capability:
		Capability.GESTURE_RECOGNITION:
			return true
		_:
			return false
