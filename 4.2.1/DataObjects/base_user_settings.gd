## Base class for managing user settings. Singleton advised
class_name BaseUserSettings
extends Popup


## Emitted when a checkbox associated with [param setting] is toggled
signal checkbox_toggled(setting: String, toggled_on: bool)

## File path for save data
@export var save_path: String = "user://settings.cfg"

var _save_file = ConfigFile.new()


# @PRIVATE
func _ready() -> void:
	
	if OS.is_debug_build():
		Input.joy_connection_changed.connect(_on_Input_joy_connection_changed)
	## default setting values
	for sett:String in get_setting_list():
		load_setting(sett, false)
	popup_hide.connect(hide)
	hide()


# @PRIVATE
func _on_CheckBox_toggled(toggle_on: bool, setting: String) -> void:
	
	update_setting(toggle_on, setting)
	checkbox_toggled.emit(setting, toggle_on)


# @PRIVATE
func _on_Input_joy_connection_changed(_device: int, _connected: bool) -> void:
	prints("[Info] Currently connected gamepads:", Input.get_connected_joypads())


# @PRIVATE
func _on_Popup_popup_hide() -> void:
	# stops input when closing user settings
	return


## Updates focus mode for all buttons that are ancestor of [param node]
func check_gamepad(node: Node, focus_first:bool=false) -> void:
	
	if not gamepad_connected():
		return
	var focus_grabbed = not focus_first
	for ch:Node in [node] + U.get_children_recursive(node):
		if ch is Button:
			ch.focus_mode = Control.FOCUS_ALL
			if not focus_grabbed:
				ch.grab_focus()
				focus_grabbed = true


## Tries to connect [param control] to its corresponding setting
## 	based on [param control]'s name.
## 	If [param setting] is passed, uses that instead of [param control]'s name
func connect_control_recursively(control: Control, setting:String="") -> void:
	
	for ch:Node in U.get_children_recursive(control):
		if ch is HSlider || ch is CheckBox:
			var _setting: String = (control_get_setting(ch)
				if setting.is_empty() else setting)
			if ch is HSlider:
				ch.value_changed.connect(update_setting.bind(_setting))
			elif ch is CheckBox:
				ch.toggled.connect(_on_CheckBox_toggled.bind(_setting))


## Returns the setting name that matches best with the name of [param control]
## [br]@PRE Setting name is unique among all sections
func control_get_setting(control: Control) -> String:
	
	assert(not get_setting_list().is_empty(), "Setting list not defined!")
	var setting: String = control.name.to_snake_case()
	for full_prop:String in get_setting_list():
		if full_prop.ends_with(setting):
			return full_prop
	assert(false, "Property could not be resolved from control name '{}'"
		.format([control.name], "{}"))
	return ""


## Returns whether any gamepad is connected
func gamepad_connected() -> bool:
	return not Input.get_connected_joypads().is_empty()


## Returns all boolean settings that are manipulated by check box
func get_checkbox_settings() -> PackedStringArray:
	
	var settings: PackedStringArray = []
	for con:Dictionary in get_incoming_connections():
		if con.callable.get_method() == "_on_CheckBox_toggled":
			settings.append(control_get_setting(con.signal.get_object()))
	return settings


## @ABSTRACT
## Returns a dictionary mapping setting names to their default values
func get_default_settings() -> Dictionary:
	return {}


## Returns the value of [param setting].
## [br]@PRE Settings were loaded from file by calling [method load_all_settings]
func get_setting(setting: String) -> Variant:
	
	var sp: PackedStringArray = setting.split("/")
	assert(sp.size() == 2)
	var section: String = sp[0]
	var key: String = sp[1]
	return _save_file.get_value(section, key)


## Returns the names of all defined settings in [param section]
## If [param section] is empty, returns the names of all defined settings
func get_setting_list(section:String="") -> PackedStringArray:
	
	if section.is_empty():
		return get_default_settings().keys()
	return get_default_settings().keys().filter(
		func(x:String): return x.begins_with(section))


## Returns the textual representation of [param event]
static func input_event_to_text(event: InputEvent) -> String:
	
	if not is_instance_valid(event):
		return "null"
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT: return "LMB"
			MOUSE_BUTTON_RIGHT: return "RMB"
			MOUSE_BUTTON_MIDDLE: return "MMB"
	return event.as_text()


## Loads all settings from the file at [member save_path]
func load_all_settings() -> void:
	
	var err: int = _save_file.load(save_path)
	if err != OK:
		print("[Warn] User settings could not be loaded, error code {}"
			.format([err], "{}"))
	for sett:String in get_setting_list():
		load_setting(sett)


# @PRIVATE
## Loads [param setting] from save file into working memory.
## 	If [param update_save], updates save file with default value
## 	if setting is not found
func load_setting(setting: String, update_save:bool=true) -> void:
	
	var sp: PackedStringArray = setting.split("/")
	var section: String = sp[0]
	var key: String = sp[1]
	var value: Variant
	if _save_file.has_section_key(section, key):
		value = _save_file.get_value(section, key)
	else:
		value = get_default_settings()[setting]
		if update_save:
			save_setting(setting, value)
	update_setting(value, setting, false)
	load_setting_control(setting, value)


## @ABSTRACT @PRIVATE
## Makes sure UI control elements match stored config data
func load_setting_control(_setting: String, _value: Variant) -> void:
	pass


## Deletes saved settings and reloads defaults
func reset_all_settings() -> void:
	
	_save_file.clear()
	_save_file.save(save_path)
	load_all_settings()


## Saves the value of [param setting] in the file at [member save_path]
func save_setting(setting: String, value: Variant) -> void:
	
	var sp: PackedStringArray = setting.split("/")
	var section: String = sp[0]
	var key: String = sp[1]
	_save_file.set_value(section, key, value)
	_save_file.save(save_path)


# @PRIVATE @ABSTRACT
func update_setting(value: Variant, setting: String, update_save:bool=true) -> void:
	
	if update_save:
		save_setting(setting, value)
