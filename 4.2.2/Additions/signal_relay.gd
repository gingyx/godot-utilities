## Node class that relays a signal emission if it satisfies given conditions.
## 
## It can also modify signal arguments on emission or delay callback.
class_name SignalRelay
extends Node

## Emitted when a connected signal passed all control checks
signal signal_passed()

# @PRIVATE
enum ArgOp {
	MAP,
	FILTER,
}

# @PRIVATE
const _FLAG_IGNORE_ARGS = 1
const _FLAG_REQUIRE_ARGS = 2
const _FLAG_DELAY_ABORT_ONGOING = 4
const _FLAG_BOUND_FIRST = 8
const _FLAG_REQUIRE_CALL = 16

## Value that represents an empty signal argument, different from null
const NO_ARG = "\b"

## Signal to relay
var input_signal: Signal
## Callable to call when emitted signal passes
var callback: Callable

# @PRIVATE
var _arg_operations: Array = [] # @TYPE [[ArgOp, Callable]
var _relay_flags: int
var _delay_bounds: Span2f
var _delay_calculate_fn: Callable
var _last_delay: Delay
var _required_args: Array
var _required_call: Callable
var _required_emissions: int


## Initializes [member input_signal] and [member callback].
func _init(p_input_signal: Signal, p_callback:Callable=Callable()) -> void:
	
	assert(p_callback.is_valid() || p_callback.is_null(), "Invalid callback")
	self.input_signal = p_input_signal
	self.callback = p_callback


# @PRIVATE
func _to_string() -> String:
	return str(callback)


# @PRIVATE
func _on_signal_emitted(a=NO_ARG, b=NO_ARG, c=NO_ARG, d=NO_ARG, e=NO_ARG) -> void:
	
	if _relay_flags & _FLAG_REQUIRE_CALL == _FLAG_REQUIRE_CALL:
		if not _required_call.call():
			return
	## validate args
	if _relay_flags & _FLAG_REQUIRE_ARGS == _FLAG_REQUIRE_ARGS:
		if not _check_args([a, b, c, d, e]):
			return
	if _required_emissions > 0:
		_required_emissions -= 1
		if _required_emissions > 0:
			return
	## process args
	var _args: Array = _process_args([a, b, c, d, e])
	## pass signal
	if _relay_flags & _FLAG_DELAY_ABORT_ONGOING == _FLAG_DELAY_ABORT_ONGOING:
		if is_instance_valid(_last_delay):
			if not _last_delay.is_queued_for_deletion():
				_last_delay.queue_free()
	var delay: float = _calculate_delay(_args)
	if delay > 0.0:
		_last_delay = Delay.new(self, delay)
		_last_delay.callback(_pass_signal.bind(_args))
	else:
		_pass_signal(_args)


# @PRIVATE Adds operation to apply on signal arguments.
func _add_arg_operation(operation: ArgOp, callable: Callable) -> void:
	_arg_operations.append([operation, callable])


# @PRIVATE Returns the next delay time (s).
func _calculate_delay(args: Array) -> float:
	
	if _delay_calculate_fn.is_valid():
		return _delay_calculate_fn.call(args)
	if is_instance_valid(_delay_bounds):
		return _delay_bounds.pick_random()
	return 0.0


# @PRIVATE Returns whether [param args] satisfy required conditions.
func _check_args(args: Array) -> bool:
	
	for i in range(mini(args.size(), _required_args.size())):
		if _required_args[i] is Object:
			if not is_instance_valid(_required_args[i]):
				queue_free()
				return false
			if _required_args[i] is CChain:
				if _required_args[i].exec(args[i]) == false:
					return false
				continue
		if not is_same(args[i], _required_args[i]):
			return false
	return true


# @PRIVATE Passes [member input_signal]'s emission with [param args].
func _pass_signal(args:Array=[]) -> void:
	
	if _relay_flags & _FLAG_BOUND_FIRST == _FLAG_BOUND_FIRST:
		callback.get_object().callv(callback.get_method(),
			callback.get_bound_arguments() + args)
	else:
		callback.callv(args)
	signal_passed.emit()


