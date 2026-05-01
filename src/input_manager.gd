class_name InputManager
extends Node
## Central coordinator for AeroBeat input providers.
##
## This manager preserves a future-friendly provider abstraction layer while
## making the current product truth explicit: camera providers are the official
## AeroBeat v1 gameplay default path.
##
## Non-camera providers can still be registered for experimentation, tooling,
## accessibility exploration, or future product slices, but they should not read
## as equal-status official gameplay peers today. Mouse and touch remain useful
## for menu/navigation surfaces and other deprioritized future input paths.

# ============================================================================
# CONFIGURATION
# ============================================================================

## If true, automatically switch to the highest-priority available provider.
## The default priority order is intentionally camera-first for v1 gameplay.
@export var auto_switch_inputs: bool = true

## Priority order for input providers (highest priority first).
## Camera providers are the official gameplay-default path for v1.
## Non-camera providers remain registered/future-friendly, but are deprioritized
## so the runtime policy does not imply broad current gameplay parity.
@export var input_priority: Array[String] = [
	"mediapipe_python",     # Preferred v1 desktop camera gameplay path
	"mediapipe_native",     # Preferred v1 mobile/native camera gameplay path
	"xr_6dof",              # Future / experimental richer provider path
	"joycon_hid",           # Future / experimental non-camera gameplay path
	"gamepad",              # Future / experimental non-camera gameplay path
	"mouse",                # Supported for menu/navigation; not official v1 gameplay parity
	"keyboard"              # Future / fallback input path; not official v1 gameplay parity
]

# ============================================================================
# SIGNALS: PROVIDER MANAGEMENT
# ============================================================================

## Emitted when a new provider is successfully registered.
signal provider_registered(provider: AeroInputProvider)

## Emitted when a provider is unregistered.
signal provider_unregistered(provider_id: String)

## Emitted when the active provider changes.
signal active_provider_changed(provider: AeroInputProvider)

# ============================================================================
# SIGNALS: LIFECYCLE (Proxied from active provider)
# ============================================================================

signal started
signal stopped
signal failed(error: String)

# ============================================================================
# SIGNALS: SPATIAL TRACKING (Proxied from active provider)
# ============================================================================

signal tracking_updated(
	head_transform: Transform3D,
	left_hand_transform: Transform3D,
	right_hand_transform: Transform3D,
	left_foot_transform: Transform3D,
	right_foot_transform: Transform3D
)

# ============================================================================
# SIGNALS: BOXING GESTURES (Proxied from active provider)
# ============================================================================

signal stance_orthodox
signal stance_southpaw
signal location_changed(zone: StringName)
signal height_changed(type: StringName)
signal punch_left(power: float)
signal punch_right(power: float)
signal uppercut_left(power: float)
signal uppercut_right(power: float)
signal cross_left(power: float)
signal cross_right(power: float)
signal hook_left(power: float)
signal hook_right(power: float)
signal block_start
signal block_end
signal weave_left
signal weave_right
signal duck_weave_left
signal duck_weave_right
signal knee_strike_left(power: float)
signal knee_strike_right(power: float)
signal leg_lift_left
signal leg_lift_right
signal run_start
signal run_end

# ============================================================================
# SIGNALS: FLOW GESTURES (Proxied from active provider)
# ============================================================================

signal slice_detected(direction: StringName, angle: float)

# ============================================================================
# INTERNAL STATE
# ============================================================================

## Dictionary of registered providers: provider_id -> AeroInputProvider.
var _providers: Dictionary = {}

## Currently active provider.
var _active_provider: AeroInputProvider = null

## Provider settings cache: provider_id -> settings_dict.
var _provider_settings: Dictionary = {}

# ============================================================================
# PUBLIC API: PROVIDER REGISTRATION
# ============================================================================

## Register a new input provider.
## @param provider: The input provider instance to register.
## @param settings: Optional dictionary of settings for this provider.
## @return: true if registration succeeded, false otherwise.
func register_provider(provider: AeroInputProvider, settings: Dictionary = {}) -> bool:
	if provider == null:
		push_error("InputManager: Cannot register null provider")
		return false
	
	var provider_id := _get_provider_id(provider)
	
	if _providers.has(provider_id):
		push_warning("InputManager: Provider '%s' already registered" % provider_id)
		return false
	
	# Probe the provider with a lightweight startup check before registration.
	if not provider.start(JSON.stringify({"test": true})):
		push_warning("InputManager: Provider '%s' failed startup test" % provider_id)
		return false
	
	provider.stop()
	
	_providers[provider_id] = provider
	_provider_settings[provider_id] = settings
	
	_connect_provider_signals(provider)
	provider_registered.emit(provider)
	
	if auto_switch_inputs:
		_evaluate_provider_priority()
	
	return true

