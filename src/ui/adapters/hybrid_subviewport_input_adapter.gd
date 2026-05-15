class_name HybridSubViewportInputAdapter
extends Node
## Minimal scaffolding for hybrid/world-presented UI backed by a SubViewport.
##
## This adapter does not claim to solve all 3D hit-testing itself. Instead it
## provides a stable normalization boundary so downstream repos can feed in
## projected hit data without coupling directly to raw Godot input everywhere.

@export var bus_path: NodePath
@export var surface_id: StringName = &"hybrid_ui"
@export var surface_type: StringName = AeroUiInteractionTypes.SURFACE_TYPE_HYBRID_3D_GUI
@export var surface_pixel_size: Vector2 = Vector2(1024.0, 1024.0)
@export var drag_threshold_pixels: float = 12.0

var _pointer_states: Dictionary = {}

func _ready() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.register_surface(surface_id, {
			"surface_type": surface_type,
			"surface_pixel_size": surface_pixel_size
		})

func _exit_tree() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.unregister_surface(surface_id)

func get_interaction_bus() -> AeroUiInteractionBus:
	if bus_path == NodePath():
		return null
	return get_node_or_null(bus_path) as AeroUiInteractionBus

func publish_from_input_event(
	event: InputEvent,
	projected_data: Dictionary = {},
	overrides: Dictionary = {}
) -> bool:
	if event is InputEventMouseButton:
		return _publish_pointer_button_event(event, projected_data, overrides)
	if event is InputEventMouseMotion:
		return _publish_pointer_motion_event(event, projected_data, overrides)
	if event is InputEventScreenTouch:
		return _publish_pointer_touch_event(event, projected_data, overrides)
	if event is InputEventScreenDrag:
		return _publish_pointer_touch_drag_event(event, projected_data, overrides)
	return false

func publish_projected_phase(
	phase: StringName,
	pointer_id: StringName,
	projected_data: Dictionary = {},
	overrides: Dictionary = {}
) -> AeroUiInteractionEvent:
	var state := _ensure_pointer_state(pointer_id)
	var event_data := _compose_base_event_data(pointer_id, phase, projected_data, overrides)
	event_data["pressed"] = bool(overrides.get("pressed", state.get("pressed", false)))
	if phase == AeroUiInteractionTypes.PHASE_PRESS_BEGIN:
		state["pressed"] = true
		state["dragging"] = false
		state["press_surface_position"] = event_data["surface_position"]
	elif phase == AeroUiInteractionTypes.PHASE_DRAG_BEGIN:
		state["dragging"] = true
		event_data["pressed"] = true
	elif phase == AeroUiInteractionTypes.PHASE_DRAG_END:
		state["dragging"] = false
		event_data["pressed"] = false
	elif phase == AeroUiInteractionTypes.PHASE_PRESS_END or phase == AeroUiInteractionTypes.PHASE_CANCEL:
		state["pressed"] = false
		state["dragging"] = false
		event_data["pressed"] = false
	return _publish_event(event_data)

func _publish_pointer_button_event(
	event: InputEventMouseButton,
	projected_data: Dictionary,
	overrides: Dictionary
) -> bool:
	var pointer_id := StringName(String(overrides.get("pointer_id", "mouse_0")))
	var state := _ensure_pointer_state(pointer_id)
	var phase: StringName = AeroUiInteractionTypes.PHASE_PRESS_BEGIN if event.pressed else AeroUiInteractionTypes.PHASE_PRESS_END
	if not event.pressed and bool(state.get("dragging", false)):
		publish_projected_phase(AeroUiInteractionTypes.PHASE_DRAG_END, pointer_id, projected_data, overrides)
	state["pressed"] = event.pressed
	state["dragging"] = false if not event.pressed else bool(state.get("dragging", false))
	publish_projected_phase(phase, pointer_id, projected_data, {
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"button": AeroUiInteractionTypes.normalize_mouse_button(event.button_index),
		"primary": event.button_index == MOUSE_BUTTON_LEFT,
		"click_count": 2 if event.double_click else 1,
		"raw_event_class": &"InputEventMouseButton",
		"raw_metadata": {"button_index": event.button_index}
	}.merged(overrides, true))
	return true

