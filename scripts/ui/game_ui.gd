extends CanvasLayer
class_name GameUI

@onready var bipob = get_node("../Bipob")

@onready var status_label: Label = $StatusLabel
@onready var hint_label: Label = $HintLabel
@onready var command_panel: PanelContainer = $CommandPanel
@onready var box_screen: Control = $BoxScreen

var diagnostic_label: Label

@onready var box_status_label: Label = $BoxScreen/PanelContainer/VBoxContainer/StatusLabel
@onready var box_module_label: Label = $BoxScreen/PanelContainer/VBoxContainer/ModuleLabel
@onready var installed_modules_label: Label = $BoxScreen/PanelContainer/VBoxContainer/InstalledModulesLabel
var box_storage_label: Label
var digital_storage_label: Label
@onready var charge_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/ChargeButton
@onready var install_module_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/InstallModuleButton
@onready var start_mission_button: Button = $BoxScreen/PanelContainer/VBoxContainer/ButtonRow/StartMissionButton
var remove_module_button: Button

@onready var box_title_label: Label = $BoxScreen/PanelContainer/VBoxContainer/TitleLabel
var box_content_scroll: ScrollContainer = null
var box_content_label: Label = null
var right_button_panel: VBoxContainer = null
var main_box_row: HBoxContainer = null
var left_panel: VBoxContainer = null

@onready var move_forward_button: Button = $CommandPanel/CommandList/MoveForwardButton
@onready var move_backward_button: Button = $CommandPanel/CommandList/MoveBackwardButton
@onready var turn_left_button: Button = $CommandPanel/CommandList/TurnLeftButton
@onready var turn_right_button: Button = $CommandPanel/CommandList/TurnRightButton
@onready var interact_button: Button = $CommandPanel/CommandList/InteractButton
@onready var end_turn_button: Button = $CommandPanel/CommandList/EndTurnButton

var scan_device_button: Button
var hack_device_button: Button
var restart_mission_button: Button
var return_to_box_button: Button
var drop_item_button: Button
var rotate_storage_button: Button
var start_mission_warning_acknowledged: bool = false
var should_advance_mission_on_start: bool = false
var selected_installed_module_index: int = 0
var selected_box_storage_index: int = 0
var selected_filtered_box_index: int = 0
var selected_grouped_module_index: int = 0
var constructor_filter_index: int = 0
const CONSTRUCTOR_FILTERS: Array[String] = [
	"all",
	"external",
	"internal",
	"power",
	"cooling",
	"data",
	"locomotion",
	"vision",
	"storage",
	"utility"
]
var prev_installed_button: Button
var next_installed_button: Button
var prev_box_button: Button
var next_box_button: Button
var box_tab_row: HBoxContainer = null
var mission_tab_button: Button
var modules_tab_button: Button
var external_tab_button: Button
var internal_tab_button: Button
var box_restart_button: Button
var box_return_button: Button

enum BoxMenuMode {
	MISSION,
	MODULES,
	EXTERNAL,
	INTERNAL
}

var box_menu_mode: BoxMenuMode = BoxMenuMode.MISSION
var selected_external_side_index: int = 1
var selected_external_slot_position: Vector2i = Vector2i(1, 1)
var internal_view_mode: String = "modules"

func _configure_box_layout() -> void:
	if box_screen == null:
		return
	var panel: PanelContainer = box_screen.get_node_or_null("PanelContainer")
	var vbox: VBoxContainer = box_screen.get_node_or_null("PanelContainer/VBoxContainer")
	if panel == null or vbox == null:
		return
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -540
	panel.offset_top = 16
	panel.offset_right = -16
	panel.offset_bottom = 632
	panel.custom_minimum_size = Vector2(520, 0)

	main_box_row = vbox.get_node_or_null("MainBoxRow")
	if main_box_row == null:
		main_box_row = HBoxContainer.new()
		main_box_row.name = "MainBoxRow"
		vbox.add_child(main_box_row)

	left_panel = vbox.get_node_or_null("MainBoxRow/LeftPanel")
	if left_panel == null:
		left_panel = VBoxContainer.new()
		left_panel.name = "LeftPanel"
		main_box_row.add_child(left_panel)
	left_panel.custom_minimum_size = Vector2(350, 0)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if box_title_label != null:
		box_title_label.reparent(left_panel)

	box_tab_row = left_panel.get_node_or_null("BoxTabRow")
	if box_tab_row == null:
		box_tab_row = HBoxContainer.new()
		box_tab_row.name = "BoxTabRow"
		left_panel.add_child(box_tab_row)
	box_tab_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

	box_content_scroll = left_panel.get_node_or_null("BoxContentScroll")
	if box_content_scroll == null:
		box_content_scroll = ScrollContainer.new()
		box_content_scroll.name = "BoxContentScroll"
		left_panel.add_child(box_content_scroll)
	box_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box_content_scroll.custom_minimum_size = Vector2(320, 340)

	box_content_label = box_content_scroll.get_node_or_null("BoxContentLabel")
	if box_content_label == null:
		box_content_label = Label.new()
		box_content_label.name = "BoxContentLabel"
		box_content_scroll.add_child(box_content_label)
	box_content_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box_content_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if box_status_label != null:
		box_status_label.visible = false
		box_status_label.text = ""
	if box_module_label != null:
		box_module_label.visible = false
		box_module_label.text = ""
	if installed_modules_label != null:
		installed_modules_label.visible = false
		installed_modules_label.text = ""
	if box_storage_label != null:
		box_storage_label.visible = false
		box_storage_label.text = ""
	if digital_storage_label != null:
		digital_storage_label.visible = false
		digital_storage_label.text = ""

	var old_button_row := vbox.get_node_or_null("ButtonRow")
	if old_button_row != null:
		old_button_row.visible = false
		for child in old_button_row.get_children():
			child.queue_free()

	for row_name in ["InstalledButtonRow", "BoxStorageButtonRow", "MissionButtonRow"]:
		var old_row := vbox.get_node_or_null(row_name)
		if old_row != null:
			old_row.visible = false
			for child in old_row.get_children():
				child.queue_free()

	right_button_panel = main_box_row.get_node_or_null("RightButtonPanel")
	if right_button_panel == null:
		right_button_panel = VBoxContainer.new()
		right_button_panel.name = "RightButtonPanel"
		main_box_row.add_child(right_button_panel)
	right_button_panel.custom_minimum_size = Vector2(140, 0)
	right_button_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	right_button_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL

func get_short_module_name(module: BipobModule) -> String:
	if module == null:
		return "empty"
	return bipob.get_module_display_name(module)

func get_selected_installed_module_text() -> String:
	if bipob == null or bipob.installed_modules.is_empty():
		return "Selected installed: none"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.installed_modules[selected_installed_module_index]
	return "Selected installed: " + get_short_module_name(module)

func get_selected_box_module_text() -> String:
	if bipob == null:
		return "Selected box: none"
	sync_selected_box_storage_index_from_filter()
	if bipob.box_storage.is_empty() or selected_box_storage_index < 0 or selected_box_storage_index >= bipob.box_storage.size():
		return "Selected box: none"
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	return "Selected box: " + get_short_module_name(module)

func get_current_constructor_filter() -> String:
	if constructor_filter_index < 0:
		constructor_filter_index = CONSTRUCTOR_FILTERS.size() - 1
	elif constructor_filter_index >= CONSTRUCTOR_FILTERS.size():
		constructor_filter_index = 0
	return String(CONSTRUCTOR_FILTERS[constructor_filter_index])

func module_matches_constructor_filter(module: BipobModule, filter_id: String) -> bool:
	if module == null:
		return false
	if filter_id == "all":
		return true
	var category: String = bipob.get_module_category(module)
	if category == filter_id:
		return true
	if filter_id == "external":
		return module.placement_type == "external"
	if filter_id == "internal":
		return module.placement_type == "internal"
	return false

func get_filtered_box_storage_indices(filter_id: String) -> Array[int]:
	var indices: Array[int] = []
	if bipob == null:
		return indices
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module_matches_constructor_filter(module, filter_id):
			indices.append(i)
	return indices

func get_filtered_internal_box_storage_indices(filter_id: String) -> Array[int]:
	var indices: Array[int] = []
	if bipob == null:
		return indices
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module == null or module.placement_type != "internal":
			continue
		if filter_id == "all" or filter_id == "internal" or module_matches_constructor_filter(module, filter_id):
			indices.append(i)
	return indices

func get_current_filtered_box_storage_indices() -> Array[int]:
	var filter_id: String = get_current_constructor_filter()
	if box_menu_mode == BoxMenuMode.INTERNAL:
		return get_filtered_internal_box_storage_indices(filter_id)
	return get_filtered_box_storage_indices(filter_id)

func get_selected_filtered_box_storage_index() -> int:
	var indices: Array[int] = get_current_filtered_box_storage_indices()
	if indices.is_empty():
		return -1
	selected_filtered_box_index = clampi(selected_filtered_box_index, 0, indices.size() - 1)
	return indices[selected_filtered_box_index]

func sync_selected_box_storage_index_from_filter() -> void:
	var raw_index: int = get_selected_filtered_box_storage_index()
	if raw_index >= 0:
		selected_box_storage_index = raw_index

func get_filtered_grouped_module_ids() -> Array[String]:
	var ids: Array[String] = []
	if bipob == null:
		return ids
	var filter_id: String = get_current_constructor_filter()
	var append_id := func(module_id: String) -> void:
		if module_id.is_empty() or ids.has(module_id):
			return
		var representative: BipobModule = bipob.get_first_module_by_id(module_id)
		if representative == null:
			return
		if module_matches_constructor_filter(representative, filter_id):
			ids.append(module_id)

	for module in bipob.box_storage:
		if module != null:
			append_id.call(module.id)
	for module in bipob.get_unique_external_modules():
		if module != null:
			append_id.call(module.id)
	for module in bipob.get_unique_internal_modules():
		if module != null:
			append_id.call(module.id)
	return ids

func get_selected_grouped_module_id() -> String:
	var ids: Array[String] = get_filtered_grouped_module_ids()
	if ids.is_empty():
		return ""
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, ids.size() - 1)
	return ids[selected_grouped_module_index]

