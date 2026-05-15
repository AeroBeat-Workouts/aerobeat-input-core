class_name AeroUiInteractionBus
extends Node
## Shared dispatcher for normalized AeroBeat UI interaction events.
##
## This node can be instantiated directly or installed as an autoload by a host
## project. Adapters publish normalized events here; downstream consumers depend
## on the bus instead of raw Godot input classes.

signal interaction_event(event: AeroUiInteractionEvent)
signal interaction_for_surface(surface_id: StringName, event: AeroUiInteractionEvent)
signal interaction_for_target(target_path: NodePath, event: AeroUiInteractionEvent)

var _surface_metadata: Dictionary = {}
var _source_verification_overrides: Dictionary = {}

func _init() -> void:
	_seed_default_verification_overrides()

func publish(event_data: Variant) -> AeroUiInteractionEvent:
	var event := _coerce_event(event_data)
	_apply_verification_defaults(event)
	interaction_event.emit(event)
	interaction_for_surface.emit(event.surface_id, event)
	if event.target_path != NodePath():
		interaction_for_target.emit(event.target_path, event)
	return event

func register_surface(surface_id: StringName, metadata: Dictionary = {}) -> void:
	_surface_metadata[surface_id] = metadata.duplicate(true)

func unregister_surface(surface_id: StringName) -> void:
	_surface_metadata.erase(surface_id)

func get_surface_metadata(surface_id: StringName) -> Dictionary:
	return _surface_metadata.get(surface_id, {}).duplicate(true)

func set_source_verification(
	source_variant: StringName,
	surface_type: StringName,
	status: StringName,
	notes: String = ""
) -> void:
	_source_verification_overrides[_verification_key(source_variant, surface_type)] = {
		"status": status,
		"notes": notes
	}

func get_source_verification(source_variant: StringName, surface_type: StringName) -> Dictionary:
	return _source_verification_overrides.get(
		_verification_key(source_variant, surface_type),
		{}
	).duplicate(true)

func _coerce_event(event_data: Variant) -> AeroUiInteractionEvent:
	if event_data is AeroUiInteractionEvent:
		return event_data
	if event_data is Dictionary:
		return AeroUiInteractionEvent.create(event_data)

	push_error("AeroUiInteractionBus: publish() expects AeroUiInteractionEvent or Dictionary")
	return AeroUiInteractionEvent.create()

func _apply_verification_defaults(event: AeroUiInteractionEvent) -> void:
	if event.verification_status != StringName():
		return
	var verification: Dictionary = get_source_verification(event.source_variant, event.surface_type)
	if verification.is_empty():
		event.verification_status = AeroUiVerificationStatus.UNVERIFIED
		event.verification_notes = "No explicit verification mapping registered for this adapter path."
		return
	event.verification_status = StringName(verification.get("status", AeroUiVerificationStatus.UNVERIFIED))
	event.verification_notes = String(verification.get("notes", ""))

func _verification_key(source_variant: StringName, surface_type: StringName) -> StringName:
	return StringName("%s::%s" % [source_variant, surface_type])

func _seed_default_verification_overrides() -> void:
	if not _source_verification_overrides.is_empty():
		return
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D,
		AeroUiVerificationStatus.PROTOTYPE,
		"Desktop mouse path is implemented in core, but still needs repo/scene QA confirmation."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_MOUSE,
		AeroUiInteractionTypes.SURFACE_TYPE_HYBRID_3D_GUI,
		AeroUiVerificationStatus.PROTOTYPE,
		"Hybrid 3D GUI mouse path is scaffolded for downstream adapters but not fully proven."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		AeroUiInteractionTypes.SURFACE_TYPE_SCREEN_2D,
		AeroUiVerificationStatus.UNVERIFIED,
		"Touch is represented in the contract, but this path is not yet validated in a real touch environment."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_SCREEN_TOUCH,
		AeroUiInteractionTypes.SURFACE_TYPE_HYBRID_3D_GUI,
		AeroUiVerificationStatus.UNVERIFIED,
		"Hybrid touch exists in the contract, but is intentionally unverified until live testing."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_XR_RAY,
		AeroUiInteractionTypes.SURFACE_TYPE_WORLD_3D,
		AeroUiVerificationStatus.UNVERIFIED,
		"XR ray interaction scaffolding is future-ready but not yet validated."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_XR_RAY,
		AeroUiInteractionTypes.SURFACE_TYPE_HYBRID_3D_GUI,
		AeroUiVerificationStatus.UNVERIFIED,
		"XR ray interaction against hybrid UI is represented now, but not yet tested."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_XR_DIRECT,
		AeroUiInteractionTypes.SURFACE_TYPE_WORLD_3D,
		AeroUiVerificationStatus.UNVERIFIED,
		"XR direct interaction is represented now, but not yet tested."
	)
	set_source_verification(
		AeroUiInteractionTypes.SOURCE_VARIANT_XR_DIRECT,
		AeroUiInteractionTypes.SURFACE_TYPE_HYBRID_3D_GUI,
		AeroUiVerificationStatus.UNVERIFIED,
		"XR direct interaction against hybrid UI is represented now, but not yet tested."
	)