# @PRIVATE Applies argument operations on [param args].
func _process_args(args:Array=[]) -> Array:
	
	var _args: Array = []
	if _relay_flags & _FLAG_IGNORE_ARGS != _FLAG_IGNORE_ARGS:
		for arg:Variant in args:
			if is_same(arg, NO_ARG):
				continue
			_args.append(arg)
	for op:Array in _arg_operations:
		match op[0]:
			ArgOp.MAP: _args = _args.map(op[1])
			ArgOp.FILTER: _args = _args.filter(op[1])
	return _args


## Sets up the relay as child of [param parent].
func connect_start(parent: Node, flags:int=0) -> void:
	
	if get_parent() != null:
		return
	assert(is_instance_valid(parent), "Parent is invalid")
	assert(parent.is_inside_tree(), "Parent is not inside tree")
	assert(callback.is_valid(), "Invalid callback")
	input_signal.connect(_on_signal_emitted, flags & ~CONNECT_ONE_SHOT)
	if flags & CONNECT_ONE_SHOT == CONNECT_ONE_SHOT:
		signal_passed.connect(queue_free, CONNECT_DEFERRED)
	var clb_obj: Object = callback.get_object()
	if clb_obj is Node:
		if not clb_obj.tree_exiting.is_connected(queue_free):
			clb_obj.tree_exiting.connect(queue_free, CONNECT_DEFERRED)
	parent.add_child(self)


## Blocks [member input_signal] every time
## 	its arguments do not match [param required_args].
func set_arg_check(required_args: Array) -> SignalRelay:
	
	_required_args = required_args
	_relay_flags |= _FLAG_REQUIRE_ARGS
	return self


## Calls [param method] on [member input_signal]'s binds when it emits.
func set_arg_map(method: Callable) -> SignalRelay:
	
	assert(method.is_valid())
	_add_arg_operation(ArgOp.MAP, method)
	return self


## If [param argless], does not relay [member input_signal]'s binds.
func set_argless(argless:bool=true) -> SignalRelay:
	
	_relay_flags = (_relay_flags & ~_FLAG_IGNORE_ARGS
			| (int(argless) * _FLAG_IGNORE_ARGS))
	return self


## Passes bound arguments in front of signal arguments.
func set_bound_first() -> SignalRelay:
	
	_relay_flags |= _FLAG_BOUND_FIRST
	return self


## Blocks connected signal every time [param callable] returns false.
func set_call_check(callable: Callable) -> SignalRelay:
	
	assert(callable.is_valid(), "Invalid callable")
	_required_call = callable
	_relay_flags |= _FLAG_REQUIRE_CALL
	return self


## If passed, relays emitted signals only after [param delay_sec].
func set_delay(delay_sec: float) -> SignalRelay:
	return set_delay_rand(Span2f.new(delay_sec, delay_sec))


## If passed, recalculates delay with [param calculate_fn] on passed arguments,
## 	every time [member input_signal] passes.
func set_delay_calculate(calculate_fn: Callable) -> SignalRelay:
	
	_delay_calculate_fn = calculate_fn
	return self


## Calls [member clb] x seconds after a signal passes,
## 	where x is randomly picked from [param p_delay_bounds].
## [br]| Useful for looping animations with randomized breaks.
## 	If [param abort_ongoing], aborts any ongoing delays when a signal passes.
func set_delay_rand(p_delay_bounds: Span2f) -> SignalRelay:
	
	if p_delay_bounds.end <= 0.0:
		## negative duration
		return self
	_delay_bounds = p_delay_bounds
	return self


## Blocks the first [code]count - 1[/code] emissions of connected signal.
func set_emission_count(count: int) -> SignalRelay:
	
	_required_emissions = maxi(0, count)
	return self


## If [param parallel], running delays do not stop
## 	when [member input_signal] emits.
func set_parallel_delays(parallel: bool) -> SignalRelay:
	
	_relay_flags = (_relay_flags & ~_FLAG_DELAY_ABORT_ONGOING
			| (int(parallel) * _FLAG_DELAY_ABORT_ONGOING))
	return self