func get_selected_grouped_module() -> BipobModule:
	var module_id: String = get_selected_grouped_module_id()
	if module_id.is_empty():
		return null
	return bipob.get_first_module_by_id(module_id)

func sync_selected_box_storage_index_from_grouped_selection() -> void:
	var module_id: String = get_selected_grouped_module_id()
	if module_id.is_empty():
		selected_box_storage_index = -1
		return
	for i in range(bipob.box_storage.size()):
		var module: BipobModule = bipob.box_storage[i]
		if module != null and module.id == module_id:
			selected_box_storage_index = i
			return
	selected_box_storage_index = -1

func get_compact_module_window(modules: Array, selected_index: int, max_lines: int = 4) -> Array[String]:
	if modules.is_empty():
		return ["empty"]

	var total: int = modules.size()
	var safe_index: int = clampi(selected_index, 0, total - 1)
	var window_size: int = mini(max_lines, total)
	var start_idx: int = clampi(safe_index - int(window_size / 2), 0, total - window_size)
	var end_idx: int = start_idx + window_size - 1
	var lines: Array[String] = []

	if start_idx > 0:
		lines.append("... ")

	for index in range(start_idx, end_idx + 1):
		var marker := "  "
		if index == safe_index:
			marker = "> "
		lines.append("%s%s" % [marker, get_short_module_name(modules[index])])

	if end_idx < total - 1:
		lines.append("... ")

	return lines

func get_digital_storage_short_text() -> String:
	if bipob == null:
		return "Digital: empty"
	if bipob.has_method("get_digital_storage_short_text"):
		var short_text := str(bipob.get_digital_storage_short_text())
		if short_text.is_empty() or short_text == "empty":
			return "Digital: empty"
		return "Digital: %s" % short_text
	if bipob.has_method("get_digital_storage_text"):
		var full_text := str(bipob.get_digital_storage_text())
		if full_text.begins_with("Digital storage:\n- "):
			var list_text := full_text.trim_prefix("Digital storage:\n- ").replace("\n- ", ", ")
			if list_text.is_empty():
				return "Digital: empty"
			return "Digital: %s" % list_text
		if full_text.begins_with("Digital storage: "):
			var one_line := full_text.trim_prefix("Digital storage: ")
			if one_line.is_empty() or one_line == "empty":
				return "Digital: empty"
			return "Digital: %s" % one_line
	return "Digital: empty"

func format_2d_size(size: Vector2i) -> String:
	return "%d×%d" % [size.x, size.y]

func format_3d_size(size: Vector3i) -> String:
	return "%d×%d×%d" % [size.x, size.y, size.z]

func get_module_details_text(module: BipobModule) -> String:
	if module == null:
		return "Selected item:\nnone"
	var lines: Array[String] = []
	lines.append("Selected item:")
	lines.append("Name: %s" % bipob.get_module_display_name(module))
	lines.append("ID: %s" % module.id)
	if module.id == "water_tube_v1" or module.id == "air_duct_v1":
		lines.append("Placement: overlay path")
		lines.append("Path type: liquid" if module.id == "water_tube_v1" else "Path type: duct")
	else:
		lines.append("Placement: %s" % module.placement_type)
	lines.append("Category: %s" % bipob.get_module_category(module))
	if module.placement_type == "external":
		var module_size_2d: Vector2i = bipob.get_external_module_size(module)
		lines.append("Size: %s external" % format_2d_size(module_size_2d))
		lines.append("Allowed sides: %s" % bipob.get_allowed_external_sides_text(module))
	elif module.placement_type == "internal":
		var module_size_3d := Vector3i(module.size_x, module.size_y, module.size_z)
		lines.append("Size: %s" % format_3d_size(module_size_3d))
		lines.append("Role: %s" % (module.internal_role if not module.internal_role.is_empty() else "none"))
		lines.append("Heat: %d / %d" % [module.heat_idle, module.heat_active])
		if module.cooling_power > 0 or module.cooling_type != "none":
			if module.cooling_type == "none":
				lines.append("Cooling: %d" % module.cooling_power)
			elif module.cooling_power > 0:
				lines.append("Cooling: %s %d" % [module.cooling_type, module.cooling_power])
			else:
				lines.append("Cooling: %s" % module.cooling_type)
		else:
			lines.append("Cooling: none")
		lines.append("Air intake: %s" % ("required" if module.requires_air_intake else "no"))
		lines.append("Allowed sides: n/a")
	else:
		lines.append("Size: n/a")
		lines.append("Allowed sides: n/a")
	if not module.description.is_empty():
		lines.append("Description: %s" % module.description)
	lines.append(str(bipob.get_module_repair_metadata_text(module)))
	lines.append(bipob.get_module_availability_text(module))
	if module.id == "water_tube_v1" or module.id == "air_duct_v1":
		lines.append("Note: does not consume internal volume")
	return "\n".join(lines)

func _ready() -> void:
	if status_label != null:
		status_label.position = Vector2(100, 20)
	if hint_label != null:
		hint_label.position = Vector2(100, 50)
		hint_label.text = "Mission 1: pick up the key, open the door, reach the exit."

	diagnostic_label = Label.new()
	diagnostic_label.name = "DiagnosticLabel"
	diagnostic_label.position = Vector2(100, 80)
	diagnostic_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	diagnostic_label.custom_minimum_size = Vector2(700, 140)
	diagnostic_label.text = "Diagnostic: none"
	add_child(diagnostic_label)

	if command_panel != null:
		command_panel.position = Vector2(850, 80)
		command_panel.custom_minimum_size = Vector2(220, 260)

	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = true
	_configure_box_layout()

	if box_storage_label == null:
		box_storage_label = Label.new()
		box_storage_label.name = "BoxStorageLabel"
		box_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if box_vbox != null:
			box_vbox.add_child(box_storage_label)
			if start_mission_button != null:
				box_vbox.move_child(box_storage_label, start_mission_button.get_index())

	if digital_storage_label == null:
		digital_storage_label = Label.new()
		digital_storage_label.name = "DigitalStorageLabel"
		digital_storage_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var digital_box_vbox := box_screen.get_node_or_null("PanelContainer/VBoxContainer")
		if digital_box_vbox != null:
			digital_box_vbox.add_child(digital_storage_label)
			if start_mission_button != null:
				digital_box_vbox.move_child(digital_storage_label, start_mission_button.get_index())

	if move_forward_button != null:
		move_forward_button.focus_mode = Control.FOCUS_NONE
	if move_backward_button != null:
		move_backward_button.focus_mode = Control.FOCUS_NONE
	if turn_left_button != null:
		turn_left_button.focus_mode = Control.FOCUS_NONE
	if turn_right_button != null:
		turn_right_button.focus_mode = Control.FOCUS_NONE
	if interact_button != null:
		interact_button.focus_mode = Control.FOCUS_NONE
	if end_turn_button != null:
		end_turn_button.focus_mode = Control.FOCUS_NONE

	drop_item_button = Button.new()
	drop_item_button.name = "DropItemButton"
	drop_item_button.text = "Drop Item"
	drop_item_button.focus_mode = Control.FOCUS_NONE

	rotate_storage_button = Button.new()
	rotate_storage_button.name = "RotateStorageButton"
	rotate_storage_button.text = "Rotate Storage"
	rotate_storage_button.focus_mode = Control.FOCUS_NONE

	scan_device_button = Button.new()
	scan_device_button.name = "ScanDeviceButton"
	scan_device_button.text = "Scan Device"
	scan_device_button.focus_mode = Control.FOCUS_NONE
	var command_list: Node = null
	if command_panel != null:
		command_list = command_panel.get_node_or_null("CommandList")
	if command_list != null:
		command_list.add_child(drop_item_button)
		drop_item_button.pressed.connect(_on_drop_item_button_pressed)
		command_list.add_child(rotate_storage_button)
		rotate_storage_button.pressed.connect(_on_rotate_storage_button_pressed)
		command_list.add_child(scan_device_button)
		scan_device_button.pressed.connect(_on_scan_device_button_pressed)
		hack_device_button = Button.new()
		hack_device_button.name = "HackDeviceButton"
		hack_device_button.text = "Hack Device"
		hack_device_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(hack_device_button)
		hack_device_button.pressed.connect(_on_hack_device_button_pressed)
		restart_mission_button = Button.new()
		restart_mission_button.name = "RestartMissionButton"
		restart_mission_button.text = "Restart Mission"
		restart_mission_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(restart_mission_button)
		restart_mission_button.pressed.connect(_on_restart_mission_button_pressed)
		return_to_box_button = Button.new()
		return_to_box_button.name = "ReturnToBoxButton"
		return_to_box_button.text = "Return to Box"
		return_to_box_button.focus_mode = Control.FOCUS_NONE
		command_list.add_child(return_to_box_button)
		return_to_box_button.pressed.connect(_on_return_to_box_button_pressed)

	if move_forward_button != null:
		move_forward_button.pressed.connect(_on_move_forward_pressed)
	if move_backward_button != null:
		move_backward_button.pressed.connect(_on_move_backward_pressed)
	if turn_left_button != null:
		turn_left_button.pressed.connect(_on_turn_left_pressed)
	if turn_right_button != null:
		turn_right_button.pressed.connect(_on_turn_right_pressed)
	if interact_button != null:
		interact_button.pressed.connect(_on_interact_pressed)
	if end_turn_button != null:
		end_turn_button.pressed.connect(_on_end_turn_pressed)

	if charge_button != null:
		charge_button.text = "Charge"
		charge_button.visible = false
		charge_button.focus_mode = Control.FOCUS_NONE
	if install_module_button != null:
		install_module_button.text = "Install"
		install_module_button.visible = false
		install_module_button.focus_mode = Control.FOCUS_NONE
	if start_mission_button != null:
		start_mission_button.text = "Start"
		start_mission_button.visible = false
		start_mission_button.focus_mode = Control.FOCUS_NONE

	remove_module_button = null

	prev_installed_button = null

	next_installed_button = null

	prev_box_button = null

	next_box_button = null

	mission_tab_button = Button.new()
	mission_tab_button.name = "MissionTabButton"
	mission_tab_button.text = "Mission"
	mission_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(mission_tab_button)
	mission_tab_button.pressed.connect(set_box_menu_mode_mission)

	modules_tab_button = Button.new()
	modules_tab_button.name = "ModulesTabButton"
	modules_tab_button.text = "Modules"
	modules_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(modules_tab_button)
	modules_tab_button.pressed.connect(set_box_menu_mode_modules)

	external_tab_button = Button.new()
	external_tab_button.name = "ExternalTabButton"
	external_tab_button.text = "External"
	external_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(external_tab_button)
	external_tab_button.pressed.connect(set_box_menu_mode_external)
	internal_tab_button = Button.new()
	internal_tab_button.name = "InternalTabButton"
	internal_tab_button.text = "Internal"
	internal_tab_button.focus_mode = Control.FOCUS_NONE
	box_tab_row.add_child(internal_tab_button)
	internal_tab_button.pressed.connect(set_box_menu_mode_internal)

	box_restart_button = null

	box_return_button = null

	bipob.status_changed.connect(update_status)
	bipob.hint_requested.connect(show_hint)
	bipob.mission_completed.connect(_on_mission_completed)
	bipob.returned_to_box.connect(_on_returned_to_box)

	update_status()
	rebuild_box_action_buttons()
	update_box_status()
	update_diagnostic_status()

