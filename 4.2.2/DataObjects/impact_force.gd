## Data class representing an attack.
class_name ImpactForce


## For deflected attacks
const DEFLECTED = -1 

## The damage
var damage: int
## The force's direction
var direction: Vector2
## The force's power, which influences knockback
var power: float
## Customizable meta-data tags for effects like: burning, frozen, charged, etc.
var effects: PackedStringArray


## Initializes [member power], [member damage] and [member direction]
func _init(p_power: float, p_damage:int=0, p_direction:Vector2=Vector2.ZERO) -> void:
	
	assert(p_damage >= 0, "Damage must be positive")
	self.power = p_power
	self.damage = p_damage
	self.direction = p_direction


# @PRIVATE
func _to_string() -> String:
	return "Force: pow={}, dmg={}, dir={}".format(
			[power, damage, direction], "{}")


## Adds a string of meta-data [param effect] to this force,
## 	to be retrieved with [method has_effect]. Returns self
func apply_effect(effect: String) -> ImpactForce:
	
	effects.append(effect)
	return self


## Marks this force as deflected
## 	to be retrieved with [method has_been_deflected]
func deflect() -> void:
	damage = DEFLECTED


## Returns the angle of [member direction] if [member direction] is valid.
## 	Otherwise returns a random angle
func get_angle() -> float:
	
	if is_random():
		return R.randomf(TAU)
	return direction.angle()


## Returns [member direction] if [member direction] is valid.
## 	Otherwise returns a random direction
func get_direction() -> Vector2:
	
	if is_random():
		return R.random_dir()
	return direction


## Returns [code]direction * power[/code]
func get_force() -> Vector2:
	return direction * power


## Returns whether [method deflect] has been called on this force
func has_been_deflected() -> bool:
	return damage == DEFLECTED


## Returns whether [param effect] has been applied to this force
func has_effect(effect: String) -> bool:
	return effect in effects


## Returns whether [code]get_force() > 0[/code]
func has_force() -> bool:
	return direction * power != Vector2.ZERO


## Returns whether [member direction] is valid
func is_random() -> bool:
	return direction == Vector2.ZERO
