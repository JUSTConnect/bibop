extends Node
class_name RuntimeWorldActionMenuSections

const PANEL_NAME := "RuntimeWorldActionsPanel"
const SECTION_PREFIX := "RuntimeWorldActionsSection"
const SCAN_INTERVAL := 0.35

const SECTION_COLOR := Color(0.520, 0.650, 0.690, 1.0)
const LINE_COLOR := Color(0.120, 0.220, 0.280, 0.85)

var _scan_timer: float = 0.0

func _ready() -> void:
	_scan_for_world_action_panels()
	if get_tree() != null and not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)


func _process(delta: float) -> void:
	_scan_timer -= delta
	if _scan_timer <= 0.0:
		_scan_timer = SCAN_INTERVAL
		_scan_for_world_action_panels()


func _on_tree_node_added(node: Node) -> void:
	if node != null and node.name == PANEL_NAME:
		call_deferred("_decorate_world_action_panel", node)


func _scan_for_world_action_panels() -> void:
	if get_tree() == null or get_tree().root == null:
		return
	_scan_node(get_tree().root)


func _scan_node(node: Node) -> void:
	if node == null:
		return
	if node.name == PANEL_NAME:
		_decorate_world_action_panel(node)
	for child in node.get_children():
		_scan_node(child)


func _decorate_world_action_panel(panel: Node) -> void:
	if panel == null or not is_instance_valid(panel):
		return
	var root: VBoxContainer = _find_first_vbox(panel)
	if root == null or not is_instance_valid(root):
		return
	if bool(root.get_meta("runtime_world_action_sections_decorated", false)):
		return

	var title_label: Label = _find_label_with_text(root, "Actions")
	var target_label: Label = null
	var state_label: Label = null
	var behavior_label: Label = null
	var past_title: bool = title_label == null

	for child in root.get_children():
		if _is_section_node(child):
			continue
		if child == title_label:
			past_title = true
			continue
		if not past_title:
			continue
		if child is Label:
			if target_label == null:
				target_label = child as Label
			elif state_label == null:
				state_label = child as Label
			elif behavior_label == null:
				behavior_label = child as Label
				break

	var actions_scroll: ScrollContainer = _find_first_direct_scroll(root)

	if target_label != null:
		_insert_section_before(root, target_label, "TARGET", "RuntimeWorldActionsSectionTarget")
	if state_label != null:
		_insert_section_before(root, state_label, "STATUS", "RuntimeWorldActionsSectionStatus")
	if actions_scroll != null:
		_insert_section_before(root, actions_scroll, "ACTIONS", "RuntimeWorldActionsSectionActions")

	root.set_meta("runtime_world_action_sections_decorated", true)


func _find_first_vbox(node: Node) -> VBoxContainer:
	if node is VBoxContainer:
		return node as VBoxContainer
	for child in node.get_children():
		var result: VBoxContainer = _find_first_vbox(child)
		if result != null:
			return result
	return null


func _find_label_with_text(root: Node, text: String) -> Label:
	for child in root.get_children():
		if child is Label and str((child as Label).text).strip_edges() == text:
			return child as Label
	return null


func _find_first_direct_scroll(root: Node) -> ScrollContainer:
	for child in root.get_children():
		if child is ScrollContainer:
			return child as ScrollContainer
	return null


func _insert_section_before(root: BoxContainer, target: Control, title: String, node_name: String) -> void:
	if root == null or target == null:
		return
	if root.get_node_or_null(node_name) != null:
		return
	var target_index: int = target.get_index()
	var section := VBoxContainer.new()
	section.name = node_name
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 2)

	var line := HSeparator.new()
	line.name = "%sLine" % node_name
	line.custom_minimum_size = Vector2(0.0, 8.0)
	line.add_theme_color_override("separator", LINE_COLOR)
	section.add_child(line)

	var label := Label.new()
	label.name = "%sTitle" % node_name
	label.text = title
	label.add_theme_color_override("font_color", SECTION_COLOR)
	section.add_child(label)

	root.add_child(section)
	root.move_child(section, target_index)


func _is_section_node(node: Node) -> bool:
	return node != null and str(node.name).begins_with(SECTION_PREFIX)