func _on_charge_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	bipob.charge_to_full()
	start_mission_warning_acknowledged = false
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_install_module_button_pressed() -> void:
	# BoxScreen preparation action: must not spend field action points or energy.
	_on_install_selected_box_module_pressed()

func clamp_box_selection_indexes() -> void:
	if bipob == null:
		selected_installed_module_index = 0
		selected_box_storage_index = 0
		return

	if bipob.installed_modules.is_empty():
		selected_installed_module_index = 0
	else:
		selected_installed_module_index = clampi(selected_installed_module_index, 0, bipob.installed_modules.size() - 1)

	if bipob.box_storage.is_empty():
		selected_box_storage_index = 0
	else:
		selected_box_storage_index = clampi(selected_box_storage_index, 0, bipob.box_storage.size() - 1)
	var filtered_indices: Array[int] = get_current_filtered_box_storage_indices()
	if filtered_indices.is_empty():
		selected_filtered_box_index = 0
	else:
		if selected_box_storage_index in filtered_indices:
			selected_filtered_box_index = filtered_indices.find(selected_box_storage_index)
		else:
			selected_filtered_box_index = clampi(selected_filtered_box_index, 0, filtered_indices.size() - 1)
			selected_box_storage_index = filtered_indices[selected_filtered_box_index]

func _on_prev_installed_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules.")
		return
	selected_installed_module_index -= 1
	if selected_installed_module_index < 0:
		selected_installed_module_index = bipob.installed_modules.size() - 1
	update_box_status()

func _on_next_installed_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules.")
		return
	selected_installed_module_index += 1
	if selected_installed_module_index >= bipob.installed_modules.size():
		selected_installed_module_index = 0
	update_box_status()

func _on_remove_selected_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.installed_modules.is_empty():
		show_hint("No installed modules to remove.")
		return
	clamp_box_selection_indexes()
	bipob.remove_installed_module_to_box_by_index(selected_installed_module_index)
	start_mission_warning_acknowledged = false
	clamp_box_selection_indexes()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_prev_box_pressed() -> void:
	if bipob == null:
		return
	var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
	if grouped_ids.is_empty():
		show_hint("No module matches current filter.")
		return
	selected_grouped_module_index = posmod(selected_grouped_module_index - 1, grouped_ids.size())
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_box_selection_indexes()
	update_box_status()

func _on_next_box_pressed() -> void:
	if bipob == null:
		return
	var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
	if grouped_ids.is_empty():
		show_hint("No module matches current filter.")
		return
	selected_grouped_module_index = posmod(selected_grouped_module_index + 1, grouped_ids.size())
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_box_selection_indexes()
	update_box_status()

func _on_install_selected_box_module_pressed() -> void:
	if bipob == null:
		return
	if bipob.box_storage.is_empty():
		show_hint("No module in Box Storage to install.")
		return
	sync_selected_box_storage_index_from_filter()
	clamp_box_selection_indexes()
	bipob.install_module_from_box_storage(selected_box_storage_index)
	start_mission_warning_acknowledged = false
	clamp_box_selection_indexes()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_remove_module_button_pressed() -> void:
	_on_remove_selected_module_pressed()

func get_selected_external_side_id() -> String:
	if bipob == null:
		return ""
	if selected_external_side_index < 0:
		selected_external_side_index = 0
	if selected_external_side_index >= bipob.EXTERNAL_SIDE_ORDER.size():
		selected_external_side_index = 0
	return String(bipob.EXTERNAL_SIDE_ORDER[selected_external_side_index])

func clamp_external_selection() -> void:
	if bipob == null:
		return

	if selected_external_side_index < 0:
		selected_external_side_index = bipob.EXTERNAL_SIDE_ORDER.size() - 1
	elif selected_external_side_index >= bipob.EXTERNAL_SIDE_ORDER.size():
		selected_external_side_index = 0

	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	selected_external_slot_position.x = clampi(selected_external_slot_position.x, 0, side_size.x - 1)
	selected_external_slot_position.y = clampi(selected_external_slot_position.y, 0, side_size.y - 1)

func get_external_module_marker(module: BipobModule) -> String:
	if module == null:
		return "M"
	match module.id:
		"wheels_v1":
			return "W"
		"legs_v1":
			return "L"
		"tracks_v1":
			return "T"
		"visor_v1", "visor_v2":
			return "V"
		"manipulator_v1":
			return "M"
		"interface_v1":
			return "I"
		_:
			var module_name: String = bipob.get_module_display_name(module).to_upper()
			if module_name.is_empty():
				return "M"
			return module_name.substr(0, 1)

func get_yes_no(value: bool) -> String:
	return "yes" if value else "no"

func get_selected_box_module_allowed_sides_text() -> String:
	if bipob == null or bipob.box_storage.is_empty():
		return "Allowed sides: n/a"
	clamp_box_selection_indexes()
	var module: BipobModule = bipob.box_storage[selected_box_storage_index]
	if module == null:
		return "Allowed sides: n/a"
	return "Allowed sides: %s" % bipob.get_allowed_external_sides_text(module)

func get_external_side_orientation_text(side_id: String) -> String:
	var lines: Array[String] = []
	match side_id:
		bipob.EXTERNAL_SIDE_TOP:
			lines.append("Orientation: FRONT ↑ / BACK ↓ / LEFT ← / RIGHT →")
		bipob.EXTERNAL_SIDE_BOTTOM:
			lines.append("Orientation: FRONT ↑ / BACK ↓ / LEFT ← / RIGHT →")
			lines.append("Note: viewed from outside bottom.")
		bipob.EXTERNAL_SIDE_FRONT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / LEFT ← / RIGHT →")
		bipob.EXTERNAL_SIDE_BACK:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / RIGHT ← / LEFT →")
			lines.append("Note: viewed from outside back.")
		bipob.EXTERNAL_SIDE_LEFT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / FRONT ← / BACK →")
		bipob.EXTERNAL_SIDE_RIGHT:
			lines.append("Orientation: TOP ↑ / BOTTOM ↓ / BACK ← / FRONT →")
		_:
			lines.append("Orientation: n/a")
	return "\n".join(lines)

func get_external_side_installed_list_text(side_id: String) -> String:
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var lines: Array[String] = []
	var seen_modules: Array[BipobModule] = []
	for y in range(side_size.y):
		for x in range(side_size.x):
			var module: BipobModule = bipob.get_external_module_at(side_id, Vector2i(x, y))
			if module == null or seen_modules.has(module):
				continue
			seen_modules.append(module)
			var origin := Vector2i(side_size.x, side_size.y)
			for yy in range(side_size.y):
				for xx in range(side_size.x):
					if bipob.get_external_module_at(side_id, Vector2i(xx, yy)) == module:
						origin.x = mini(origin.x, xx)
						origin.y = mini(origin.y, yy)
			var module_size: Vector2i = bipob.get_external_module_size(module)
			lines.append("- x%d,y%d: %s (%dx%d)" % [origin.x, origin.y, bipob.get_module_display_name(module), module_size.x, module_size.y])
	if lines.is_empty():
		return "none"
	return "\n".join(lines)

func _on_start_mission_button_pressed() -> void:
	if bipob == null:
		return

	# BoxScreen preparation action: starts mission flow without field action/energy spend.
	if bipob.sector_completed and should_advance_mission_on_start:
		bipob.start_next_mission()
		start_mission_warning_acknowledged = false
		update_status()
		update_box_status()
		update_diagnostic_status()
		return

	var warnings: Array[String] = bipob.get_pre_mission_warnings()
	if not bipob.can_start_mission_from_box():
		show_hint("Cannot start mission. Battery depleted. Charge first.")
		start_mission_warning_acknowledged = false
		update_box_status()
		return

	if not warnings.is_empty() and not start_mission_warning_acknowledged:
		start_mission_warning_acknowledged = true
		show_hint("Warnings before mission. Press Start Mission again to continue anyway.")
		update_box_status()
		return

	if should_advance_mission_on_start:
		bipob.start_next_mission()
	else:
		bipob.start_mission(bipob.current_mission_index)
	should_advance_mission_on_start = false
	start_mission_warning_acknowledged = false
	if not bipob.sector_completed:
		hide_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func _on_mission_completed() -> void:
	should_advance_mission_on_start = true
	show_box_screen()
	update_box_status()

func _on_returned_to_box() -> void:
	should_advance_mission_on_start = false
	show_box_screen()
	update_box_status()

func show_box_screen() -> void:
	if box_screen != null:
		box_screen.visible = true
	if command_panel != null:
		command_panel.visible = false
	start_mission_warning_acknowledged = false
	update_box_status()
	
func hide_box_screen() -> void:
	if box_screen != null:
		box_screen.visible = false
	if command_panel != null:
		command_panel.visible = true
	update_status()
	update_box_status()
	update_diagnostic_status()
	
