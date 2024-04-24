## Data class that holds objects' member values,
## 	which allows recovery when member values change
class_name MemberRecord


# @TYPE {CChain = Object}
var _callbacks: Dictionary = {}


## Returns whether [param object] has been recorded
func has_record_of(object: Object) -> bool:
	return _callbacks.values().has(object)


## Records all [param object]'s members that appear in [param member_list]
func record_members(object: Object, member_list: Array[StringName]) -> void:
	
	for mem:StringName in member_list:
		var value: Variant = object.get(mem)
		assert(value != null, "Object {} has no member {}"
			.format([object, mem], "{}"))
		var cc = CChain._xset(mem, value)
		_callbacks[cc] = object


func record_members_custom(object: Object, call_list: Array[CChain]) -> void:
	
	for cc:CChain in call_list:
		_callbacks[cc] = object


## Reapply all object members
func recover_all() -> void:
	
	for c:CChain in _callbacks:
		c.exec(_callbacks[c])
