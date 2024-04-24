## Builder class for signals with util functions
class_name SigBuilder


const SIG_CONTROL_GROUP = "signal_builder:signal_controls"

## Signal object
var signal_obj: Signal
## Callable that executes when a signal passes
var clb: Callable

var sig_control: SigControl


## Initializes [member signal_obj], [member clb] and [member flags]
func _init(_signal: Signal) -> void:
	
	assert(not _signal.is_null(), "Invalid signal")
	#assert(_clb.is_valid(), "Invalid callable")
	self.signal_obj = _signal


# @PRIVATE
func _to_string() -> String:
	
	return signal_obj.get_name()


## Asserts that [member signal_obj] and [member clb]
## 	have a matching number of arguments
#func assert_args_match() -> void:
	#
	#var signal_args: Array = (U.signal_args(signal_obj)
		#if not (get_control_flags() & SigControl.FLAG_IGNORE_ARGS
			#== SigControl.FLAG_IGNORE_ARGS) else []) 
	#assert(U.assert_equal(signal_args.size() + clb.get_bound_arguments_count(),
		#U.callable_args(clb).size()),
		#"Signal and callable have a different number of arguments")


## Passes bound arguments in front of signal arguments
func bound_first() -> SigBuilder:
	
	get_signal_control().control_flags |= SigControl.FLAG_BOUND_FIRST
	return self