func update_box_status() -> void:
	if bipob == null:
		return

	clamp_box_selection_indexes()
	update_diagnostic_status()

	if box_title_label != null:
		if box_menu_mode == BoxMenuMode.MISSION:
			box_title_label.text = "Box / Garage — Mission"
		elif box_menu_mode == BoxMenuMode.EXTERNAL:
			box_title_label.text = "Box / Garage — External Constructor"
		elif box_menu_mode == BoxMenuMode.INTERNAL:
			box_title_label.text = "Box / Garage — Internal Constructor"
		else:
			box_title_label.text = "Box / Garage — Modules"

	var content_text: String
	if box_menu_mode == BoxMenuMode.MISSION:
		content_text = get_box_mission_menu_text()
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		content_text = get_box_external_menu_text()
	elif box_menu_mode == BoxMenuMode.INTERNAL:
		content_text = get_box_internal_menu_text()
	else:
		content_text = get_box_modules_menu_text()
	update_box_button_visibility()

	if box_content_label != null:
		box_content_label.text = content_text

func get_box_mission_menu_text() -> String:
	var content_lines: Array[String] = []
	var mission_name := "n/a"
	if bipob.has_method("get_mission_name"):
		mission_name = str(bipob.get_mission_name(bipob.current_mission_index))
	content_lines.append("Mission:")
	content_lines.append("Mission %d — %s" % [bipob.current_mission_index + 1, mission_name])
	content_lines.append("")
	content_lines.append("Energy:")
	content_lines.append("%d / %d" % [bipob.energy, bipob.max_energy])
	content_lines.append("")
	content_lines.append(bipob.get_constructor_readiness_summary_text())
	content_lines.append("")
	content_lines.append(bipob.get_constructor_warning_summary_text())

	var warnings: Array = bipob.get_pre_mission_warnings()
	content_lines.append("")
	if warnings.is_empty():
		content_lines.append("Warnings: none")
	else:
		content_lines.append("Warnings:")
		var warning_limit := mini(2, warnings.size())
		for index in range(warning_limit):
			content_lines.append("- %s" % str(warnings[index]))
		if warnings.size() > warning_limit:
			content_lines.append("- ... +%d more" % (warnings.size() - warning_limit))

	var hand_text := "empty"
	if bipob.held_module != null:
		hand_text = bipob.get_module_display_name(bipob.held_module)
	var storage_text := "empty"
	if bipob.stored_physical_module != null:
		storage_text = bipob.get_module_display_name(bipob.stored_physical_module)
	content_lines.append("")
	content_lines.append("Carry:")
	content_lines.append("Hand: %s" % hand_text)
	content_lines.append("Robot storage: %s" % storage_text)
	content_lines.append("Carry: %d / %d" % [bipob.get_carried_physical_count(), bipob.physical_carry_capacity])

	content_lines.append("")
	content_lines.append(get_digital_storage_short_text())
	content_lines.append("")
	if bipob.found_module != null:
		content_lines.append("Found: %s" % bipob.get_module_display_name(bipob.found_module))
	else:
		content_lines.append("Found: none")
	content_lines.append("Box storage: %d modules" % bipob.box_storage.size())
	content_lines.append("Installed: %d modules" % bipob.installed_modules.size())
	return "\n".join(content_lines)

func get_box_modules_menu_text() -> String:
	sync_selected_box_storage_index_from_grouped_selection()
	var filter_id: String = get_current_constructor_filter()
	var grouped_ids: Array[String] = get_filtered_grouped_module_ids()
	var content_lines: Array[String] = []
	content_lines.append("Constructor Dashboard")
	content_lines.append("")
	content_lines.append(bipob.get_constructor_readiness_summary_text())
	content_lines.append("")
	content_lines.append(bipob.get_constructor_warning_summary_text())
	content_lines.append("")
	content_lines.append("Storage:")
	content_lines.append("Box: %d" % bipob.box_storage.size())
	content_lines.append("External installed: %d" % bipob.get_unique_external_modules().size())
	content_lines.append("Internal installed: %d" % bipob.get_unique_internal_modules().size())
	content_lines.append("Overlay paths: %d" % bipob.internal_overlay_paths.size())
	content_lines.append("Liquid paths: %d" % bipob.get_liquid_overlay_path_count())
	content_lines.append("Duct paths: %d" % bipob.get_duct_overlay_path_count())
	content_lines.append(str(bipob.get_overlay_effect_compact_text()))
	content_lines.append(str(bipob.get_overlay_thermal_contribution_compact_text()))
	content_lines.append(str(bipob.get_damage_planning_compact_text()))
	content_lines.append("Thermal rules: heat 1-5, critical 5, overlay hypothetical")
	content_lines.append(bipob.get_constructor_consistency_compact_text())
	content_lines.append("")
	content_lines.append("Filter: %s" % filter_id.capitalize())
	content_lines.append("Available / Installed:")
	if grouped_ids.is_empty():
		content_lines.append("empty")
	else:
		selected_grouped_module_index = clampi(selected_grouped_module_index, 0, grouped_ids.size() - 1)
		for i in range(grouped_ids.size()):
			content_lines.append(bipob.get_module_availability_line_by_id(grouped_ids[i], i == selected_grouped_module_index))
	content_lines.append("")
	var selected_module: BipobModule = get_selected_grouped_module()
	content_lines.append("Selected item:")
	content_lines.append(get_module_details_text(selected_module))
	return "\n".join(content_lines)

func get_box_external_menu_text() -> String:
	clamp_external_selection()
	sync_selected_box_storage_index_from_grouped_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var side_name: String = bipob.get_external_side_display_name(side_id)
	var slot_module: BipobModule = bipob.get_external_module_at(side_id, selected_external_slot_position)
	var content_lines: Array[String] = []

	var selected_box_module: BipobModule = get_selected_grouped_module()

	var placement_error := ""
	var preview_footprint: Array[Vector2i] = []
	var preview_safe_area: Array[Vector2i] = []
	if selected_box_module != null:
		preview_footprint = bipob.get_external_module_footprint_cells(selected_box_module, selected_external_slot_position)
		preview_safe_area = bipob.get_external_module_safe_area_cells(selected_box_module, selected_external_slot_position)
		placement_error = bipob.get_external_module_placement_error(selected_box_module, side_id, selected_external_slot_position)

	content_lines.append("Selected side: %s" % side_name)
	content_lines.append("Filter: %s" % get_current_constructor_filter().capitalize())
	content_lines.append(bipob.get_constructor_readiness_compact_text())
	content_lines.append("Side size: %d x %d" % [side_size.x, side_size.y])
	content_lines.append(get_external_side_orientation_text(side_id))
	content_lines.append("")

	var header_cells: Array[String] = ["   "]
	for x in range(side_size.x):
		header_cells.append("x%d" % x)
	content_lines.append("  ".join(header_cells))
	for y in range(side_size.y):
		var row_cells: Array[String] = ["y%d" % y]
		for x in range(side_size.x):
			var slot_pos := Vector2i(x, y)
			var module: BipobModule = bipob.get_external_module_at(side_id, slot_pos)
			var is_selected: bool = slot_pos == selected_external_slot_position
			var has_footprint_preview := selected_box_module != null and preview_footprint.has(slot_pos)
			var has_safe_preview := selected_box_module != null and preview_safe_area.has(slot_pos)
			var cell_text := "[ ]"
			if has_safe_preview:
				cell_text = "[.]" if module == null else "[x]"
			if module != null:
				cell_text = "[%s]" % get_external_module_marker(module)
			if has_footprint_preview:
				cell_text = "[+]" if module == null else "[!]"
			if is_selected and selected_box_module == null:
				cell_text = "[>]" if module == null else "[>%s]" % get_external_module_marker(module)
			row_cells.append(cell_text)
		content_lines.append(" ".join(row_cells))

	content_lines.append("")
	content_lines.append("Selected slot: x=%d, y=%d" % [selected_external_slot_position.x, selected_external_slot_position.y])
	if slot_module == null:
		content_lines.append("Slot status: empty")
	else:
		content_lines.append("Slot status: %s" % bipob.get_module_display_name(slot_module))

	if selected_box_module == null:
		content_lines.append("Selected Box module: none")
		content_lines.append("Module size: n/a")
		content_lines.append("Allowed sides: n/a")
		content_lines.append("Placement: n/a")
	else:
		var module_size: Vector2i = bipob.get_external_module_size(selected_box_module)
		content_lines.append("Selected Box module: %s" % bipob.get_module_display_name(selected_box_module))
		content_lines.append("Module size: %d x %d" % [module_size.x, module_size.y])
		content_lines.append("Allowed sides: %s" % bipob.get_allowed_external_sides_text(selected_box_module))
		if placement_error.is_empty():
			content_lines.append("Placement: valid")
		else:
			content_lines.append("Placement: invalid — %s" % placement_error)
		if selected_box_module.id == "air_intake_v1":
			content_lines.append("Purpose: supplies air to internal air cooling modules.")
			content_lines.append("Allowed sides: Any")
		if selected_box_module.placement_type != "external":
			content_lines.append("Cannot place: module is not external.")
		if bipob.get_box_module_count_by_id(selected_box_module.id) <= 0:
			content_lines.append("No available copy in Box Storage.")

	content_lines.append("")
	content_lines.append(get_module_details_text(selected_box_module))

	content_lines.append("")
	content_lines.append("Air intake requirement:")
	content_lines.append("- internal air cooling: %s" % get_yes_no(bipob.has_air_cooling_requiring_intake()))
	content_lines.append("- air intake installed: %s" % get_yes_no(bipob.has_external_air_intake()))
	if bipob.has_method("get_air_intake_warning_text"):
		var air_intake_warning: String = str(bipob.get_air_intake_warning_text())
		if not air_intake_warning.is_empty():
			content_lines.append(air_intake_warning)
	content_lines.append("")
	content_lines.append(bipob.get_constructor_warning_compact_text())
	var constructor_warnings: Array[String] = bipob.get_constructor_warning_lines()
	var warning_limit: int = mini(2, constructor_warnings.size())
	for index in range(warning_limit):
		content_lines.append("- %s" % constructor_warnings[index])
	content_lines.append("")
	content_lines.append("Installed on %s:" % side_name)
	content_lines.append(get_external_side_installed_list_text(side_id))
	content_lines.append("")
	content_lines.append(bipob.get_external_build_summary_text())

	return "\n".join(content_lines)