## Unregister an input provider.
## @param provider_id: The ID of the provider to unregister.
func unregister_provider(provider_id: String) -> void:
	if not _providers.has(provider_id):
		push_warning("InputManager: Provider '%s' not found" % provider_id)
		return
	
	var provider: AeroInputProvider = _providers[provider_id]
	
	if _active_provider == provider:
		provider.stop()
		_active_provider = null
	
	_disconnect_provider_signals(provider)
	
	_providers.erase(provider_id)
	_provider_settings.erase(provider_id)
	
	provider_unregistered.emit(provider_id)
	
	if auto_switch_inputs:
		_evaluate_provider_priority()

## Get a registered provider by ID.
## @param provider_id: The provider ID to look up.
## @return: The provider instance, or null if not found.
func get_provider(provider_id: String) -> AeroInputProvider:
	return _providers.get(provider_id, null)

## Get the currently active provider.
## @return: The active provider, or null if none active.
func get_active_provider() -> AeroInputProvider:
	return _active_provider

## Get list of all registered provider IDs.
## @return: Array of provider ID strings.
func get_registered_providers() -> Array[String]:
	return _providers.keys()

# ============================================================================
# PUBLIC API: PROVIDER CONTROL
# ============================================================================

## Set a specific provider as active.
## @param provider: The provider to activate.
## @return: true if activation succeeded.
func set_active_provider(provider: AeroInputProvider) -> bool:
	if provider == null:
		push_error("InputManager: Cannot activate null provider")
		return false
	
	var provider_id := _get_provider_id(provider)
	
	if not _providers.has(provider_id):
		push_error("InputManager: Provider '%s' not registered" % provider_id)
		return false
	
	if _active_provider != null and _active_provider != provider:
		_active_provider.stop()
	
	var settings := _provider_settings.get(provider_id, {})
	var settings_json := JSON.stringify(settings)
	
	if not provider.start(settings_json):
		push_error("InputManager: Failed to start provider '%s'" % provider_id)
		return false
	
	_active_provider = provider
	active_provider_changed.emit(provider)
	
	return true

## Stop the active provider.
func stop_active_provider() -> void:
	if _active_provider != null:
		_active_provider.stop()
		_active_provider = null

# ============================================================================
# PUBLIC API: CAPABILITY CHECKS
# ============================================================================

## Check if the active provider supports a specific optional capability.
## @param capability: The Capability enum value to check.
## @return: true if the active provider supports the capability.
func active_provider_has_capability(capability: AeroInputProvider.Capability) -> bool:
	if _active_provider == null:
		return false
	return _active_provider.has_capability(capability)

## Check if any registered provider supports a specific optional capability.
## @param capability: The Capability enum value to check.
## @return: true if any provider supports the capability.
func any_provider_has_capability(capability: AeroInputProvider.Capability) -> bool:
	for provider in _providers.values():
		if provider.has_capability(capability):
			return true
	return false

# ============================================================================
# PRIVATE: SIGNAL MANAGEMENT
# ============================================================================

func _connect_provider_signals(provider: AeroInputProvider) -> void:
	provider.started.connect(func(): started.emit())
	provider.stopped.connect(func(): stopped.emit())
	provider.failed.connect(func(err): failed.emit(err))
	
	provider.tracking_updated.connect(
		func(h, lh, rh, lf, rf): tracking_updated.emit(h, lh, rh, lf, rf)
	)
	
	if provider.has_signal("punch_left"):
		_connect_boxing_signals(provider)
	
	if provider.has_signal("slice_detected"):
		_connect_flow_signals(provider)

