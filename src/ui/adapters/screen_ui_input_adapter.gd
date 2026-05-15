class_name ScreenUiInputAdapter
extends Node
## Normalizes standard screen-space mouse/touch input into AeroUiInteractionEvent.
##
## This adapter is intentionally minimal v1 scaffolding: it publishes canonical
## pointer phases and surface metadata without forcing downstream UI scenes to
## parse raw InputEvent classes directly.

@export var bus_path: NodePath
@export var surface_id: StringName = &"screen_ui"
@export var surface_type: StringName = AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D
@export var drag_threshold_pixels: float = 12.0
@export var emit_hover_events: bool = true

var _pointer_states: Dictionary = {}
var _hover_pointer_id: StringName = &"mouse_0"

func _ready() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.register_surface(surface_id, {"surface_type": surface_type})

func _exit_tree() -> void:
	var bus := get_interaction_bus()
	if bus != null:
		bus.unregister_surface(surface_id)

func _input(event: InputEvent) -> void:
	publish_input_event(event)

func publish_input_event(
	event: InputEvent,
	target_path: NodePath = NodePath(),
	extra_metadata: Dictionary = {}
) -> bool:
	if event is InputEventMouseButton:
		return _publish_mouse_button_event(event, target_path, extra_metadata)
	if event is InputEventMouseMotion:
		return _publish_mouse_motion_event(event, target_path, extra_metadata)
	if event is InputEventScreenTouch:
		return _publish_touch_event(event, target_path, extra_metadata)
	if event is InputEventScreenDrag:
		return _publish_touch_drag_event(event, target_path, extra_metadata)
	return false

func get_interaction_bus() -> AeroUiInteractionBus:
	if bus_path == NodePath():
		return null
	return get_node_or_null(bus_path) as AeroUiInteractionBus

func _publish_mouse_button_event(
	event: InputEventMouseButton,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	if event.button_index != MOUSE_BUTTON_LEFT \
	and event.button_index != MOUSE_BUTTON_RIGHT \
	and event.button_index != MOUSE_BUTTON_MIDDLE:
		return false

	var pointer_id: StringName = _hover_pointer_id
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)
	var button := AeroUiInteractionTypes.normalize_mouse_button(event.button_index)
	var modifiers := _modifiers_for_event(event)

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	state["target_path"] = resolved_target_path
	state["source_type"] = AeroUiInteractionTypes.SOURCE_TYPE_MOUSE
	state["source_variant"] = AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE
	state["button"] = button

	if event.pressed:
		state["pressed"] = true
		state["dragging"] = false
		state["press_screen_position"] = screen_position
		state["press_surface_position"] = surface_position
		state["click_count"] = 2 if event.double_click else 1
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
			"target_path": resolved_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": button == AeroUiInteractionTypes.BUTTON_PRIMARY,
			"pressed": true,
			"button": button,
			"contact_count": 1,
			"pressure": 1.0,
			"click_count": state["click_count"],
			"modifiers": modifiers,
			"raw_event_class": &"InputEventMouseButton",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {"button_index": event.button_index})
		})
		return true

	if bool(state.get("dragging", false)):
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_DRAG_END,
			"target_path": resolved_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": button == AeroUiInteractionTypes.BUTTON_PRIMARY,
			"pressed": false,
			"button": button,
			"contact_count": 0,
			"pressure": 0.0,
			"modifiers": modifiers,
			"raw_event_class": &"InputEventMouseButton",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {"button_index": event.button_index})
		})

	state["pressed"] = false
	state["dragging"] = false
	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_END,
		"target_path": resolved_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": button == AeroUiInteractionTypes.BUTTON_PRIMARY,
		"pressed": false,
		"button": button,
		"contact_count": 0,
		"pressure": 0.0,
		"click_count": int(state.get("click_count", 0)),
		"modifiers": modifiers,
		"raw_event_class": &"InputEventMouseButton",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {"button_index": event.button_index})
	})
	return true

