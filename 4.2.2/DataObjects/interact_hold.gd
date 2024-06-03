## Data class representing a holdable interaction
extends Resource
class_name InteractHold


## Emitted when [member enabled] updates
signal enabled_updated(enabled: bool)
## Emitted when enabled and cast_hold() is called
signal hold_casted()
## Emitted when holding for x seconds, as set by [member custom_hold_thres]
signal hold_custom_thres_reached()
## Emitted when started holding
signal hold_started()
## Emitted when stopped holding
signal hold_stopped()
## Emitted when started or stopped holding
signal hold_toggled(holding: bool)

## A signal will emit after holding for [param custom_hold_thres] seconds.
## [br]@PRE [code]value > 0.0[/code]
@export var custom_hold_thres: float
## When disabled, the holding cannot start or stop
@export var enabled: bool = true:
	set = update_on_enabled

var custom_hold_thres_timer: Delay
var interaction: Interaction = Interaction.new(null, null, [])
var is_holding: bool
var startup_delay: Delay


## Marks the holding interaction as succesfully completed.
## 	If [param start_new], automatically starts holding again
func cast_hold(start_new:bool=false) -> void:
	
	if not enabled:
		return
	if not is_holding:
		return
	hold_casted.emit()
	if is_holding && start_new:
		is_holding = false # allow update
		toggle_holding(true)
	else:
		toggle_holding(false) 


## Starts or stops holding after [param delay] seconds.
## 	Ignores negative delay values
func toggle_holding(holding: bool, delay:float=0.0) -> void:
	
	if not enabled:
		return
	if delay > 0.0:
		startup_delay = Delay.new(g, delay)
		startup_delay.callback(toggle_holding.bind(holding))
		return
	var holding_changed: bool = (holding != is_holding)
	self.is_holding = holding
	if is_holding:
		if custom_hold_thres > 0:
			custom_hold_thres_timer = Delay.new(g, custom_hold_thres)
			custom_hold_thres_timer.callback(
				emit_signal.bind("hold_custom_thres_reached"))
	else:
		if is_instance_valid(startup_delay): startup_delay.queue_free()
		if is_instance_valid(custom_hold_thres_timer): custom_hold_thres_timer.queue_free()
	if holding_changed:
		if is_holding:
			hold_started.emit()
		else:
			hold_stopped.emit()
		hold_toggled.emit(is_holding)


# @PRIVATE
func update_on_enabled(_enabled: bool) -> void:
	
	enabled = _enabled
	if not enabled && is_holding:
		toggle_holding(false)
	enabled_updated.emit(enabled)
