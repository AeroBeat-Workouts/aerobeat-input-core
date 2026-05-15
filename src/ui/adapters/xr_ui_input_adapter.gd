class_name XrUiInputAdapter
extends Node
## Minimal future-ready XR interaction adapter scaffolding.
##
## This does not pretend to provide proven XR parity yet. It exists so
## downstream repos can depend on a stable contract today while real XR runtime
## integrations land later behind the same normalized event surface.

@export var bus_path: NodePath
@export var surface_id: StringName = &"xr_ui"
@export var surface_type: StringName = AeroUiInteractionTypes.SURFACE_TYPE_WORLD_3D
@export var default_source_variant: StringName = AeroUiInteractionTypes.SOURCE_VARIANT_XR_RAY

var _pointer_states: Dictionary = {}

func _ready() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.register_surface(surface_id, {"surface_type": surface_type})

func _exit_tree() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.unregister_surface(surface_id)

func get_interaction_bus() -> AeroUiInteractionBus:
	if bus_path == NodePath():
		return null
	return get_node_or_null(bus_path) as AeroUiInteractionBus

func publish_pointer_phase(
	pointer_id: StringName,
	phase: StringName,
	projected_data: Dictionary = {},
	overrides: Dictionary = {}
) -> AeroUiInteractionEvent:
	var state := _ensure_pointer_state(pointer_id)
	var event_data := {
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_XR,
		"source_variant": StringName(overrides.get("source_variant", default_source_variant)),
		"surface_type": StringName(overrides.get("surface_type", surface_type)),
		"surface_id": StringName(overrides.get("surface_id", surface_id)),
		"phase": phase,
		"target_path": projected_data.get("target_path", NodePath()),
		"screen_position": projected_data.get("screen_position", Vector2.ZERO),
		"surface_position": projected_data.get("surface_position", Vector2.ZERO),
		"surface_normalized_position": projected_data.get("surface_normalized_position", Vector2.ZERO),
		"world_position": projected_data.get("world_position", Vector3.ZERO),
		"world_normal": projected_data.get("world_normal", Vector3.ZERO),
		"world_direction": projected_data.get("world_direction", Vector3.ZERO),
		"primary": bool(overrides.get("primary", true)),
		"pressed": bool(overrides.get("pressed", bool(state.get("pressed", false)))),
		"button": StringName(overrides.get("button", AeroUiInteractionTypes.BUTTON_TRIGGER)),
		"contact_count": int(overrides.get("contact_count", 1 if bool(overrides.get("pressed", bool(state.get("pressed", false)))) else 0)),
		"pressure": float(overrides.get("pressure", 1.0 if bool(overrides.get("pressed", bool(state.get("pressed", false)))) else 0.0)),
		"delta": projected_data.get("delta", Vector2.ZERO),
		"world_delta": projected_data.get("world_delta", Vector3.ZERO),
		"velocity": projected_data.get("velocity", Vector2.ZERO),
		"click_count": int(overrides.get("click_count", 0)),
		"modifiers": PackedStringArray(overrides.get("modifiers", PackedStringArray())),
		"is_synthetic": bool(overrides.get("is_synthetic", false)),
		"verification_status": StringName(overrides.get("verification_status", AeroUiVerificationStatus.UNVERIFIED)),
		"verification_notes": String(overrides.get(
			"verification_notes",
			"XR interaction scaffolding exists in core but still needs live device validation."
		)),
		"raw_event_class": StringName(overrides.get("raw_event_class", projected_data.get("raw_event_class", &""))),
		"raw_metadata": _compose_raw_metadata(projected_data, overrides)
	}

	if phase == AeroUiInteractionTypes.PHASE_PRESS_BEGIN:
		state["pressed"] = true
		state["dragging"] = false
		event_data["pressed"] = true
	elif phase == AeroUiInteractionTypes.PHASE_DRAG_BEGIN:
		state["dragging"] = true
		state["pressed"] = true
		event_data["pressed"] = true
	elif phase == AeroUiInteractionTypes.PHASE_DRAG_END:
		state["dragging"] = false
		event_data["pressed"] = false
	elif phase == AeroUiInteractionTypes.PHASE_PRESS_END or phase == AeroUiInteractionTypes.PHASE_CANCEL:
		state["pressed"] = false
		state["dragging"] = false
		event_data["pressed"] = false

	var bus := get_interaction_bus()
	if bus == null:
		return AeroUiInteractionEvent.create(event_data)
	return bus.publish(event_data)

func _compose_raw_metadata(projected_data: Dictionary, overrides: Dictionary) -> Dictionary:
	var raw_metadata: Dictionary = projected_data.get("raw_metadata", {}).duplicate(true)
	for key in overrides.get("raw_metadata", {}).keys():
		raw_metadata[key] = overrides["raw_metadata"][key]
	return raw_metadata

func _ensure_pointer_state(pointer_id: StringName) -> Dictionary:
	if not _pointer_states.has(pointer_id):
		_pointer_states[pointer_id] = {
			"pressed": false,
			"dragging": false
		}
	return _pointer_states[pointer_id]