func _publish_pointer_motion_event(
	event: InputEventMouseMotion,
	projected_data: Dictionary,
	overrides: Dictionary
) -> bool:
	var pointer_id := StringName(String(overrides.get("pointer_id", "mouse_0")))
	var state := _ensure_pointer_state(pointer_id)
	var phase := AeroUiInteractionTypes.PHASE_HOVER_MOVE
	if bool(state.get("pressed", false)):
		var drag_distance := Vector2(projected_data.get("surface_position", Vector2.ZERO)).distance_to(
			state.get("press_surface_position", Vector2.ZERO)
		)
		if bool(state.get("dragging", false)):
			phase = AeroUiInteractionTypes.PHASE_DRAG_MOVE
		elif drag_distance >= drag_threshold_pixels:
			state["dragging"] = true
			phase = AeroUiInteractionTypes.PHASE_DRAG_BEGIN
		else:
			phase = AeroUiInteractionTypes.PHASE_PRESS_HOLD
	publish_projected_phase(phase, pointer_id, projected_data, {
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"button": StringName(state.get("button", AeroUiInteractionTypes.BUTTON_PRIMARY)),
		"pressed": bool(state.get("pressed", false)),
		"delta": event.relative,
		"velocity": event.relative,
		"raw_event_class": &"InputEventMouseMotion"
	}.merged(overrides, true))
	return true

func _publish_pointer_touch_event(
	event: InputEventScreenTouch,
	projected_data: Dictionary,
	overrides: Dictionary
) -> bool:
	var pointer_id := StringName(String(overrides.get("pointer_id", "touch_%s" % event.index)))
	var state := _ensure_pointer_state(pointer_id)
	var phase: StringName = AeroUiInteractionTypes.PHASE_PRESS_BEGIN if event.pressed else AeroUiInteractionTypes.PHASE_PRESS_END
	if not event.pressed and bool(state.get("dragging", false)):
		publish_projected_phase(AeroUiInteractionTypes.PHASE_DRAG_END, pointer_id, projected_data, overrides)
	state["pressed"] = event.pressed
	state["dragging"] = false if not event.pressed else bool(state.get("dragging", false))
	publish_projected_phase(phase, pointer_id, projected_data, {
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		"button": AeroUiInteractionTypes.BUTTON_CONTACT,
		"primary": event.index == 0,
		"pressure": 1.0,
		"raw_event_class": &"InputEventScreenTouch",
		"raw_metadata": {"index": event.index}
	}.merged(overrides, true))
	return true

func _publish_pointer_touch_drag_event(
	event: InputEventScreenDrag,
	projected_data: Dictionary,
	overrides: Dictionary
) -> bool:
	var pointer_id := StringName(String(overrides.get("pointer_id", "touch_%s" % event.index)))
	var state := _ensure_pointer_state(pointer_id)
	var phase := AeroUiInteractionTypes.PHASE_PRESS_HOLD
	var drag_distance := Vector2(projected_data.get("surface_position", Vector2.ZERO)).distance_to(
		state.get("press_surface_position", Vector2.ZERO)
	)
	if bool(state.get("dragging", false)):
		phase = AeroUiInteractionTypes.PHASE_DRAG_MOVE
	elif drag_distance >= drag_threshold_pixels:
		state["dragging"] = true
		phase = AeroUiInteractionTypes.PHASE_DRAG_BEGIN
	publish_projected_phase(phase, pointer_id, projected_data, {
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		"button": AeroUiInteractionTypes.BUTTON_CONTACT,
		"primary": event.index == 0,
		"pressed": true,
		"pressure": maxf(event.pressure, 1.0),
		"delta": event.relative,
		"velocity": event.velocity,
		"raw_event_class": &"InputEventScreenDrag",
		"raw_metadata": {"index": event.index}
	}.merged(overrides, true))
	return true

