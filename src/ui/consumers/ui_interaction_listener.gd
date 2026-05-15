class_name AeroUiInteractionListener
extends Node
## Small composition helper that subscribes to AeroUiInteractionBus and re-emits
## filtered local signals.
##
## Ergonomic sugar like `tapped` lives here instead of in the core event payload.

signal interaction_event(event: AeroUiInteractionEvent)
signal hover_entered(event: AeroUiInteractionEvent)
signal hover_moved(event: AeroUiInteractionEvent)
signal hover_exited(event: AeroUiInteractionEvent)
signal press_began(event: AeroUiInteractionEvent)
signal press_held(event: AeroUiInteractionEvent)
signal press_ended(event: AeroUiInteractionEvent)
signal drag_began(event: AeroUiInteractionEvent)
signal drag_moved(event: AeroUiInteractionEvent)
signal drag_ended(event: AeroUiInteractionEvent)
signal canceled(event: AeroUiInteractionEvent)
signal tapped(event: AeroUiInteractionEvent)

@export var bus_path: NodePath
@export var surface_id_filter: StringName = &""
@export var target_path_filter: NodePath
@export var pointer_id_filter: StringName = &""

var _pointer_phase_state: Dictionary = {}

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

	interaction_event.emit(event)
	var pointer_id: StringName = event.pointer_id
	var pointer_state: Dictionary = _pointer_phase_state.get(pointer_id, {"did_drag": false})

	match event.phase:
		AeroUiInteractionTypes.PHASE_HOVER_ENTER:
			hover_entered.emit(event)
		AeroUiInteractionTypes.PHASE_HOVER_MOVE:
			hover_moved.emit(event)
		AeroUiInteractionTypes.PHASE_HOVER_EXIT:
			hover_exited.emit(event)
		AeroUiInteractionTypes.PHASE_PRESS_BEGIN:
			pointer_state = {"did_drag": false}
			press_began.emit(event)
		AeroUiInteractionTypes.PHASE_PRESS_HOLD:
			press_held.emit(event)
		AeroUiInteractionTypes.PHASE_DRAG_BEGIN:
			pointer_state["did_drag"] = true
			drag_began.emit(event)
		AeroUiInteractionTypes.PHASE_DRAG_MOVE:
			pointer_state["did_drag"] = true
			drag_moved.emit(event)
		AeroUiInteractionTypes.PHASE_DRAG_END:
			pointer_state["did_drag"] = true
			drag_ended.emit(event)
		AeroUiInteractionTypes.PHASE_PRESS_END:
			press_ended.emit(event)
			if not bool(pointer_state.get("did_drag", false)):
				tapped.emit(event)
			_pointer_phase_state.erase(pointer_id)
		AeroUiInteractionTypes.PHASE_CANCEL:
			canceled.emit(event)
			_pointer_phase_state.erase(pointer_id)
		_:
			pass

	if event.phase != AeroUiInteractionTypes.PHASE_PRESS_END \
	and event.phase != AeroUiInteractionTypes.PHASE_CANCEL:
		_pointer_phase_state[pointer_id] = pointer_state

func _matches_filters(event: AeroUiInteractionEvent) -> bool:
	if surface_id_filter != StringName() and event.surface_id != surface_id_filter:
		return false
	if target_path_filter != NodePath() and event.target_path != target_path_filter:
		return false
	if pointer_id_filter != StringName() and event.pointer_id != pointer_id_filter:
		return false
	return true
