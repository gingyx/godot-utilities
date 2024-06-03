## Class for generating probability booleans with predictable rules
extends Resource
class_name PredictableChance


## General probability value
@export var probability: float
## When generating this many chances chances,
## 	ensure at least one chance is true
@export var at_least_every: int
## Allow subsequent true chances
@export var allow_subsequent: bool = true

var aging: CycleIter
var previous_chance: bool


func _init() -> void:
	
	if at_least_every > 0:
		aging = CycleIter.new(at_least_every)


## Returns true with a probability of [param prob], unless overruled
func chance() -> bool:
	
	var _chance: bool
	if previous_chance && not allow_subsequent:
		_chance = false
	elif aging != null && aging.increment():
		_chance = true
	else:
		_chance = R.chance(probability)
	previous_chance = _chance
	return _chance
