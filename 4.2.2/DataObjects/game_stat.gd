## Data class for stats (e.g. health, coins, gems, ...)
## [br]| Automatic clamping
## [br]| Signals for player feedback
class_name GameStat
extends Resource


## Emitted when a deposit test exceeds [member max_value]
## [br]| Useful for player feedback
signal deposit_failed()
## Emitted when a withdraw test exceeds [member min_value]
## [br]| Useful for player feedback
signal withdraw_failed()
## Emitted when the stat's value changed
signal value_changed(old_val: float, new_val: float)
## Emitted when the stat's value changed
signal value_changed_to(new_val: float)

## Minimum stat value, clamped
@export var min_value: float = -INF
## Maximum stat value, clamped
@export var max_value: float = INF
## Custom stat name
@export var name: String
## Current stat value
@export var val: float: set = set_val


## See [param value_bounds]: [member min_value] and [member max_value]
func _init(value_bounds:Span2f=null, start_value:float=0.0) -> void:
	
	if value_bounds != null:
		set_value_bounds(value_bounds)
	self.val = start_value


# @PRIVATE
func _to_string() -> String:
	
	var _name: String = " '" + name + "' " if name else ""
	var _min: String = str(min_value) if not is_inf(min_value) else ".."
	var _max: String = str(max_value) if not is_inf(max_value) else ".."
	return "Stat{}[{}, {}]: {}".format([_name, _min, _max, val], "{}")


## Increases [member val] to [param max_val] if [param max_val] is larger
func check_max(max_val: float) -> void:
	val = max(val, max_val)


## Decreases [member val] to [param min_val] if [param min_val] is smaller
func check_min(min_val: float) -> void:
	val = min(val, min_val)


## Returns whether increasing [member val] by [param amount]
## 	would exceed [member max_value].
## Commits decrease if that would not exceed [member max_value]
## 	and [param check_only] is false
func deposit(amount: float, check_only:bool=false) -> bool:
	
	if val + amount > max_value:
		deposit_failed.emit()
		return false
	else:
		if not check_only:
			val += amount
		return true


## Returns whether decreasing [member val] by [param amount]
## 	would exceed [member min_value].
## Commits decrease if that would not exceed [member min_value]
## 	and [param check_only] is false
func withdraw(amount: float, check_only:bool=false) -> bool:
	
	if val - amount < min_value:
		withdraw_failed.emit()
		return false
	else:
		if not check_only:
			val -= amount
		return true


## Returns [code]val == min_value[/code]
func is_empty() -> bool:
	return val == min_value


## Returns [code]val == max_value[/code]
func is_full() -> bool:
	return val == max_value


## Sets [member val] to [member min_value]. Returns self
func make_empty() -> GameStat:
	
	val = min_value
	return self


## Sets [member val] to [member max_value]. Returns self
func make_full() -> GameStat:
	
	val = max_value
	return self


## Emits [signal value_changed] for correct initialization of e.g. UI
func refresh() -> void:
	
	value_changed.emit(val, val)
	value_changed_to.emit(val)


func set_val(new_value: float) -> void:
	
	var old_value: float = val
	val = clamp(new_value, min_value, max_value)
	value_changed.emit(old_value, val)
	value_changed_to.emit(val)


## Sets the minimum and maximum values
func set_value_bounds(value_bounds: Span2f) -> void:
	
	assert(value_bounds != null)
	self.min_value = value_bounds.lower
	self.max_value = value_bounds.upper
