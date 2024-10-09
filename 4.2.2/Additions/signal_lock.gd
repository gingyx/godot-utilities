## Node class with a logic gate that unlocks based on [member input_signals]'s emissions.
## 
## When unlocked, emits [signal unlocked].
extends Node
class_name SignalLock


## Emitted when all required [member input_signals] emitted,
## 	according to [member gate_logic]
signal unlocked()

enum GateLogic {
	ANY_SIGNAL, ## Unlocks when any one of [member input_signals] emitted
	ALL_SIGNALS, ## Unlocks when all [member input_signals] emitted
	ALL_SIGNALS_IN_ORDER, ## Unlocks when all [member input_signals] emitted, in order of the [param signals] array
}

## Logic for checking signal emissions
var gate_logic: GateLogic
## Signals that trigger the gate logic
var input_signals: Array[Signal]

# @PRIVATE For each of [method input_signals], holds indexed received boolean.
# 	Resets if ALL_SIGNALS_IN_ORDER and order is wrong.
var _signal_idx_received: Array


## Initializes this SignalLock as a child of [param parent].
## 	Initializes [param gate_logic] and [param input_signals].
func _init(parent: Node, p_gate_logic: GateLogic, p_input_signals: Array[Signal]) -> void:
	
	assert(is_instance_valid(parent))
	assert(parent.is_inside_tree())
	self.gate_logic = p_gate_logic
	self.input_signals = p_input_signals
	_signal_idx_received = []
	parent.add_child(self)
	for i:int in range(input_signals.size()):
		_signal_idx_received.append(false)
		if input_signals[i].get_object() is SignalRelay:
			input_signals[i].get_object().set_argless().connect_start(self)
		input_signals[i].connect(check_lock_on_signal_pass.bind(i))


# @PRIVATE Marks the [param passed_signal_id]th signal
# 	in [member input_signals] as passed.
# 	If logic gate conditions are met, unlocks.
func check_lock_on_signal_pass(passed_signal_id: int) -> void:
	
	_signal_idx_received[passed_signal_id] = true
	if gate_logic == GateLogic.ALL_SIGNALS_IN_ORDER:
		for i in range(passed_signal_id):
			if not _signal_idx_received[i]:
				reset_lock()
				return
		if passed_signal_id < input_signals.size() - 1:
			return
	if gate_logic == GateLogic.ALL_SIGNALS:
		if _signal_idx_received.any(func(x): return x == false):
			return
	unlocked.emit()


## Clears tracking data and invalidates previously emitted signals.
func reset_lock() -> void:
	_signal_idx_received.fill(false)
