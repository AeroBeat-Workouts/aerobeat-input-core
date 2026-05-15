class_name AeroUiInteractable
extends Node
## Stateful composition helper for reusable UI nodes.
##
## This helper stays opt-in and bus-driven. It does not impose inheritance on a
## screen or panel hierarchy.

signal interaction_event(event: AeroUiInteractionEvent)
signal hovered_changed(is_hovered: bool, event: AeroUiInteractionEvent)
signal pressed_changed(is_pressed: bool, event: AeroUiInteractionEvent)
signal dragging_changed(is_dragging: bool, event: AeroUiInteractionEvent)
signal tapped(event: AeroUiInteractionEvent)
signal canceled(event: AeroUiInteractionEvent)

@export var bus_path: NodePath
@export var surface_id_filter: StringName = &""
@export var target_path_filter: NodePath
@export var pointer_id_filter: StringName = &""

var is_hovered: bool = false
var is_pressed: bool = false
var is_dragging: bool = false
var last_event: AeroUiInteractionEvent = null

func _ready() -> void:
	var bus := get_interaction_bus()
	if bus != null and not bus.interaction_event.is_connected(_on_bus_interaction_event):
		bus.interaction_event.connect(_on_bus_interaction_event)

func _exit_tree() -> void:
	var bus := get_interaction_bus()
	if bus != null and bus.interaction_event.is_connected(_on_bus_interaction_event):
		bus.interaction_event.disconnect(_on_bus_interaction_event)

func get_interaction_bus() -> AeroUiInteractionBus:
	if bus_path == NodePath():
		return null
	return get_node_or_null(bus_path) as AeroUiInteractionBus

func _on_bus_interaction_event(event: AeroUiInteractionEvent) -> void:
	if not _matches_filters(event):
		return

	last_event = event
	interaction_event.emit(event)

	match event.phase:
		AeroUiInteractionTypes.PHASE_HOVER_ENTER:
			_set_hovered(true, event)
		AeroUiInteractionTypes.PHASE_HOVER_EXIT:
			_set_hovered(false, event)
		AeroUiInteractionTypes.PHASE_PRESS_BEGIN:
			_set_pressed(true, event)
			_set_dragging(false, event)
		AeroUiInteractionTypes.PHASE_DRAG_BEGIN:
			_set_pressed(true, event)
			_set_dragging(true, event)
		AeroUiInteractionTypes.PHASE_DRAG_END:
			_set_dragging(false, event)
		AeroUiInteractionTypes.PHASE_PRESS_END:
			var was_dragging := is_dragging
			_set_pressed(false, event)
			_set_dragging(false, event)
			if not was_dragging:
				tapped.emit(event)
		AeroUiInteractionTypes.PHASE_CANCEL:
			_set_hovered(false, event)
			_set_pressed(false, event)
			_set_dragging(false, event)
			canceled.emit(event)
		_:
			pass

func _set_hovered(value: bool, event: AeroUiInteractionEvent) -> void:
	if is_hovered == value:
		return
	is_hovered = value
	hovered_changed.emit(is_hovered, event)

func _set_pressed(value: bool, event: AeroUiInteractionEvent) -> void:
	if is_pressed == value:
		return
	is_pressed = value
	pressed_changed.emit(is_pressed, event)

func _set_dragging(value: bool, event: AeroUiInteractionEvent) -> void:
	if is_dragging == value:
		return
	is_dragging = value
	dragging_changed.emit(is_dragging, event)

func _matches_filters(event: AeroUiInteractionEvent) -> bool:
	if surface_id_filter != StringName() and event.surface_id != surface_id_filter:
		return false
	if target_path_filter != NodePath() and event.target_path != target_path_filter:
		return false
	if pointer_id_filter != StringName() and event.pointer_id != pointer_id_filter:
		return false
	return true
