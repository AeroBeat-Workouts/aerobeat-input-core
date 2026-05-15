class_name AeroUiVerificationStatus
extends RefCounted
## Truthful verification-status labels for normalized AeroBeat UI interaction paths.
##
## These values describe confidence in the adapter/runtime path itself, not in a
## downstream consumer widget.

const VERIFIED: StringName = &"verified"
const PROTOTYPE: StringName = &"prototype"
const UNVERIFIED: StringName = &"unverified"
const UNSUPPORTED: StringName = &"unsupported"

const ALL: Array[StringName] = [
	VERIFIED,
	PROTOTYPE,
	UNVERIFIED,
	UNSUPPORTED
]

static func is_valid(value: StringName) -> bool:
	return ALL.has(value)
