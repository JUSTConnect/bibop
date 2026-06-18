extends RefCounted

# Target class: PalettePanelBuilder
# Builds palette from ObjectDefinitionCatalog and ItemDefinitionCatalog.

static func build_palette(definitions: Array) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = "PalettePanel"
	var grid := GridContainer.new()
	grid.columns = 4
	panel.add_child(grid)
	for definition in definitions:
		var button := Button.new()
		button.text = str(Dictionary(definition).get("display_name", Dictionary(definition).get("id", "Object")))
		grid.add_child(button)
	return panel
