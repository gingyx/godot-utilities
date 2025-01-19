## Static class for converting objects from/to dictionaries.
##
## Provides an alternative to the built-in [method @GlobalScope.inst_to_dict],
## 	that does not store class references.
## Instead, the object reference and its class type are passed when loading
## 	its stored members. That ensures better backwards-compatibility.
class_name ObjectConverter


# @PRIVATE
static func _invoke_nested_objects(nest: Variant, clb: Callable) -> Variant:
	
	if typeof(nest) == TYPE_ARRAY:
		var arr: Array = []
		for i in range(nest.size()):
			if nest[i] is Object:
				arr.append(clb.call(nest[i]))
			else:
				arr.append(_invoke_nested_objects(nest[i], clb))
		return arr
	elif typeof(nest) == TYPE_DICTIONARY:
		var dict: Dictionary = {}
		for key in nest:
			if nest[key] is Object:
				dict[key] = clb.call(nest[key])
			else:
				dict[key] = _invoke_nested_objects(nest[key], clb)
		return dict
	return nest


## Assigns [param member_values] to the members of [param object].
static func apply_dict_to(member_values: Dictionary, object: Object) -> void:
	
	for member:String in member_values:
		var current_value: Variant = object.get(member)
		var new_value: Variant = member_values[member]
		if typeof(new_value) == TYPE_DICTIONARY:
			if current_value is Object && is_instance_valid(current_value):
				apply_dict_to(new_value, current_value)
				continue
			if typeof(current_value) == TYPE_DICTIONARY:
				apply_dict_to(new_value, DictObjectWrapper.new(current_value))
				continue
		elif typeof(new_value) == TYPE_ARRAY:
			if typeof(current_value) == TYPE_ARRAY:
				apply_dict_to(UArr.to_dict(new_value, true),
					ArrObjectWrapper.new(current_value))
				continue
		elif typeof(new_value) == TYPE_STRING && new_value.is_valid_html_color():
			object.set(member, Color(new_value))
			continue
		object.set(member, new_value)


## Creates new object of [param object_class]
## 	and assigns [param member_values] to its members.
static func from_dict(member_values: Dictionary, object_class: GDScript) -> Object:
	
	var object: Object = object_class.new()
	for mem:String in obj_get_user_members(object):
		object.set(mem, member_values[mem])
	return object


## Returns all user-defined members of [param object].
static func obj_get_user_members(object: Object) -> PackedStringArray:
	
	var members: PackedStringArray = []
	for pr:Dictionary in object.get_property_list():
		if pr.usage & PROPERTY_USAGE_SCRIPT_VARIABLE == PROPERTY_USAGE_SCRIPT_VARIABLE:
			members.append(pr.name)
	return members


## Converts [param object] into a dictionary with its assigned members.
## 	If [param deep], converts object members as well.
static func to_dict(object: Object, deep:bool=true) -> Dictionary:
	
	if not is_instance_valid(object):
		return {}
	var dict: Dictionary = {}
	for mem:String in obj_get_user_members(object):
		var value: Variant = object.get(mem)
		if deep:
			value = _invoke_nested_objects(value,
					ObjectConverter.to_dict.bind(true))
		if value is Object && value != null && deep:
			value = to_dict(value, true)
		elif typeof(value) == TYPE_COLOR:
			value = value.to_html()
		dict[mem] = value
	return dict


## Class that wraps dictionary in object.
class DictObjectWrapper:
	
	var dict: Dictionary
	
	func _init(p_dict: Dictionary) -> void:
		self.dict = p_dict
	
	func _get(property: StringName) -> Variant:
		return dict.get(property)
	
	func _set(property: StringName, value: Variant) -> bool:
		if property in dict:
			dict[property] = value
		return true


## Class that wraps array in object.
class ArrObjectWrapper:
	
	var arr: Array
	
	func _init(p_arr: Array) -> void:
		self.arr = p_arr
	
	func _get(property: StringName) -> Variant:
		if property.is_valid_int():
			var idx: int = int(String(property))
			if idx >= 0 && idx < arr.size():
				return arr[idx]
		return null
	
	func _set(property: StringName, value: Variant) -> bool:
		if property.is_valid_int():
			var idx: int = int(String(property))
			if idx >= 0 && idx < arr.size():
				arr[idx] = value
		return true