func _add_box_action_button(button_text: String, handler: Callable) -> void:
	if right_button_panel == null:
		return
	var button: Button = Button.new()
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_button_panel.add_child(button)
	button.pressed.connect(handler)

func _add_right_action_group(title: String) -> void:
	if right_button_panel == null:
		return
	var label: Label = Label.new()
	label.text = title
	right_button_panel.add_child(label)

func _add_right_action_button(text: String, callable_ref: Callable) -> void:
	_add_box_action_button(text, callable_ref)

func rebuild_box_action_buttons() -> void:
	if right_button_panel == null:
		return
	for child in right_button_panel.get_children():
		child.queue_free()

	var actions_label := Label.new()
	actions_label.name = "ActionsLabel"
	actions_label.text = "Actions"
	right_button_panel.add_child(actions_label)

	if box_menu_mode == BoxMenuMode.MISSION:
		_add_box_action_button("Charge", Callable(self, "_on_charge_button_pressed"))
		_add_box_action_button("Warnings", Callable(self, "_on_constructor_warnings_button_pressed"))
		_add_box_action_button("Start", Callable(self, "_on_start_mission_button_pressed"))
		_add_box_action_button("Restart", Callable(self, "_on_restart_mission_button_pressed"))
	elif box_menu_mode == BoxMenuMode.EXTERNAL:
		_add_box_action_button("Prev Filter", Callable(self, "_on_prev_constructor_filter_pressed"))
		_add_box_action_button("Next Filter", Callable(self, "_on_next_constructor_filter_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Prev Side", Callable(self, "_on_prev_external_side_pressed"))
		_add_box_action_button("Next Side", Callable(self, "_on_next_external_side_pressed"))
		_add_box_action_button("Prev Slot", Callable(self, "_on_prev_external_slot_pressed"))
		_add_box_action_button("Next Slot", Callable(self, "_on_next_external_slot_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Place", Callable(self, "_on_place_external_module_pressed"))
		_add_box_action_button("Remove", Callable(self, "_on_remove_external_module_pressed"))
		_add_box_action_button("Warnings", Callable(self, "_on_constructor_warnings_button_pressed"))
	elif box_menu_mode == BoxMenuMode.INTERNAL:
		_add_right_action_group("Selection")
		_add_right_action_button("Prev Filter", Callable(self, "_on_prev_constructor_filter_pressed"))
		_add_right_action_button("Next Filter", Callable(self, "_on_next_constructor_filter_pressed"))
		_add_right_action_button("Prev Box", Callable(self, "_on_prev_internal_box_pressed"))
		_add_right_action_button("Next Box", Callable(self, "_on_next_internal_box_pressed"))
		right_button_panel.add_spacer(false)
		_add_right_action_group("Position")
		_add_right_action_button("X-", Callable(self, "_on_internal_x_minus_pressed"))
		_add_right_action_button("X+", Callable(self, "_on_internal_x_plus_pressed"))
		_add_right_action_button("Y-", Callable(self, "_on_internal_y_minus_pressed"))
		_add_right_action_button("Y+", Callable(self, "_on_internal_y_plus_pressed"))
		_add_right_action_button("Z-", Callable(self, "_on_internal_z_minus_pressed"))
		_add_right_action_button("Z+", Callable(self, "_on_internal_z_plus_pressed"))
		right_button_panel.add_spacer(false)
		_add_right_action_group("Module")
		_add_right_action_button("Rotate", Callable(self, "_on_rotate_internal_pressed"))
		_add_right_action_button("Place", Callable(self, "_on_place_internal_pressed"))
		_add_right_action_button("Remove", Callable(self, "_on_remove_internal_pressed"))
		right_button_panel.add_spacer(false)
		_add_right_action_group("View")
		_add_right_action_button("Toggle View", Callable(self, "_on_toggle_internal_view_pressed"))
		right_button_panel.add_spacer(false)
		_add_right_action_group("Overlay Plan")
		_add_right_action_button("Type", Callable(self, "_on_overlay_type_pressed"))
		_add_right_action_button("Toggle Cell", Callable(self, "_on_toggle_overlay_cell_pressed"))
		_add_right_action_button("+X", Callable(self, "_on_extend_overlay_pos_x_pressed"))
		_add_right_action_button("-X", Callable(self, "_on_extend_overlay_neg_x_pressed"))
		_add_right_action_button("+Y", Callable(self, "_on_extend_overlay_pos_y_pressed"))
		_add_right_action_button("-Y", Callable(self, "_on_extend_overlay_neg_y_pressed"))
		_add_right_action_button("+Z", Callable(self, "_on_extend_overlay_pos_z_pressed"))
		_add_right_action_button("-Z", Callable(self, "_on_extend_overlay_neg_z_pressed"))
		_add_right_action_button("Undo", Callable(self, "_on_undo_overlay_cell_pressed"))
		_add_right_action_button("Clear", Callable(self, "_on_clear_overlay_pressed"))
		_add_right_action_button("Commit", Callable(self, "_on_commit_overlay_pressed"))
		right_button_panel.add_spacer(false)
		_add_right_action_group("Overlay Paths")
		_add_right_action_button("Prev Path", Callable(self, "_on_prev_overlay_pressed"))
		_add_right_action_button("Next Path", Callable(self, "_on_next_overlay_pressed"))
		_add_right_action_button("Remove Path", Callable(self, "_on_remove_selected_overlay_pressed"))
		right_button_panel.add_spacer(false)
		_add_right_action_group("Preview")
		_add_right_action_button("Check", Callable(self, "_on_overlay_check_pressed"))
		_add_right_action_button("Endpoints", Callable(self, "_on_overlay_endpoints_pressed"))
		_add_right_action_button("Thermal", Callable(self, "_on_overlay_thermal_pressed"))
		_add_right_action_button("Damage Plan", Callable(self, "_on_damage_plan_pressed"))
		_add_right_action_button("Rules", Callable(self, "_on_thermal_rules_pressed"))
		_add_right_action_button("Diff", Callable(self, "_on_overlay_effects_pressed"))
	else:
		_add_box_action_button("Prev Filter", Callable(self, "_on_prev_constructor_filter_pressed"))
		_add_box_action_button("Next Filter", Callable(self, "_on_next_constructor_filter_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Remove", Callable(self, "_on_remove_selected_module_pressed"))
		_add_box_action_button("Prev Inst", Callable(self, "_on_prev_installed_pressed"))
		_add_box_action_button("Next Inst", Callable(self, "_on_next_installed_pressed"))
		right_button_panel.add_spacer(false)
		_add_box_action_button("Install", Callable(self, "_on_install_selected_box_module_pressed"))
		_add_box_action_button("Prev Box", Callable(self, "_on_prev_box_pressed"))
		_add_box_action_button("Next Box", Callable(self, "_on_next_box_pressed"))
		_add_box_action_button("Consistency", Callable(self, "_on_constructor_consistency_button_pressed"))
		_add_box_action_button("Warnings", Callable(self, "_on_constructor_warnings_button_pressed"))
		_add_box_action_button("Dashboard", Callable(self, "_on_constructor_dashboard_button_pressed"))

func update_box_button_visibility() -> void:
	var is_mission := box_menu_mode == BoxMenuMode.MISSION
	var is_modules := box_menu_mode == BoxMenuMode.MODULES
	var is_external := box_menu_mode == BoxMenuMode.EXTERNAL
	var is_internal := box_menu_mode == BoxMenuMode.INTERNAL
	if mission_tab_button != null:
		mission_tab_button.disabled = is_mission
	if modules_tab_button != null:
		modules_tab_button.disabled = is_modules
	if external_tab_button != null:
		external_tab_button.disabled = is_external
	if internal_tab_button != null:
		internal_tab_button.disabled = is_internal

func set_box_menu_mode_mission() -> void:
	box_menu_mode = BoxMenuMode.MISSION
	update_box_status()
	rebuild_box_action_buttons()

func set_box_menu_mode_modules() -> void:
	box_menu_mode = BoxMenuMode.MODULES
	update_box_status()
	rebuild_box_action_buttons()

func set_box_menu_mode_external() -> void:
	box_menu_mode = BoxMenuMode.EXTERNAL
	clamp_external_selection()
	update_box_status()
	rebuild_box_action_buttons()


func set_box_menu_mode_internal() -> void:
	box_menu_mode = BoxMenuMode.INTERNAL
	update_box_status()
	rebuild_box_action_buttons()

func _get_internal_box_modules() -> Array[BipobModule]:
	if bipob == null:
		return []
	var modules: Array[BipobModule] = []
	var filtered_indices: Array[int] = get_filtered_internal_box_storage_indices(get_current_constructor_filter())
	for raw_index in filtered_indices:
		modules.append(bipob.box_storage[raw_index])
	return modules

func get_internal_role_display_name(role_id: String) -> String:
	match role_id:
		"battery":
			return "Battery"
		"power_block":
			return "Power Block"
		"internal_interface":
			return "Internal Interface"
		"external_interface":
			return "External Interface"
		"processor":
			return "Processor"
		"memory":
			return "Memory"
		"storage":
			return "Storage"
		"cooling":
			return "Cooling"
		_:
			return "None"

func get_internal_module_info_text(module: BipobModule) -> String:
	if module == null:
		return "Selected internal module: none"
	var base_size: Vector3i = bipob.get_internal_module_base_size(module)
	var lines: Array[String] = []
	lines.append("Selected internal module:")
	lines.append(bipob.get_module_display_name(module))
	lines.append("Size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
	lines.append("Role: %s" % get_internal_role_display_name(module.internal_role))
	lines.append("Placement: %s" % module.placement_type)
	if not module.description.is_empty():
		lines.append("Description: %s" % module.description)
	return "\n".join(lines)

func _clamp_internal_selection() -> void:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		bipob.selected_internal_box_index = 0
	else:
		bipob.selected_internal_box_index = clampi(bipob.selected_internal_box_index, 0, modules.size() - 1)
	bipob.selected_internal_rotation = posmod(bipob.selected_internal_rotation, 3)
	var v: Vector3i = bipob.get_internal_volume_size()
	bipob.selected_internal_origin.x = clampi(bipob.selected_internal_origin.x, 0, v.x - 1)
	bipob.selected_internal_origin.y = clampi(bipob.selected_internal_origin.y, 0, v.y - 1)
	bipob.selected_internal_origin.z = clampi(bipob.selected_internal_origin.z, 0, v.z - 1)

func _get_selected_internal_module() -> BipobModule:
	var modules := _get_internal_box_modules()
	if modules.is_empty():
		return null
	_clamp_internal_selection()
	return modules[bipob.selected_internal_box_index]

func get_internal_module_marker(module: BipobModule) -> String:
	if module == null:
		return "X"
	match module.internal_role:
		"battery":
			return "B"
		"processor":
			return "P"
		"external_interface":
			return "E"
		"internal_interface":
			return "I"
		"memory":
			return "M"
		"power_block":
			return "W"
		"storage":
			return "H"
		_:
			return "X"

func _build_internal_axis_header(prefix: String, count: int) -> String:
	var labels: Array[String] = []
	for i in range(count):
		labels.append("%s%d" % [prefix, i])
	return "    %s" % " ".join(labels)


func _get_internal_view_mode_display_name() -> String:
	match internal_view_mode:
		"modules":
			return "Modules"
		"thermal":
			return "Thermal"
		"overlay":
			return "Overlay"
		"thermal_overlay":
			return "Thermal+Overlay"
		_:
			return String(internal_view_mode)

func _get_internal_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	if internal_view_mode == "thermal":
		return _get_internal_thermal_cell_marker(cell, preview_cells_map, can_place)
	if internal_view_mode == "overlay":
		return _get_internal_overlay_cell_marker(cell, preview_cells_map, can_place)
	if internal_view_mode == "thermal_overlay":
		return _get_internal_thermal_overlay_cell_marker(cell, preview_cells_map, can_place)
	return _get_internal_module_cell_marker(cell, preview_cells_map, can_place)

func _get_internal_module_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied: bool = occupied_module != null
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if is_origin and is_occupied:
		return "[>%s]" % get_internal_module_marker(occupied_module)
	if is_origin:
		return "[>]"
	if is_occupied:
		return "[%s]" % get_internal_module_marker(occupied_module)
	if not overlay_marker.is_empty():
		return "[%s]" % overlay_marker
	return "[ ]"

func _get_internal_thermal_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied: bool = occupied_module != null
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if is_occupied:
		var heat: int = bipob.get_preview_heat_after_cooling_for_internal_module(occupied_module)
		heat = clampi(heat, 0, 5)
		return "[>%d]" % heat if is_origin else "[%d]" % heat
	if is_origin:
		return "[>]"
	if not overlay_marker.is_empty():
		return "[%s]" % overlay_marker
	return "[ ]"

func _get_internal_thermal_overlay_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if occupied_module != null:
		var heat: int = bipob.get_hypothetical_heat_after_overlay_for_module(occupied_module)
		heat = clampi(heat, 0, 5)
		if is_origin:
			return "[>%d]" % heat
		return "[%d]" % heat
	if not overlay_marker.is_empty():
		if is_origin:
			return "[>%s]" % overlay_marker
		return "[%s]" % overlay_marker
	if is_origin:
		return "[>]"
	return "[ ]"

func _get_internal_background_module_marker(module: BipobModule) -> String:
	if module == null:
		return " "
	var marker: String = get_internal_module_marker(module)
	return marker.to_lower()

func _get_internal_overlay_cell_marker(cell: Vector3i, preview_cells_map: Dictionary, can_place: bool) -> String:
	var is_origin: bool = cell == bipob.selected_internal_origin
	var overlay_marker: String = bipob.get_internal_overlay_marker_for_cell(cell)
	var occupied_module: BipobModule = bipob.get_internal_module_at_cell(cell)
	var is_occupied: bool = occupied_module != null
	var in_preview: bool = preview_cells_map.has(bipob.get_internal_slot_key(cell))
	if not overlay_marker.is_empty():
		return "[>%s]" % overlay_marker if is_origin else "[%s]" % overlay_marker
	if in_preview:
		if can_place:
			return "[>*]" if is_origin else "[*]"
		return "[>!]" if is_origin else "[!]"
	if is_occupied:
		var background_marker: String = _get_internal_background_module_marker(occupied_module)
		return "[>%s]" % background_marker if is_origin else "[%s]" % background_marker
	if is_origin:
		return "[>]"
	return "[ ]"

func get_air_intake_status_text() -> String:
	if bipob == null:
		return "unknown"
	if bipob.has_method("get_air_intake_status_text"):
		return str(bipob.get_air_intake_status_text())
	return "unknown"

func _on_prev_external_side_pressed() -> void:
	if bipob == null:
		return
	selected_external_side_index -= 1
	clamp_external_selection()
	update_box_status()

func _on_next_external_side_pressed() -> void:
	if bipob == null:
		return
	selected_external_side_index += 1
	clamp_external_selection()
	update_box_status()

func _move_external_slot_by(delta: int) -> void:
	if bipob == null:
		return
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	var side_size: Vector2i = bipob.get_external_side_size(side_id)
	var width := side_size.x
	var total_slots := width * side_size.y
	if total_slots <= 0:
		return
	var index := selected_external_slot_position.y * width + selected_external_slot_position.x
	index = (index + delta) % total_slots
	if index < 0:
		index += total_slots
	selected_external_slot_position.x = index % width
	selected_external_slot_position.y = int(index / width)

func _on_prev_external_slot_pressed() -> void:
	_move_external_slot_by(-1)
	update_box_status()

func _on_next_external_slot_pressed() -> void:
	_move_external_slot_by(1)
	update_box_status()

func _on_place_external_module_pressed() -> void:
	if bipob == null:
		return
	sync_selected_box_storage_index_from_grouped_selection()
	clamp_external_selection()
	var selected_module: BipobModule = get_selected_grouped_module()
	if selected_module == null:
		show_hint("No module matches current filter.")
		return
	if bipob.get_box_module_count_by_id(selected_module.id) <= 0:
		show_hint("No available copy in Box Storage.")
		return
	if selected_box_storage_index < 0:
		show_hint("No available copy in Box Storage.")
		return
	var side_id := get_selected_external_side_id()
	if bipob.place_external_module_from_box_storage(
		selected_box_storage_index,
		side_id,
		selected_external_slot_position
	):
		clamp_box_selection_indexes()
		clamp_external_selection()
		update_box_status()

func _on_remove_external_module_pressed() -> void:
	if bipob == null:
		return
	clamp_external_selection()
	var side_id := get_selected_external_side_id()
	if bipob.remove_external_module_to_box_storage(side_id, selected_external_slot_position):
		clamp_box_selection_indexes()
		update_box_status()

func show_hint(message: String) -> void:
	if hint_label != null:
		hint_label.text = message


func _on_constructor_dashboard_button_pressed() -> void:
	if bipob == null:
		return
	show_hint(bipob.get_constructor_dashboard_text())

func _on_constructor_warnings_button_pressed() -> void:
	if bipob == null:
		return
	show_hint(bipob.get_constructor_warning_summary_text())
	update_box_status()

func _on_constructor_consistency_button_pressed() -> void:
	if bipob == null:
		return
	show_hint(bipob.get_constructor_consistency_summary_text())
	update_box_status()

func _on_move_forward_pressed() -> void:
	bipob.move_forward()
	update_status()

func _on_move_backward_pressed() -> void:
	bipob.move_backward()
	update_status()

func _on_turn_left_pressed() -> void:
	bipob.turn_left()
	update_status()

func _on_turn_right_pressed() -> void:
	bipob.turn_right()
	update_status()

func _on_interact_pressed() -> void:
	bipob.interact()
	update_status()

func _on_drop_item_button_pressed() -> void:
	bipob.drop_held_item()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_rotate_storage_button_pressed() -> void:
	bipob.rotate_physical_storage()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_scan_device_button_pressed() -> void:
	bipob.scan_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_hack_device_button_pressed() -> void:
	bipob.hack_device()
	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_end_turn_pressed() -> void:
	bipob.end_turn()
	update_status()

func _on_restart_mission_button_pressed() -> void:
	if bipob == null:
		return

	# Mission reset action: should not spend field action points or energy as button press.
	bipob.restart_current_mission()
	if box_screen != null and box_screen.visible:
		hide_box_screen()
	else:
		if command_panel != null:
			command_panel.visible = true

	update_status()
	update_diagnostic_status()
	update_box_status()

func _on_return_to_box_button_pressed() -> void:
	if bipob == null:
		return
	bipob.return_to_box()
	if box_screen != null and not box_screen.visible:
		show_box_screen()
	update_status()
	update_box_status()
	update_diagnostic_status()

func update_status() -> void:
	if bipob == null:
		return

	var key_text := "no"
	if bipob.has_key:
		key_text = "yes"

	var info_key_text := "no"
	if bipob.has_info_key:
		info_key_text = "yes"
	var held_text := "empty"
	if bipob.held_module != null:
		held_text = bipob.get_module_display_name(bipob.held_module)
	elif bipob.current_mission_index == 7 and bipob.mission7_is_dragging_cable:
		held_text = "Cable End"
	var storage_text := "empty"
	if bipob.stored_physical_module != null:
		storage_text = bipob.get_module_display_name(bipob.stored_physical_module)

	if status_label == null:
		return

	status_label.text = "Energy: %d / %d | Actions: %d / %d | Key: %s | Info-Key: %s | Hand: %s | Storage: %s" % [
		bipob.energy,
		bipob.max_energy,
		bipob.actions_left,
		bipob.actions_per_turn,
		key_text,
		info_key_text,
		held_text,
		storage_text
	]
	status_label.text += " | Carry: %d / %d" % [
		bipob.get_carried_physical_count(),
		bipob.physical_carry_capacity
	]
	var digital_storage_short_text := "empty"
	if bipob.has_method("get_digital_storage_short_text"):
		digital_storage_short_text = str(bipob.get_digital_storage_short_text())
	elif bipob.has_method("get_digital_storage_text"):
		var full_storage_text := str(bipob.get_digital_storage_text())
		if full_storage_text.begins_with("Digital storage: "):
			digital_storage_short_text = full_storage_text.trim_prefix("Digital storage: ")
		elif full_storage_text.begins_with("Digital storage:\n- "):
			digital_storage_short_text = full_storage_text.trim_prefix("Digital storage:\n- ").replace("\n- ", ", ")
		elif not full_storage_text.is_empty():
			digital_storage_short_text = full_storage_text
	status_label.text += " | Data: %s" % digital_storage_short_text
	if bipob.has_method("get_mission8_airflow_status_text"):
		var mission8_status := str(bipob.get_mission8_airflow_status_text())
		if not mission8_status.is_empty():
			status_label.text += " | %s" % mission8_status
	if bipob.current_mission_index == 7 and bipob.has_method("get_mission7_cable_status_text"):
		status_label.text += " | %s" % str(bipob.get_mission7_cable_status_text())


func update_diagnostic_status() -> void:
	if bipob == null:
		return

	if diagnostic_label == null:
		return

	var result = bipob.last_diagnostic_result
	if result == null:
		diagnostic_label.text = "Diagnostic: none"
		return

	var device_name: String = str(result.device_name)

	if device_name.is_empty():
		device_name = "unknown"

	var status_text: String = str(result.get_status_text())

	if status_text.is_empty():
		status_text = "UNKNOWN"

	var supported_action: String = str(result.supported_action)
	if supported_action.is_empty():
		supported_action = "none"

	var reason: String = str(result.reason)
	if reason.is_empty():
		reason = "n/a"

	var recommendation: String = str(result.recommendation)
	if recommendation.is_empty():
		recommendation = "n/a"

	var estimated_risk: String = str(result.estimated_risk)
	if estimated_risk.is_empty():
		estimated_risk = "n/a"

	diagnostic_label.text = "Diagnostic:\nDevice: %s\nStatus: %s\nAction: %s\nReason: %s\nRecommendation: %s\nRisk: %s" % [
		device_name,
		status_text,
		supported_action,
		reason,
		recommendation,
		estimated_risk
	]


func _section_title(title: String) -> String:
	return "== %s ==" % title

func _subsection_title(title: String) -> String:
	return "-- %s --" % title

func _empty_line(lines: Array[String]) -> void:
	lines.append("")

func _get_internal_view_legend_text() -> String:
	if internal_view_mode == "thermal":
		return "[1-5] base preview heat after normal cooling, [5] critical preview"
	if internal_view_mode == "overlay":
		return "[L] selected liquid, [A] selected duct, [l] liquid path, [a] duct path"
	if internal_view_mode == "thermal_overlay":
		return "[1-5] hypothetical heat, [l/a] overlay, [*] preview, [!] invalid"
	return "[ ] empty, [>] origin, [*] preview, [!] invalid, [B/P/E/I/M/W/H] modules"

func get_box_internal_menu_text() -> String:
	_clamp_internal_selection()
	sync_selected_box_storage_index_from_filter()
	var selected_module: BipobModule = _get_selected_internal_module()
	var preview_cells: Array[Vector3i] = []
	var preview_cells_map: Dictionary = {}
	var reason: String = "No internal module selected."
	var can_place: bool = false
	var placement_size: Vector3i = Vector3i.ZERO
	var base_size: Vector3i = Vector3i.ZERO
	var selected_cell_module: BipobModule = bipob.get_internal_module_at_cell(bipob.selected_internal_origin)
	var selected_module_id: String = ""
	var is_overlay_module: bool = false
	if selected_module != null:
		selected_module_id = selected_module.id
		is_overlay_module = selected_module_id == "water_tube_v1" or selected_module_id == "air_duct_v1"
		base_size = selected_module.internal_size
		placement_size = bipob.get_rotated_internal_size(selected_module, bipob.selected_internal_rotation)
		preview_cells = bipob.get_internal_module_covered_cells(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
		for cell in preview_cells:
			preview_cells_map[bipob.get_internal_slot_key(cell)] = true
		reason = bipob.get_internal_module_placement_error(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation)
		can_place = reason.is_empty()
	if can_place:
		reason = "OK"

	var lines: Array[String] = []
	var volume_size: Vector3i = bipob.get_internal_volume_size()
	var overlay_count: int = bipob.internal_overlay_paths.size()
	lines.append(_section_title("Internal Constructor"))
	lines.append("View mode: %s" % _get_internal_view_mode_display_name())
	lines.append("Filter: %s" % get_current_constructor_filter().capitalize())
	lines.append("Cursor: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
	lines.append("Volume: %d×%d×%d" % [volume_size.x, volume_size.y, volume_size.z])
	lines.append("Right panel groups: Selection / Position / Module / View / Overlay")
	_empty_line(lines)

	lines.append(_section_title("Selected Module"))
	if selected_module == null:
		lines.append("Selected: none")
		lines.append("Hint: No module matches current filter.")
	else:
		lines.append("Selected: %s" % bipob.get_module_display_name(selected_module))
		var box_count: int = bipob.get_box_module_count_by_id(selected_module.id)
		var overlay_available: int = 0
		lines.append("Availability: box %d / overlay %d / total %d" % [box_count, overlay_available, box_count + overlay_available])
		lines.append("Placement: %s" % selected_module.placement_type)
		if selected_module.placement_type != "internal" and not is_overlay_module:
			lines.append("Hint: Cannot place in internal volume.")
		elif is_overlay_module:
			lines.append("Hint: Use Overlay Plan actions, not Place Internal.")
		lines.append("Category: %s" % bipob.get_module_category(selected_module))
		lines.append("Size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
		lines.append("Role: %s" % selected_module.role)
		lines.append("Heat: %d / %d" % [selected_module.heat_output, selected_module.heat_limit])
		lines.append("Cooling: %s %d" % [selected_module.cooling_type, selected_module.cooling_power])
		lines.append("Air intake: %s" % ("required" if selected_module.requires_air_intake else "not required"))
	_empty_line(lines)

	lines.append(_section_title("Placement"))
	lines.append("Origin: %d,%d,%d" % [bipob.selected_internal_origin.x, bipob.selected_internal_origin.y, bipob.selected_internal_origin.z])
	lines.append("Rotation: %d" % bipob.selected_internal_rotation)
	lines.append("Base size: %d×%d×%d" % [base_size.x, base_size.y, base_size.z])
	lines.append("Rotated size: %d×%d×%d" % [placement_size.x, placement_size.y, placement_size.z])
	if is_overlay_module:
		lines.append("Overlay path module: use Commit Plan.")
	else:
		lines.append("Valid: %s" % get_yes_no(can_place))
		lines.append("Reason: %s" % reason)
	lines.append("Selected cell: %s" % ("empty" if selected_cell_module == null else "occupied by %s" % bipob.get_module_display_name(selected_cell_module)))
	_empty_line(lines)

	lines.append(_section_title("Status"))
	lines.append("Power: %s" % ("available" if bipob.is_virtual_power_available() else "unavailable"))
	lines.append("Internal data: %s" % ("available" if bipob.is_internal_data_network_available() else "unavailable"))
	lines.append("External data: %s" % ("available" if bipob.is_external_data_network_available() else "unavailable"))
	lines.append("Air intake: %s" % get_air_intake_status_text())
	lines.append("Warnings: %d" % bipob.get_constructor_warning_lines().size())
	var highest_heat: int = bipob.get_highest_internal_preview_heat()
	var critical_count: int = bipob.get_critical_internal_preview_count()
	var thermal_status: String = "ok"
	if critical_count > 0:
		thermal_status = "critical preview"
	elif bipob.get_warning_level() == "warning":
		thermal_status = "warning"
	lines.append("Thermal: %s" % thermal_status)
	var consistency_issue_count: int = bipob.get_constructor_consistency_issue_lines().size()
	lines.append("Consistency: %s" % ("OK" if consistency_issue_count <= 0 else "%d issue(s)" % consistency_issue_count))
	_empty_line(lines)

	lines.append(_section_title("Views"))
	lines.append("Legend: %s" % _get_internal_view_legend_text())
	lines.append("Front view — X/Y at Z=%d" % bipob.selected_internal_origin.z)
	lines.append(_build_internal_axis_header("x", volume_size.x))
	for y in range(volume_size.y):
		var front_row: Array[String] = []
		for x in range(volume_size.x):
			var front_cell: Vector3i = Vector3i(x, y, bipob.selected_internal_origin.z)
			front_row.append(_get_internal_cell_marker(front_cell, preview_cells_map, can_place))
		lines.append("y%d %s" % [y, " ".join(front_row)])
	_empty_line(lines)
	lines.append("Vertical slice — Z/Y at X=%d" % bipob.selected_internal_origin.x)
	lines.append(_build_internal_axis_header("z", volume_size.z))
	for y in range(volume_size.y):
		var vertical_row: Array[String] = []
		for z in range(volume_size.z):
			var vertical_cell: Vector3i = Vector3i(bipob.selected_internal_origin.x, y, z)
			vertical_row.append(_get_internal_cell_marker(vertical_cell, preview_cells_map, can_place))
		lines.append("y%d %s" % [y, " ".join(vertical_row)])
	_empty_line(lines)
	lines.append("Horizontal slice — X/Z at Y=%d" % bipob.selected_internal_origin.y)
	lines.append(_build_internal_axis_header("x", volume_size.x))
	for z in range(volume_size.z):
		var horizontal_row: Array[String] = []
		for x in range(volume_size.x):
			var horizontal_cell: Vector3i = Vector3i(x, bipob.selected_internal_origin.y, z)
			horizontal_row.append(_get_internal_cell_marker(horizontal_cell, preview_cells_map, can_place))
		lines.append("z%d %s" % [z, " ".join(horizontal_row)])
	_empty_line(lines)

	lines.append(_section_title("Overlay Planning"))
	lines.append("Type: %s" % bipob.selected_overlay_path_type)
	lines.append("Planning cells: %d" % bipob.selected_overlay_cells.size())
	lines.append(str(bipob.get_selected_overlay_plan_short_text()))
	lines.append(str(bipob.get_overlay_connectivity_compact_text()))
	lines.append(str(bipob.get_overlay_endpoint_compact_text()))
	var required_overlay_module_id: String = bipob.get_selected_overlay_module_id()
	lines.append("Required module: %s" % required_overlay_module_id)
	lines.append("Available in box: %d" % bipob.get_box_module_count_by_id(required_overlay_module_id))
	_empty_line(lines)

	lines.append(_section_title("Selected Overlay Path"))
	if overlay_count <= 0:
		lines.append("Selected overlay path: none")
	else:
		bipob.clamp_selected_overlay_path_index()
		var selected_overlay_record: Dictionary = bipob.get_selected_overlay_path_record()
		lines.append("Selected path: %d / %d" % [bipob.selected_overlay_path_index + 1, overlay_count])
		lines.append("ID: %s" % str(selected_overlay_record.get("id", "overlay_%d" % (bipob.selected_overlay_path_index + 1))))
		lines.append("Type: %s" % str(selected_overlay_record.get("path_type", "unknown")))
		var selected_overlay_cells: Array = selected_overlay_record.get("cells", [])
		lines.append("Cells: %d" % selected_overlay_cells.size())
		lines.append("Connected: %s" % ("yes" if bool(selected_overlay_record.get("connected", false)) else "no"))
		lines.append("Components: %d" % int(selected_overlay_record.get("component_count", 0)))
		lines.append("Endpoints: %d" % int(selected_overlay_record.get("endpoint_count", 0)))
		lines.append("Suitability: %s" % str(selected_overlay_record.get("suitability", "unknown")))
	_empty_line(lines)

	lines.append(_section_title("Thermal Preview"))
	lines.append("Highest heat: %d / %d" % [highest_heat, bipob.THERMAL_CRITICAL_HEAT])
	lines.append("Critical preview: %d" % critical_count)
	lines.append(str(bipob.get_damage_planning_compact_text()))
	lines.append("Overlay thermal: %s" % str(bipob.get_overlay_thermal_contribution_compact_text()))
	lines.append("Overlay diff: %s" % str(bipob.get_overlay_thermal_contribution_diff_summary_text()))
	lines.append("Thermal rules: heat 1-5, critical 5, overlay hypothetical")
	lines.append("Base thermal remains unchanged.")
	_empty_line(lines)

	lines.append(_section_title("Placed Internal Modules"))
	if bipob.placed_internal_modules.is_empty():
		lines.append("none")
	else:
		var display_limit: int = mini(8, bipob.placed_internal_modules.size())
		for i in range(display_limit):
			var record: Dictionary = bipob.placed_internal_modules[i]
			var placed_module: BipobModule = record.get("module", null)
			if placed_module == null:
				continue
			var origin: Vector3i = record.get("origin", Vector3i.ZERO)
			var rotation_index: int = int(record.get("rotation", 0))
			var size: Vector3i = bipob.get_rotated_internal_size(placed_module, rotation_index)
			lines.append("- %s at %d,%d,%d size %d×%d×%d rot %d" % [bipob.get_module_display_name(placed_module), origin.x, origin.y, origin.z, size.x, size.y, size.z, rotation_index])
		if bipob.placed_internal_modules.size() > display_limit:
			lines.append("...and %d more" % (bipob.placed_internal_modules.size() - display_limit))

	return "\n".join(lines)

func _move_internal_cursor(dx: int, dy: int, dz: int) -> void:
	var v: Vector3i = bipob.get_internal_volume_size()
	bipob.selected_internal_origin.x = clampi(bipob.selected_internal_origin.x + dx, 0, v.x - 1)
	bipob.selected_internal_origin.y = clampi(bipob.selected_internal_origin.y + dy, 0, v.y - 1)
	bipob.selected_internal_origin.z = clampi(bipob.selected_internal_origin.z + dz, 0, v.z - 1)
	update_box_status()

func _on_prev_internal_box_pressed() -> void:
	_on_prev_box_pressed()

func _on_next_internal_box_pressed() -> void:
	_on_next_box_pressed()

func _on_prev_constructor_filter_pressed() -> void:
	constructor_filter_index -= 1
	if constructor_filter_index < 0:
		constructor_filter_index = CONSTRUCTOR_FILTERS.size() - 1
	clamp_box_selection_indexes()
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, maxi(get_filtered_grouped_module_ids().size() - 1, 0))
	sync_selected_box_storage_index_from_grouped_selection()
	update_box_status()

func _on_next_constructor_filter_pressed() -> void:
	constructor_filter_index += 1
	if constructor_filter_index >= CONSTRUCTOR_FILTERS.size():
		constructor_filter_index = 0
	clamp_box_selection_indexes()
	selected_grouped_module_index = clampi(selected_grouped_module_index, 0, maxi(get_filtered_grouped_module_ids().size() - 1, 0))
	sync_selected_box_storage_index_from_grouped_selection()
	update_box_status()

func _on_internal_x_minus_pressed() -> void: _move_internal_cursor(-1, 0, 0)
func _on_internal_x_plus_pressed() -> void: _move_internal_cursor(1, 0, 0)
func _on_internal_y_minus_pressed() -> void: _move_internal_cursor(0, -1, 0)
func _on_internal_y_plus_pressed() -> void: _move_internal_cursor(0, 1, 0)
func _on_internal_z_minus_pressed() -> void: _move_internal_cursor(0, 0, -1)
func _on_internal_z_plus_pressed() -> void: _move_internal_cursor(0, 0, 1)
func _on_rotate_internal_pressed() -> void:
	bipob.selected_internal_rotation = posmod(bipob.selected_internal_rotation + 1, 3)
	update_box_status()
func _on_place_internal_pressed() -> void:
	var selected_module: BipobModule = get_selected_grouped_module()
	if selected_module == null:
		show_hint("No module matches current filter.")
		return
	if bipob.get_box_module_count_by_id(selected_module.id) <= 0:
		show_hint("No available copy in Box Storage.")
		return
	sync_selected_box_storage_index_from_grouped_selection()
	if selected_box_storage_index < 0:
		show_hint("No available copy in Box Storage.")
		return
	if bipob.place_internal_module(selected_module, bipob.selected_internal_origin, bipob.selected_internal_rotation):
		update_box_status()
func _on_remove_internal_pressed() -> void:
	if bipob.remove_internal_module(bipob.selected_internal_origin):
		update_box_status()

func _on_toggle_internal_view_pressed() -> void:
	if internal_view_mode == "modules":
		internal_view_mode = "thermal"
	elif internal_view_mode == "thermal":
		internal_view_mode = "overlay"
	elif internal_view_mode == "overlay":
		internal_view_mode = "thermal_overlay"
	else:
		internal_view_mode = "modules"
	update_box_status()
func _on_reset_internal_cursor_pressed() -> void:
	bipob.selected_internal_origin = Vector3i.ZERO
	bipob.selected_internal_rotation = 0
	update_box_status()


func _on_overlay_type_pressed() -> void:
	bipob.selected_overlay_path_type = "duct" if bipob.selected_overlay_path_type == "liquid" else "liquid"
	update_box_status()

func _on_toggle_overlay_cell_pressed() -> void:
	bipob.toggle_selected_overlay_cell(bipob.selected_internal_origin)
	update_box_status()

func _on_extend_overlay_pos_x_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("+x")
	if not ok:
		show_hint("Cannot extend overlay +X.")
	update_box_status()

func _on_extend_overlay_neg_x_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("-x")
	if not ok:
		show_hint("Cannot extend overlay -X.")
	update_box_status()

func _on_extend_overlay_pos_y_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("+y")
	if not ok:
		show_hint("Cannot extend overlay +Y.")
	update_box_status()

func _on_extend_overlay_neg_y_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("-y")
	if not ok:
		show_hint("Cannot extend overlay -Y.")
	update_box_status()

func _on_extend_overlay_pos_z_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("+z")
	if not ok:
		show_hint("Cannot extend overlay +Z.")
	update_box_status()

func _on_extend_overlay_neg_z_pressed() -> void:
	var ok: bool = bipob.extend_selected_overlay_path("-z")
	if not ok:
		show_hint("Cannot extend overlay -Z.")
	update_box_status()

func _on_undo_overlay_cell_pressed() -> void:
	var ok: bool = bipob.undo_selected_overlay_cell()
	if not ok:
		show_hint("No overlay cell to undo.")
	update_box_status()

func _on_commit_overlay_pressed() -> void:
	if bipob.commit_selected_overlay_path():
		update_box_status()
		return
	if bipob.get_selected_overlay_module_id() == "air_duct_v1":
		show_hint("No Air Duct V1 in Box Storage.")
	else:
		show_hint("No Water Tube V1 in Box Storage.")
	update_box_status()

func _on_clear_overlay_pressed() -> void:
	bipob.clear_selected_overlay_cells()
	update_box_status()

func _on_overlay_effects_pressed() -> void:
	show_hint(str(bipob.get_overlay_effect_preview_text()))
	update_box_status()

func _on_overlay_check_pressed() -> void:
	show_hint(str(bipob.get_overlay_connectivity_preview_text()))
	update_box_status()

func _on_overlay_endpoints_pressed() -> void:
	show_hint(str(bipob.get_overlay_endpoint_preview_text()))
	update_box_status()

func _on_overlay_thermal_pressed() -> void:
	show_hint(str(bipob.get_overlay_thermal_contribution_preview_text()))
	update_box_status()

func _on_thermal_rules_pressed() -> void:
	show_hint(str(bipob.get_thermal_rules_reference_text()))
	update_box_status()

func _on_damage_plan_pressed() -> void:
	show_hint(str(bipob.get_damage_planning_preview_text()))
	update_box_status()

func _on_prev_overlay_pressed() -> void:
	bipob.select_prev_overlay_path()
	update_box_status()

func _on_next_overlay_pressed() -> void:
	bipob.select_next_overlay_path()
	update_box_status()

func _on_remove_selected_overlay_pressed() -> void:
	var removed: bool = bipob.remove_selected_overlay_path()
	if not removed:
		show_hint("No overlay path selected.")
	update_box_status()