func _compose_base_event_data(
	pointer_id: StringName,
	phase: StringName,
	projected_data: Dictionary,
	overrides: Dictionary
) -> Dictionary:
	var source_variant: StringName = StringName(overrides.get(
		"source_variant",
		AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE
	))
	var source_type: StringName = StringName(overrides.get(
		"source_type",
		AeroUiInteractionTypes.SOURCE_TYPE_MOUSE
	))
	var surface_normalized_position: Vector2 = projected_data.get("surface_normalized_position", Vector2.ZERO)
	var resolved_surface_position: Vector2 = projected_data.get(
		"surface_position",
		Vector2(
			surface_normalized_position.x * surface_pixel_size.x,
			surface_normalized_position.y * surface_pixel_size.y
		)
	)
	var resolved_target_path: NodePath = projected_data.get("target_path", NodePath())
	var state := _ensure_pointer_state(pointer_id)
	state["button"] = StringName(overrides.get("button", state.get("button", AeroUiInteractionTypes.BUTTON_PRIMARY)))
	if phase == AeroUiInteractionTypes.PHASE_PRESS_BEGIN:
		state["press_surface_position"] = resolved_surface_position
	return {
		"pointer_id": pointer_id,
		"source_type": source_type,
		"source_variant": source_variant,
		"surface_type": StringName(overrides.get("surface_type", surface_type)),
		"surface_id": StringName(overrides.get("surface_id", surface_id)),
		"phase": phase,
		"target_path": resolved_target_path,
		"screen_position": projected_data.get("screen_position", Vector2.ZERO),
		"surface_position": resolved_surface_position,
		"surface_normalized_position": surface_normalized_position,
		"world_position": projected_data.get("world_position", Vector3.ZERO),
		"world_normal": projected_data.get("world_normal", Vector3.ZERO),
		"world_direction": projected_data.get("world_direction", Vector3.ZERO),
		"primary": bool(overrides.get("primary", true)),
		"pressed": bool(overrides.get("pressed", bool(state.get("pressed", false)))),
		"button": StringName(overrides.get("button", state.get("button", AeroUiInteractionTypes.BUTTON_PRIMARY))),
		"contact_count": int(overrides.get("contact_count", 1 if bool(overrides.get("pressed", bool(state.get("pressed", false)))) else 0)),
		"pressure": float(overrides.get("pressure", 1.0 if bool(overrides.get("pressed", bool(state.get("pressed", false)))) else 0.0)),
		"delta": projected_data.get("delta", overrides.get("delta", Vector2.ZERO)),
		"world_delta": projected_data.get("world_delta", Vector3.ZERO),
		"velocity": projected_data.get("velocity", overrides.get("velocity", Vector2.ZERO)),
		"click_count": int(overrides.get("click_count", 0)),
		"modifiers": PackedStringArray(overrides.get("modifiers", PackedStringArray())),
		"is_synthetic": bool(overrides.get("is_synthetic", false)),
		"verification_status": StringName(overrides.get("verification_status", StringName())),
		"verification_notes": String(overrides.get("verification_notes", projected_data.get("verification_notes", ""))),
		"raw_event_class": StringName(overrides.get("raw_event_class", projected_data.get("raw_event_class", &""))),
		"raw_metadata": _compose_raw_metadata(projected_data, overrides)
	}

func _compose_raw_metadata(projected_data: Dictionary, overrides: Dictionary) -> Dictionary:
	var raw_metadata: Dictionary = projected_data.get("raw_metadata", {}).duplicate(true)
	for key in overrides.get("raw_metadata", {}).keys():
		raw_metadata[key] = overrides["raw_metadata"][key]
	return raw_metadata

func _publish_event(event_data: Dictionary) -> AeroUiInteractionEvent:
	var bus := get_interaction_bus()
	if bus == null:
		return AeroUiInteractionEvent.create(event_data)
	return bus.publish(event_data)

func _ensure_pointer_state(pointer_id: StringName) -> Dictionary:
	if not _pointer_states.has(pointer_id):
		_pointer_states[pointer_id] = {
			"pressed": false,
			"dragging": false,
			"button": AeroUiInteractionTypes.BUTTON_PRIMARY,
			"press_surface_position": Vector2.ZERO
		}
	return _pointer_states[pointer_id]
