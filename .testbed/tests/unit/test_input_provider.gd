extends "res://addons/gut/test.gd"

func test_aero_input_provider_default_left_hand_position_is_zero_vector():
	var provider = autofree(AeroInputProvider.new())

	var result = provider.get_left_hand_position()
	assert_push_error("AeroInputProvider: get_left_hand_position() must be overridden")
	assert_eq(result, Vector3.ZERO, "Default abstract implementation should return Vector3.ZERO")

func test_tracking_mode_enum_values():
	assert_eq(AeroInputProvider.TrackingMode.MODE_2D, 0)
	assert_eq(AeroInputProvider.TrackingMode.MODE_3D, 1)

func test_body_track_flags_bitfield():
	assert_eq(AeroInputProvider.BodyTrackFlags.NONE, 0)
	assert_eq(AeroInputProvider.BodyTrackFlags.HEAD, 1)
	assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_HAND, 2)
	assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_HAND, 4)
	assert_eq(AeroInputProvider.BodyTrackFlags.LEFT_FOOT, 8)
	assert_eq(AeroInputProvider.BodyTrackFlags.RIGHT_FOOT, 16)

	var combined = AeroInputProvider.BodyTrackFlags.HEAD | AeroInputProvider.BodyTrackFlags.LEFT_HAND
	assert_eq(combined, 3, "Combined flags should work")

func test_optional_capability_enum_values_remain_stable():
	assert_eq(AeroInputProvider.Capability.SPATIAL_TRANSFORM, 1)
	assert_eq(AeroInputProvider.Capability.GESTURE_RECOGNITION, 2)
	assert_eq(AeroInputProvider.Capability.LOWER_BODY, 4)
	assert_eq(AeroInputProvider.Capability.HAPTICS, 8)
	assert_eq(AeroInputProvider.Capability.VELOCITY, 16)

func test_flow_input_reports_gesture_capability_without_claiming_other_optional_features():
	var provider = autofree(FlowInput.new())

	assert_true(provider.has_capability(AeroInputProvider.Capability.GESTURE_RECOGNITION))
	assert_false(provider.has_capability(AeroInputProvider.Capability.LOWER_BODY))
	assert_false(provider.has_capability(AeroInputProvider.Capability.HAPTICS))

func test_boxing_input_reports_gesture_and_lower_body_capabilities_as_provider_extensions():
	var provider = autofree(BoxingInput.new())

	assert_true(provider.has_capability(AeroInputProvider.Capability.GESTURE_RECOGNITION))
	assert_true(provider.has_capability(AeroInputProvider.Capability.LOWER_BODY))
	assert_false(provider.has_capability(AeroInputProvider.Capability.HAPTICS))
