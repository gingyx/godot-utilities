## Data class representing a series of get/set/call operations.
## [br]| Increases readability over for loops.
## [br]@INVAR [member argv_list] and [member method_list] are of identical size
class_name CChain


var argv_list: Array = [] # list of lists
var method_list: Array = []

var cmp_op: int = -1 # operator for comparison
var cmp_val: Variant # value to compare against


# @PRIVATE
func _to_string() -> String:
	
	var st: String = "CChain::"
	for i in range(method_list.size()):
		if i > 0:
			st += '.'
		st += method_list[i] + '(' + str(argv_list[i]) + ')'
	return st


## Creates a new call chain starting with [param method]
static func _xcall(method: String, args:Array=[]) -> CChain:
	return CChain.new().xcall(method, args)


## Creates a new call chain starting with a get request of [param property]
static func _xget(property: String) -> CChain:
	return CChain.new().xget(property)


## Creates a new call chain starting with a set request of [param property]
static func _xset(property: String, value: Variant) -> CChain:
	return CChain.new().xset(property, value)


## Exectues this CChain on [param target] and passes back any return values.
## 	If [param _argvv] is passed, overrides [member argv_list].
## 	Evaluates arguments of type [CChain] on [param arg_target]
func exec(target: Variant, _argvv:Array=[], arg_target:Variant=null) -> Variant:
	
	if target == null:
		return
	if target is Object && not is_instance_valid(target):
		return
	if method_list.is_empty():
		return target
	if _argvv.is_empty():
		_argvv = self.argv_list
	if arg_target != null:
		_argvv = _argvv.duplicate(true) # TODO also dupes dicts!
		for args:Variant in _argvv:
			for j in range(args.size()):
				if args[j] is CChain:
					args[j] = args[j].exec(arg_target)
	var obj: Variant = target
	for i in range(method_list.size()):
		obj = U.call_variant(obj, method_list[i], _argvv[i])
	if cmp_op >= 0:
		obj = U.compare(obj, cmp_val, cmp_op)
	return obj


## Exectues this CChain on every element of [param targets]
## 	and passes on their return values through an array
func exec_all(targets: Array) -> Array:
	
	var values: Array = []
	for m:Variant in targets:
		values.append(exec(m))
	return values


## Appends [param method] to this call chain 
func xcall(method: String, argv:Array=[]) -> CChain:
	
	method_list.append(method)
	argv_list.append(argv)
	return self


## Appends a comparison to this call chain
func xcmp(val: Variant, comparator:int=OP_EQUAL) -> CChain:
	
	self.cmp_op = comparator
	self.cmp_val = val
	return self


## Appends a get request to this call chain 
func xget(property: String) -> CChain:
	
	method_list.append("get_indexed")
	argv_list.append([property])
	return self


## Appends a set request to this call chain 
func xset(property: String, value: Variant) -> CChain:
	
	method_list.append("set_indexed")
	argv_list.append([property, value])
	return self