func _publish_mouse_motion_event(
	event: InputEventMouseMotion,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	var pointer_id: StringName = _hover_pointer_id
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)
	var delta: Vector2 = event.relative
	var is_pressed: bool = bool(state.get("pressed", false))
	var phase: StringName = AeroUiInteractionTypes.PHASE_HOVER_MOVE

	if is_pressed:
		var drag_distance := screen_position.distance_to(state.get("press_screen_position", screen_position))
		if bool(state.get("dragging", false)):
			phase = AeroUiInteractionTypes.PHASE_DRAG_MOVE
		elif drag_distance >= drag_threshold_pixels:
			state["dragging"] = true
			phase = AeroUiInteractionTypes.PHASE_DRAG_BEGIN
		else:
			phase = AeroUiInteractionTypes.PHASE_PRESS_HOLD
	elif emit_hover_events:
		var inside_surface := _is_inside_surface(surface_position)
		var was_hovering := bool(state.get("hovering", false))
		if inside_surface and not was_hovering:
			phase = AeroUiInteractionTypes.PHASE_HOVER_ENTER
			state["hovering"] = true
		elif inside_surface:
			phase = AeroUiInteractionTypes.PHASE_HOVER_MOVE
		elif was_hovering:
			phase = AeroUiInteractionTypes.PHASE_HOVER_EXIT
			state["hovering"] = false
		else:
			return false
	else:
		return false

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	state["target_path"] = resolved_target_path

	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_MOUSE,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": phase,
		"target_path": resolved_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": true,
		"pressed": is_pressed,
		"button": StringName(state.get("button", AeroUiInteractionTypes.BUTTON_PRIMARY)),
		"contact_count": 1 if is_pressed else 0,
		"pressure": 1.0 if is_pressed else 0.0,
		"delta": delta,
		"velocity": delta,
		"modifiers": _modifiers_for_event(event),
		"raw_event_class": &"InputEventMouseMotion",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {})
	})
	return true

func _publish_touch_event(
	event: InputEventScreenTouch,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	var pointer_id := StringName("touch_%s" % event.index)
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	state["press_screen_position"] = screen_position
	state["press_surface_position"] = surface_position
	state["target_path"] = resolved_target_path
	state["source_type"] = AeroUiInteractionTypes.SOURCE_TYPE_TOUCH
	state["source_variant"] = AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH
	state["button"] = AeroUiInteractionTypes.BUTTON_CONTACT

	if event.pressed:
		state["pressed"] = true
		state["dragging"] = false
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_PRESS_BEGIN,
			"target_path": resolved_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": event.index == 0,
			"pressed": true,
			"button": AeroUiInteractionTypes.BUTTON_CONTACT,
			"contact_count": 1,
			"pressure": 1.0,
			"raw_event_class": &"InputEventScreenTouch",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {"index": event.index})
		})
		return true

	if bool(state.get("dragging", false)):
		_publish_event({
			"pointer_id": pointer_id,
			"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
			"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
			"surface_type": surface_type,
			"surface_id": surface_id,
			"phase": AeroUiInteractionTypes.PHASE_DRAG_END,
			"target_path": resolved_target_path,
			"screen_position": screen_position,
			"surface_position": surface_position,
			"surface_normalized_position": normalized_surface_position,
			"primary": event.index == 0,
			"pressed": false,
			"button": AeroUiInteractionTypes.BUTTON_CONTACT,
			"contact_count": 0,
			"pressure": 0.0,
			"raw_event_class": &"InputEventScreenTouch",
			"raw_metadata": _merge_raw_metadata(extra_metadata, {"index": event.index})
		})

	state["pressed"] = false
	state["dragging"] = false
	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": AeroUiInteractionTypes.PHASE_PRESS_END,
		"target_path": resolved_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": event.index == 0,
		"pressed": false,
		"button": AeroUiInteractionTypes.BUTTON_CONTACT,
		"contact_count": 0,
		"pressure": 0.0,
		"raw_event_class": &"InputEventScreenTouch",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {"index": event.index})
	})
	return true