func _connect_boxing_signals(provider: AeroInputProvider) -> void:
	if provider.has_signal("stance_orthodox"):
		provider.stance_orthodox.connect(func(): stance_orthodox.emit())
	if provider.has_signal("stance_southpaw"):
		provider.stance_southpaw.connect(func(): stance_southpaw.emit())
	if provider.has_signal("location_changed"):
		provider.location_changed.connect(func(z): location_changed.emit(z))
	if provider.has_signal("height_changed"):
		provider.height_changed.connect(func(t): height_changed.emit(t))
	
	if provider.has_signal("punch_left"):
		provider.punch_left.connect(func(p): punch_left.emit(p))
	if provider.has_signal("punch_right"):
		provider.punch_right.connect(func(p): punch_right.emit(p))
	if provider.has_signal("uppercut_left"):
		provider.uppercut_left.connect(func(p): uppercut_left.emit(p))
	if provider.has_signal("uppercut_right"):
		provider.uppercut_right.connect(func(p): uppercut_right.emit(p))
	if provider.has_signal("cross_left"):
		provider.cross_left.connect(func(p): cross_left.emit(p))
	if provider.has_signal("cross_right"):
		provider.cross_right.connect(func(p): cross_right.emit(p))
	if provider.has_signal("hook_left"):
		provider.hook_left.connect(func(p): hook_left.emit(p))
	if provider.has_signal("hook_right"):
		provider.hook_right.connect(func(p): hook_right.emit(p))
	
	if provider.has_signal("block_start"):
		provider.block_start.connect(func(): block_start.emit())
	if provider.has_signal("block_end"):
		provider.block_end.connect(func(): block_end.emit())
	if provider.has_signal("weave_left"):
		provider.weave_left.connect(func(): weave_left.emit())
	if provider.has_signal("weave_right"):
		provider.weave_right.connect(func(): weave_right.emit())
	if provider.has_signal("duck_weave_left"):
		provider.duck_weave_left.connect(func(): duck_weave_left.emit())
	if provider.has_signal("duck_weave_right"):
		provider.duck_weave_right.connect(func(): duck_weave_right.emit())
	
	if provider.has_signal("knee_strike_left"):
		provider.knee_strike_left.connect(func(p): knee_strike_left.emit(p))
	if provider.has_signal("knee_strike_right"):
		provider.knee_strike_right.connect(func(p): knee_strike_right.emit(p))
	if provider.has_signal("leg_lift_left"):
		provider.leg_lift_left.connect(func(): leg_lift_left.emit())
	if provider.has_signal("leg_lift_right"):
		provider.leg_lift_right.connect(func(): leg_lift_right.emit())
	if provider.has_signal("run_start"):
		provider.run_start.connect(func(): run_start.emit())
	if provider.has_signal("run_end"):
		provider.run_end.connect(func(): run_end.emit())

func _connect_flow_signals(provider: AeroInputProvider) -> void:
	if provider.has_signal("slice_detected"):
		provider.slice_detected.connect(func(d, a): slice_detected.emit(d, a))

func _disconnect_provider_signals(provider: AeroInputProvider) -> void:
	# Godot will usually clean these up when the provider is freed, but we keep the
	# explicit disconnect pass for predictable manager lifecycle semantics.
	var signals := provider.get_signal_list()
	for sig in signals:
		provider.disconnect(sig["name"], Callable())

# ============================================================================
# PRIVATE: PRIORITY MANAGEMENT
# ============================================================================

func _evaluate_provider_priority() -> void:
	if _providers.is_empty():
		return
	
	# Prefer the highest-ranked registered provider. The default list is ordered so
	# camera providers become the active gameplay path before future-facing peers.
	for provider_id in input_priority:
		if _providers.has(provider_id):
			var provider: AeroInputProvider = _providers[provider_id]
			if _active_provider != provider:
				set_active_provider(provider)
			return
	
	# If no configured priority entry matches, fall back to the first available
	# provider without implying product-level parity.
	if _active_provider == null:
		var first_provider: AeroInputProvider = _providers.values()[0]
		set_active_provider(first_provider)

func _get_provider_id(provider: AeroInputProvider) -> String:
	var script := provider.get_script()
	if script != null and script is GDScript:
		var global_name: String = script.get_global_name()
		if global_name != "":
			return global_name.to_snake_case()
	
	return provider.get_class().to_snake_case()

# ============================================================================
# CLEANUP
# ============================================================================

func _exit_tree() -> void:
	stop_active_provider()
	
	for provider in _providers.values():
		provider.stop()
	
	_providers.clear()
	_provider_settings.clear()
