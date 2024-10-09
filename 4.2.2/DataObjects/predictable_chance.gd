## Class that generates probability booleans with predictable rules.
##
## Provides an alternative to pure randomness, which can improve user experience.
extends Resource
class_name PredictableChance


## General probability value
@export var probability: float
## When generating this many chances chances,
## 	ensure at least one chance is true
@export var at_least_every: int:
	set = set_at_least_every
## Allow subsequent true chances
@export var allow_subsequent: bool = true

# @PRIVATE
var _aging: CycleIter
var _last_chance_value: bool


# @PRIVATE
func _init() -> void:
	## Call setter
	at_least_every = at_least_every


## Returns true with a probability of [param prob], unless overruled.
func chance() -> bool:
	
	var _chance: bool
	if _last_chance_value && not allow_subsequent:
		_chance = false
	elif _aging != null && _aging.increment():
		_chance = true
	else:
		_chance = R.chance(probability)
	_last_chance_value = _chance
	return _chance


## Sets [member at_least_every]
func set_at_least_every(p_at_least_every: int):
	
	at_least_every = p_at_least_every
	if at_least_every > 0:
		_aging = CycleIter.new(at_least_every)
	else:
		_aging = null
