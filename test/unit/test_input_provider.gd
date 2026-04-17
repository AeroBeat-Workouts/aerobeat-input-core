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

	var combined = AeroInputProvider.BodyTrackFlags.HEAD | AeroInputProvider.BodyTrackFlags.LEFT_HAND
	assert_eq(combined, 3, "Combined flags should work")
