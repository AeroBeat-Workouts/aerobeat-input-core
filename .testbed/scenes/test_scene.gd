extends Node2D
## Test scene for AeroBeat Input Core
## Verifies that the input interface classes are available

@onready var status_label: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/StatusLabel
@onready var class_list: Label = $CanvasLayer/Panel/MarginContainer/VBoxContainer/ClassList

const INTERFACE_PATH = "res://src/interfaces/input_provider.gd"

func _ready():
	print("=== AeroBeat Input Core Test Scene ===")
	
	# Verify the input interface file exists and can be loaded
	var file_exists = FileAccess.file_exists(INTERFACE_PATH)
	var script_loaded = false
	var script: Script = null
	
	if file_exists:
		script = load(INTERFACE_PATH)
		script_loaded = script != null
	
	if file_exists and script_loaded:
		status_label.text = "✓ AeroBeat Input Core Loaded Successfully"
		status_label.add_theme_color_override("font_color", Color.GREEN)
		print("✓ AeroInputProvider interface found at: " + INTERFACE_PATH)
		print("✓ Script resource loaded: " + str(script.resource_path))
		
		# Show class info
		var class_info = _get_class_info()
		class_list.text = class_info
	else:
		status_label.text = "✗ AeroBeat Input Core NOT found"
		status_label.add_theme_color_override("font_color", Color.RED)
		class_list.text = "Error: Could not load
" + INTERFACE_PATH
		push_error("AeroBeat Input Core interface not found!")
	
	print("================================")

func _get_class_info() -> String:
	var info = "Available Classes:
"
	info += "- AeroInputProvider
"
	info += "
Tracking Modes:
"
	info += "  • MODE_2D (2D viewport coordinates)
"
	info += "  • MODE_3D (3D world coordinates)
"
	info += "
Body Track Flags:
"
	info += "  • HEAD
"
	info += "  • LEFT_HAND
"
	info += "  • RIGHT_HAND
"
	info += "  • LEFT_FOOT
"
	info += "  • RIGHT_FOOT"
	return info
