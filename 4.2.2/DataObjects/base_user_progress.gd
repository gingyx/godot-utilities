## Data class representing a user's total game progress
class_name BaseUserProgress
extends Resource


## Path where user progress save files should be stored
@export var save_path = "user://progress_data.json"

## Custom game version property
var game_version: int = 0


## Loads data from [member save_path] into members
func load_data() -> void:
	
	var json_file = FileAccess.open(save_path, FileAccess.READ)
	if FileAccess.get_open_error() != OK:
		prints("[Error] Failed to load data: error code",
			FileAccess.get_open_error())
		return
	var test_json_conv = JSON.new()
	test_json_conv.parse(json_file.get_as_text())
	var result: JSON = test_json_conv.get_data()
	if result.error != OK:
		prints("[Error] Failed to parse data:", result.error_string)
		return
	ObjectConverter.apply_dict_to(result.result, self)


## Saves member data to [member save_path].
## NOTE: avoid JSON-incompatible values like INF, NAN, etc.
func save_data() -> void:
	
	var json_file = FileAccess.open(save_path, FileAccess.WRITE)
	if FileAccess.get_open_error() != OK:
		prints("[Error] Failed to save data: error code",
			FileAccess.get_open_error())
		return
	var dict: Dictionary = ObjectConverter.to_dict(self)
	json_file.store_string(JSON.stringify(dict))