## Simulates signal emission that ignores connection flags and
## 	delay or match requirements. Passes [param argv] as signal arguments.
## 	If [param drop_binds], drops binds from [member clb].
func emit_freely(argv:Array=[], drop_binds:bool=false) -> SigBuilder:
	
	assert(not clb.is_null(),
		"Define callable with 'set_connect' before calling this method")
	assert(clb.is_valid(), "Callable is invalid")
	var _argv: Array = argv
	if is_instance_valid(sig_control):
		assert(not (argv && sig_control.control_flags
			& SigControl.FLAG_IGNORE_ARGS == SigControl.FLAG_IGNORE_ARGS),
			"Cannot pass arguments if ignore_args was called.
			Consider calling this method before ignore_args")
		_argv = sig_control.process_args(_argv)
	if drop_binds:
		clb.get_object().callv(clb.get_method(), _argv)
	else:
		clb.callv(_argv)
	return self


## Calls [method emit_freely], only if connected
## 	If [param drop_binds], drops binds from [member clb].
## [br]| Used fo proper setup of [member src]
func emit_setup(argv:Array=[], drop_binds:bool=false) -> SigBuilder:
	
	if not is_connected_to_clb():
		# cannot simulate signal if not connected
		return self
	return emit_freely(argv, drop_binds)


## Calls [method emit_freely], only if not connected
## 	If [param drop_binds], drops binds from [member clb].
func emit_teardown(argv:Array=[], drop_binds:bool=false) -> SigBuilder:
	
	if is_connected_to_clb():
		# cannot simulate signal if connected
		return self
	return emit_freely(argv, drop_binds)


## Returns flags of the signal control, if any. Otherwise returns 0
func get_control_flags() -> int:
	
	if sig_control != null:
		return sig_control.control_flags
	return 0


# @PRIVATE
## Returns existing signal control, or initializes one if not present 
func get_signal_control() -> SigControl:
	
	if not is_instance_valid(sig_control):
		sig_control = SigControl.new(Callable())
		sig_control.add_to_group(SIG_CONTROL_GROUP)
		# TODO mem leakage when src and target are not Node
	return sig_control


## Blocks connected signal every time its arguments do not match [param matched]
func if_args(matched: Array, match_method:Callable=Callable()) -> SigBuilder:
	
	assert(not matched.is_empty())
	if not match_method.is_null():
		assert(match_method.is_valid())
		get_signal_control().match_method = match_method
	get_signal_control().required_args = matched
	get_signal_control().control_flags |= SigControl.FLAG_REQUIRE_ARGS
	return self


## Blocks connected signal every time [param callable] returns false
func if_callable(callable: Callable) -> SigBuilder:
	
	assert(callable.is_valid())
	get_signal_control().required_call = callable
	get_signal_control().control_flags |= SigControl.FLAG_REQUIRE_CALL
	return self


## Connects a signal without forwarding its binds
func ignore_args() -> SigBuilder:
	
	get_signal_control().control_flags |= SigControl.FLAG_IGNORE_ARGS
	return self


## Returns whether [member signal_obj] is connected to [member clb],
## 	either directly or through a signal control
func is_connected_to_clb() -> bool:
	
	if is_instance_valid(sig_control):
		return not sig_control.is_queued_for_deletion()
	return signal_obj.is_connected(clb)


## Calls [param method] on connected signal binds on emission
func map_args(method: Callable) -> SigBuilder:
	
	assert(method.is_valid())
	get_signal_control().add_arg_operation(SigControl.ArgOp.MAP, method)
	return self


## Connects or disconnects signal based on [param start].
## 	Disconnects existing signals
func set_connect(_clb: Callable, start:bool=true, flags:int=0) -> SigBuilder:
	
	assert(_clb.is_valid())
	self.clb = _clb
	if is_instance_valid(sig_control):
		sig_control.callback = clb
		if not start:
			if is_instance_valid(sig_control):
				sig_control.queue_free()
			#for control:SigControl in g.get_tree().get_nodes_in_group(
					#SIG_CONTROL_GROUP):
				#if control == sig_control && start:
					#continue
				#if signal_obj.is_connected(control._on_signal):
					#if control.callback == clb:
						## TODO EQUAL DOESNT WORK
						#control.queue_free()
		if start:
			signal_obj.connect(sig_control._on_signal,
				flags & ~CONNECT_ONE_SHOT)
			if flags & CONNECT_ONE_SHOT == CONNECT_ONE_SHOT:
				sig_control.signal_passed.connect(sig_control.queue_free,
					CONNECT_DEFERRED)
			if clb.get_object() is Node:
				clb.get_object().tree_exiting.connect(sig_control.queue_free,
					CONNECT_DEFERRED)
			var parent: Node = (signal_obj.get_object()
				if signal_obj.get_object() is Node else g.CSc)
			parent.add_child(sig_control)
	else:
		if signal_obj.is_connected(clb):
			signal_obj.disconnect(clb)
		if start:
			signal_obj.connect(clb, flags)
	return self


## Calls [member clb] [param delay_sec] seconds after a signal passes.
## 	If [param abort_ongoing], aborts any ongoing delays when a signal passes
func set_delay(delay_sec: float) -> SigBuilder:
	return set_delay_rand(Span2f.new(delay_sec, delay_sec))


## Recalculates delay with [param delay_function] every time a signal passes,
## 	based on passed arguments
func set_delay_function(delay_function: Callable) -> SigBuilder:
	
	get_signal_control().delay_function = delay_function
	return self


func set_delays_parallel(parallel: bool) -> SigBuilder:
	
	if parallel:
		get_signal_control().control_flags &= ~SigControl.FLAG_DELAY_ABORT_ONGOING
	else:
		get_signal_control().control_flags |= SigControl.FLAG_DELAY_ABORT_ONGOING
	return self


## Calls [member clb] x seconds after a signal passes,
## 	where x is randomly picked from [param delay_bounds].
## [br]| Useful for looping animations with randomized breaks
## 	If [param abort_ongoing], aborts any ongoing delays when a signal passes
func set_delay_rand(delay_bounds: Span2f) -> SigBuilder:
	
	if delay_bounds.upper <= 0.0:
		## negative duration
		return self
	get_signal_control().delay_bounds = delay_bounds
	return self


## Prints arguments of an emitted signal
##  when connected by [method Object.connect]
static func PRINT_SIGNAL_ARGS(a="", b="", c="", d="", e="") -> void:
	prints(a, b, c, d, e)


# @PRIVATE
class SigControl extends Node:
	
	## Emitted when a connected signal passed all control checks
	signal signal_passed()
	
	enum ArgOp {
		MAP,
		FILTER
	}
	
	const FLAG_IGNORE_ARGS = 1
	const FLAG_REQUIRE_ARGS = 2
	const FLAG_DELAY_ABORT_ONGOING = 4
	const FLAG_BOUND_FIRST = 8
	const FLAG_REQUIRE_CALL = 16
	
	const NO_ARG = "\b"
	
	## public
	var arg_operations: Array = [] # @type [[ArgOp, Callable]
	var control_flags: int
	var delay_bounds: Span2f
	var delay_function: Callable
	var match_method: Callable = check_args
	var required_args: Array
	var required_call: Callable
	## private
	var callback: Callable
	var delay_last: Delay
	
	func _init(_callback: Callable) -> void:
		self.callback = _callback
	
	func _to_string() -> String:
		return str(callback)
	
	func _on_signal(a=NO_ARG, b=NO_ARG, c=NO_ARG, d=NO_ARG, e=NO_ARG) -> void:
		if control_flags & FLAG_REQUIRE_CALL == FLAG_REQUIRE_CALL:
			if not required_call.call():
				return
		# validate args
		if control_flags & FLAG_REQUIRE_ARGS == FLAG_REQUIRE_ARGS:
			if not match_method.call([a, b, c, d, e]):
				return
		# process args
		var _args: Array = process_args([a, b, c, d, e])
		# pass signal
		if control_flags & FLAG_DELAY_ABORT_ONGOING == FLAG_DELAY_ABORT_ONGOING:
			if is_instance_valid(delay_last):
				if not delay_last.is_queued_for_deletion():
					delay_last.queue_free()
		var delay: float = calculate_delay(_args)
		if delay > 0.0:
			delay_last = Delay.new(self, delay)
			delay_last.callback(pass_signal.bind(_args))
		else:
			pass_signal(_args)
	
	func add_arg_operation(operation: ArgOp, callable: Callable) -> void:
		arg_operations.append([operation, callable])
	
	func calculate_delay(args: Array) -> float:
		if delay_function.is_valid():
			return delay_function.call(args)
		if is_instance_valid(delay_bounds):
			return delay_bounds.pick_value()
		return 0.0
	
	func check_args(args: Array) -> bool:
		for i in range(min(args.size(), required_args.size())):
			if required_args[i] is Object:
				if not is_instance_valid(required_args[i]):
					queue_free()
					return false
				if required_args[i] is CChain:
					if required_args[i].exec(args[i]) == false:
						return false
					continue
			if args[i] != required_args[i]:
				return false
		return true
	
	func pass_signal(args:Array=[]) -> void:
		if control_flags & FLAG_BOUND_FIRST == FLAG_BOUND_FIRST:
			callback.get_object().callv(callback.get_method(),
				callback.get_bound_arguments() + args)
		else:
			callback.callv(args)
		signal_passed.emit()
	
	func process_args(args:Array=[]) -> Array:
		var _args: Array = []
		if control_flags & FLAG_IGNORE_ARGS != FLAG_IGNORE_ARGS:
			for arg:Variant in args:
				if typeof(arg) == typeof(NO_ARG):
					if arg == NO_ARG:
						continue
				_args.append(arg)
		for op:Array in arg_operations:
			match op[0]:
				ArgOp.MAP: _args = _args.map(op[1])
				ArgOp.FILTER: _args = _args.map(op[1])
		return _args
