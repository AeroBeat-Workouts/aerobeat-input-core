class_name AeroUiInteractionEvent
extends RefCounted
## Canonical normalized AeroBeat UI interaction payload.
##
## The shared contract intentionally exposes one canonical lifecycle field:
## `phase`. Do not add a second core `action` field here.

var event_id: StringName = &""
var pointer_id: StringName = &""
var source_type: StringName = AeroUiInteractionTypes.SOURCE_TYPE_UNKNOWN
var source_variant: StringName = AeroUiInteractionTypes.SOURCE_VARIANT_UNKNOWN
var surface_type: StringName = AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D
var surface_id: StringName = &""
var phase: StringName = AeroUiInteractionTypes.PHASE_HOVER_MOVE
var target_path: NodePath = NodePath()
var timestamp_usec: int = 0

var screen_position: Vector2 = Vector2.ZERO
var surface_position: Vector2 = Vector2.ZERO
var surface_normalized_position: Vector2 = Vector2.ZERO
var world_position: Vector3 = Vector3.ZERO
var world_normal: Vector3 = Vector3.ZERO
var world_direction: Vector3 = Vector3.ZERO

var primary: bool = true
var pressed: bool = false
var button: StringName = AeroUiInteractionTypes.BUTTON_UNKNOWN
var contact_count: int = 0
var pressure: float = 0.0

var delta: Vector2 = Vector2.ZERO
var world_delta: Vector3 = Vector3.ZERO
var velocity: Vector2 = Vector2.ZERO

var click_count: int = 0
var modifiers: PackedStringArray = PackedStringArray()

var is_synthetic: bool = false
var verification_status: StringName = StringName()
var verification_notes: String = ""

var raw_event_class: StringName = &""
var raw_metadata: Dictionary = {}

static func create(data: Dictionary = {}) -> AeroUiInteractionEvent:
	var event := AeroUiInteractionEvent.new()
	event.apply(data)
	if event.event_id == StringName():
		event.event_id = StringName("ui_%s" % Time.get_ticks_usec())
	if event.timestamp_usec == 0:
		event.timestamp_usec = Time.get_ticks_usec()
	return event

func apply(data: Dictionary) -> AeroUiInteractionEvent:
	for key in data.keys():
		if key == &"action":
			continue
		if key == &"event_id":
			event_id = StringName(data[key])
		elif key == &"pointer_id":
			pointer_id = StringName(data[key])
		elif key == &"source_type":
			source_type = StringName(data[key])
		elif key == &"source_variant":
			source_variant = StringName(data[key])
		elif key == &"surface_type":
			surface_type = StringName(data[key])
		elif key == &"surface_id":
			surface_id = StringName(data[key])
		elif key == &"phase":
			phase = StringName(data[key])
		elif key == &"target_path":
			target_path = data[key] as NodePath
		elif key == &"timestamp_usec":
			timestamp_usec = int(data[key])
		elif key == &"screen_position":
			screen_position = data[key] as Vector2
		elif key == &"surface_position":
			surface_position = data[key] as Vector2
		elif key == &"surface_normalized_position":
			surface_normalized_position = data[key] as Vector2
		elif key == &"world_position":
			world_position = data[key] as Vector3
		elif key == &"world_normal":
			world_normal = data[key] as Vector3
		elif key == &"world_direction":
			world_direction = data[key] as Vector3
		elif key == &"primary":
			primary = bool(data[key])
		elif key == &"pressed":
			pressed = bool(data[key])
		elif key == &"button":
			button = StringName(data[key])
		elif key == &"contact_count":
			contact_count = int(data[key])
		elif key == &"pressure":
			pressure = float(data[key])
		elif key == &"delta":
			delta = data[key] as Vector2
		elif key == &"world_delta":
			world_delta = data[key] as Vector3
		elif key == &"velocity":
			velocity = data[key] as Vector2
		elif key == &"click_count":
			click_count = int(data[key])
		elif key == &"modifiers":
			modifiers = PackedStringArray(data[key])
		elif key == &"is_synthetic":
			is_synthetic = bool(data[key])
		elif key == &"verification_status":
			verification_status = StringName(data[key])
		elif key == &"verification_notes":
			verification_notes = String(data[key])
		elif key == &"raw_event_class":
			raw_event_class = StringName(data[key])
		elif key == &"raw_metadata":
			raw_metadata = data[key].duplicate(true)
	return self

func duplicate_event() -> AeroUiInteractionEvent:
	return AeroUiInteractionEvent.create(to_dictionary())

func to_dictionary() -> Dictionary:
	return {
		"event_id": event_id,
		"pointer_id": pointer_id,
		"source_type": source_type,
		"source_variant": source_variant,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": phase,
		"target_path": target_path,
		"timestamp_usec": timestamp_usec,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": surface_normalized_position,
		"world_position": world_position,
		"world_normal": world_normal,
		"world_direction": world_direction,
		"primary": primary,
		"pressed": pressed,
		"button": button,
		"contact_count": contact_count,
		"pressure": pressure,
		"delta": delta,
		"world_delta": world_delta,
		"velocity": velocity,
		"click_count": click_count,
		"modifiers": modifiers,
		"is_synthetic": is_synthetic,
		"verification_status": verification_status,
		"verification_notes": verification_notes,
		"raw_event_class": raw_event_class,
		"raw_metadata": raw_metadata.duplicate(true)
	}

func is_phase(test_phase: StringName) -> bool:
	return phase == test_phase
