## Static class for converting objects from/to dictionaries
## [br]| Better for backwards compatibility to store dicts than classes
class_name ObjectConverter


## Assigns [param member_values] to the members of [param object]
static func apply_dict_to(member_values: Dictionary, object: Object) -> void:
	
	for mem:Variant in member_values:
		if typeof(member_values[mem]) == TYPE_DICTIONARY:
			## try to convert to dict
			var current_value: Variant = object.get(mem)
			if current_value is Object && is_instance_valid(current_value):
				apply_dict_to(member_values[mem], current_value)
				continue
		object.set(mem, member_values[mem])


## Creates new object of [param object_class]
## 	and assigns [param member_values] to its members
static func from_dict(member_values: Dictionary, object_class: GDScript) -> Object:
	
	var object: Object = object_class.new()
	for mem:String in object_get_members(object):
		object.set(mem, member_values[mem])
	return object


## Returns all user-defined members of [param object]
static func object_get_members(object: Object) -> PackedStringArray:
	
	var members: PackedStringArray = []
	for pr:Dictionary in object.get_property_list():
		if pr.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
			members.append(pr.name)
	return members


## Converts [param object] into a dictionary with its assigned members.
## 	If [param deep], converts object members as well
static func to_dict(object: Object, deep:bool=true) -> Dictionary:
	
	if not is_instance_valid(object):
		return {}
	var dict: Dictionary = {}
	for mem:String in object_get_members(object):
		var value: Variant = object.get(mem)
		if deep && value is Object:
			value = to_dict(value, true)
		dict[mem] = value
	return dict
