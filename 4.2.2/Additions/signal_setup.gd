## Utility class for setting up complex signal connections.
class_name SignalSetup


# @PRIVATE
const _SIG_RELAY_GROUP = "SignalSetup_signal_relays"

## Signal data
var input_signal: Signal
## Last callable passed in [method set_connected]
var last_clb: Callable


# @PRIVATE Relay object
var _sig_relay: SignalRelay


## Initializes [member input_signal], [member last_clb] and [member flags].
func _init(p_signal: Signal) -> void:
	
	assert(not p_signal.is_null(), "Invalid signal")
	#assert(_clb.is_valid(), "Invalid callable")
	self.input_signal = p_signal


# @PRIVATE
func _to_string() -> String:
	return input_signal.get_name()


# @PRIVATE Returns existing signal relay, or initializes one if not present.
func _get_signal_relay() -> SignalRelay:
	
	if not is_instance_valid(_sig_relay):
		_sig_relay = SignalRelay.new(input_signal)
		_sig_relay.add_to_group(_SIG_RELAY_GROUP)
		# TODO mem leakage when src and target are not Node
	return _sig_relay


## Asserts that [member input_signal] and [member last_clb]
## 	have a matching number of arguments.
#func assert_args_match() -> void:
	#
	#var signal_args: Array = (U.signal_args(input_signal)
		#if not (get_relay_flags() & SignalRelay.FLAG_IGNORE_ARGS
			#== SignalRelay.FLAG_IGNORE_ARGS) else []) 
	#assert(U.assert_equal(signal_args.size() + last_clb.get_bound_arguments_count(),
		#U.callable_args(last_clb).size()),
		#"Signal and callable have a different number of arguments")


## Simulates signal emission that ignores connection flags and
## 	delay or match requirements. Passes [param argv] as signal arguments.
## 	If [param drop_binds], drops binds from [member last_clb].
func emit_freely(argv:Array=[], drop_binds:bool=false) -> SignalSetup:
	
	assert(not last_clb.is_null(),
		"Define callable with 'set_connected' before calling this method")
	assert(last_clb.is_valid(), "Callable is invalid")
	var _argv: Array = argv
	if is_instance_valid(_sig_relay):
		assert(not (argv && _sig_relay._relay_flags
			& SignalRelay._FLAG_IGNORE_ARGS == SignalRelay._FLAG_IGNORE_ARGS),
			"Cannot pass arguments if 'set_argless' was called.
			Consider calling this method before 'set_argless'")
		_argv = _sig_relay._process_args(argv)
	if drop_binds:
		last_clb.get_object().callv(last_clb.get_method(), _argv)
	else:
		last_clb.callv(_argv)
	return self


## Calls [method emit_freely], only if connected.
## 	If [param drop_binds], drops binds from [member last_clb].
## [br]| Used fo proper setup of [member src].
func emit_setup(argv:Array=[], drop_binds:bool=false) -> SignalSetup:
	
	if not is_connected_to_clb():
		## cannot simulate signal if not connected
		return self
	return emit_freely(argv, drop_binds)


## Calls [method emit_freely], only if not connected.
## 	If [param drop_binds], drops binds from [member last_clb].
func emit_teardown(argv:Array=[], drop_binds:bool=false) -> SignalSetup:
	
	if is_connected_to_clb():
		## cannot simulate signal if connected
		return self
	return emit_freely(argv, drop_binds)


## Returns flags of the signal relay, if any. Otherwise returns 0.
func get_relay_flags() -> int:
	
	if is_instance_valid(_sig_relay):
		return _sig_relay._relay_flags
	return 0


## Returns whether [member input_signal] is connected to [param callable],
## 	either directly or through a signal relay.
func is_connected_to_clb(callable:Callable=last_clb) -> bool:
	
	if is_instance_valid(_sig_relay):
		if _sig_relay.callback != callable:
			return false
		return not _sig_relay.is_queued_for_deletion()
	return input_signal.is_connected(callable)


## Blocks [member input_signal] every time
## 	its arguments do not match [param required_args].
func set_arg_check(required_args: Array) -> SignalSetup:
	
	_get_signal_relay().set_arg_check(required_args)
	return self


## Calls [param method] on [member input_signal]'s binds when it emits.
func set_arg_map(method: Callable) -> SignalSetup:
	
	_get_signal_relay().set_arg_map(method)
	return self


## If [param argless], does not relay [member input_signal]'s binds.
func set_argless(argless:bool=true) -> SignalSetup:
	
	_get_signal_relay().set_argless(argless)
	return self


## Passes bound arguments in front of signal arguments.
func set_bound_first() -> SignalSetup:
	
	_get_signal_relay().set_bound_first()
	return self


## Blocks connected signal every time [param callable] returns false.
func set_call_check(callable: Callable) -> SignalSetup:
	
	_get_signal_relay().set_call_check(callable)
	return self


## Connects or disconnects signal based on [param connected].
## 	Disconnects existing signals.
func set_connected(connected: bool, p_clb: Callable, flags:int=0) -> SignalSetup:
	
	assert(p_clb.is_valid(), "Callable is invalid.")
	if not p_clb.is_valid():
		return
	last_clb = p_clb
	if is_instance_valid(_sig_relay):
		_sig_relay.callback = p_clb
		if connected:
			var parent: Node = (input_signal.get_object()
					if input_signal.get_object() is Node else gl)
			_sig_relay.connect_start(parent, flags)
		else:
			if is_instance_valid(_sig_relay):
				_sig_relay.queue_free()
			#for control:SignalRelay in g.get_tree().get_nodes_in_group(
					#_SIG_RELAY_GROUP):
				#if control == _sig_relay && connected:
					#continue
				#if input_signal.is_connected(control._on_signal):
					#if control.callback == last_clb:
						## TODO EQUAL DOESNT WORK
						#control.queue_free()
	else:
		if input_signal.is_connected(last_clb):
			input_signal.disconnect(last_clb)
		if connected:
			input_signal.connect(last_clb, flags)
	return self


## If passed, relays emitted signals only after [param delay_sec].
func set_delay(delay_sec: float) -> SignalSetup:
	
	_get_signal_relay().set_delay(delay_sec)
	return self


## If passed, recalculates delay with [param calculate_fn] on passed arguments,
## 	every time [member input_signal] passes.
func set_delay_calculate(calculate_fn: Callable) -> SignalSetup:
	
	_get_signal_relay().set_delay_calculate(calculate_fn)
	return self


## Calls [member last_clb] x seconds after a signal passes,
## 	where x is randomly picked from [param delay_bounds].
## [br]| Useful for looping animations with randomized breaks.
## 	If [param abort_ongoing], aborts any ongoing delays when a signal passes.
func set_delay_rand(delay_bounds: Span2f) -> SignalSetup:
	
	_get_signal_relay().set_delay_rand(delay_bounds)
	return self


## Blocks the first [code]count - 1[/code] emissions of connected signal.
func set_emission_count(count: int) -> SignalSetup:
	
	_get_signal_relay().set_emission_count(count)
	return self


## If [param parallel], running delays do not stop
## 	when [member input_signal] emits.
func set_parallel_delays(parallel: bool) -> SignalSetup:
	
	_get_signal_relay().set_parallel_delays(parallel)
	return self


## Prints arguments of an emitted signal
##  when connected by [method Object.connect].
static func PRINT_SIGNAL_ARGS(a="", b="", c="", d="", e="") -> void:
	prints(a, b, c, d, e)