func _publish_touch_drag_event(
	event: InputEventScreenDrag,
	target_path: NodePath,
	extra_metadata: Dictionary
) -> bool:
	var pointer_id := StringName("touch_%s" % event.index)
	var state: Dictionary = _ensure_pointer_state(pointer_id)
	var resolved_target_path := _resolve_target_path(target_path)
	var screen_position: Vector2 = event.position
	var surface_position: Vector2 = _resolve_surface_position(screen_position)
	var normalized_surface_position: Vector2 = _resolve_surface_normalized_position(surface_position)
	var drag_distance := screen_position.distance_to(state.get("press_screen_position", screen_position))
	var phase: StringName = AeroUiInteractionTypes.PHASE_PRESS_HOLD

	if bool(state.get("dragging", false)):
		phase = AeroUiInteractionTypes.PHASE_DRAG_MOVE
	elif drag_distance >= drag_threshold_pixels:
		state["dragging"] = true
		phase = AeroUiInteractionTypes.PHASE_DRAG_BEGIN

	state["last_screen_position"] = screen_position
	state["last_surface_position"] = surface_position
	_publish_event({
		"pointer_id": pointer_id,
		"source_type": AeroUiInteractionTypes.SOURCE_TYPE_TOUCH,
		"source_variant": AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		"surface_type": surface_type,
		"surface_id": surface_id,
		"phase": phase,
		"target_path": resolved_target_path,
		"screen_position": screen_position,
		"surface_position": surface_position,
		"surface_normalized_position": normalized_surface_position,
		"primary": event.index == 0,
		"pressed": true,
		"button": AeroUiInteractionTypes.BUTTON_CONTACT,
		"contact_count": 1,
		"pressure": maxf(event.pressure, 1.0),
		"delta": event.relative,
		"velocity": event.velocity,
		"raw_event_class": &"InputEventScreenDrag",
		"raw_metadata": _merge_raw_metadata(extra_metadata, {"index": event.index})
	})
	return true

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
			"hovering": false,
			"click_count": 0,
			"button": AeroUiInteractionTypes.BUTTON_PRIMARY,
			"press_screen_position": Vector2.ZERO,
			"press_surface_position": Vector2.ZERO,
			"last_screen_position": Vector2.ZERO,
			"last_surface_position": Vector2.ZERO,
			"target_path": NodePath()
		}
	return _pointer_states[pointer_id]

func _resolve_target_path(explicit_target_path: NodePath) -> NodePath:
	if explicit_target_path != NodePath():
		return explicit_target_path
	var viewport := get_viewport()
	if viewport != null:
		var hovered := viewport.gui_get_hovered_control()
		if hovered != null:
			return hovered.get_path()
	return NodePath()

func _resolve_surface_control() -> Control:
	if get_parent() is Control:
		return get_parent() as Control
	return null

func _resolve_surface_position(screen_position: Vector2) -> Vector2:
	var control := _resolve_surface_control()
	if control == null:
		return screen_position
	return control.get_global_transform_with_canvas().affine_inverse() * screen_position

func _resolve_surface_normalized_position(surface_position: Vector2) -> Vector2:
	var control := _resolve_surface_control()
	if control == null:
		return surface_position
	if is_zero_approx(control.size.x) or is_zero_approx(control.size.y):
		return Vector2.ZERO
	return Vector2(
		clampf(surface_position.x / control.size.x, 0.0, 1.0),
		clampf(surface_position.y / control.size.y, 0.0, 1.0)
	)

func _is_inside_surface(surface_position: Vector2) -> bool:
	var control := _resolve_surface_control()
	if control == null:
		return true
	return Rect2(Vector2.ZERO, control.size).has_point(surface_position)

func _modifiers_for_event(event: InputEventWithModifiers) -> PackedStringArray:
	var modifiers := PackedStringArray()
	if event.alt_pressed:
		modifiers.append("alt")
	if event.ctrl_pressed:
		modifiers.append("ctrl")
	if event.meta_pressed:
		modifiers.append("meta")
	if event.shift_pressed:
		modifiers.append("shift")
	return modifiers

func _merge_raw_metadata(extra_metadata: Dictionary, event_metadata: Dictionary) -> Dictionary:
	var merged := extra_metadata.duplicate(true)
	for key in event_metadata.keys():
		merged[key] = event_metadata[key]
	return merged
