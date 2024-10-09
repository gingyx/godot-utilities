## Dictionary class used for picking randomized loot.
extends Resource
class_name ChanceTable


## See [method pick_item_list]
var base_item_list: Array
## Reference table that matches keys to probability weights
var table: Dictionary = {
	# item_id = chance_weight
}


## Initializes [member table] and [member base_item_list].
func _init(p_table:Dictionary={}, p_base_item_list:Array=[]) -> void:
	
	self.table = p_table
	self.base_item_list = p_base_item_list


# @PRIVATE
func _to_string() -> String:
	return str(table)


## Returns a string representation of [member table]
##  that replaces integer items with names as defined by [param item_by_name].
## If [param normalize_weights], expresses weights as percentages.
func get_summary(item_by_name: Dictionary, normalize_weights:bool=false) -> String:
	
	var pair_strings: Array = []
	var sum_of_keys: int = UArr.sum(table.values())
	var name_by_item: Dictionary = {}
	for name:Variant in item_by_name:
		name_by_item[item_by_name[name]] = name.to_lower()
	var table_keys_sorted: Array = table.keys()
	table_keys_sorted.sort()
	for item:Variant in table_keys_sorted:
		var weight: float = (table[item] / float(sum_of_keys)
			if normalize_weights else table[item])
		pair_strings.append("{}: {}".format([name_by_item[item], weight], "{}"))
	return "{" + str(pair_strings).lstrip("[").rstrip("]") + "}"


## Returns the total value of all keys in [param item_list]
## 	as defined by this table.
func get_total_weight(item_list: Array) -> int:
	
	var total_weight: int = 0
	for item:Variant in item_list:
		total_weight += table[item]
	return total_weight


## Adds a new table pair (index:value) for every value in [param arr].
## 	Returns self.
func import_array(arr: Array) -> ChanceTable:
	
	for i in range(arr.size()):
		table[i] = arr[i]
	return self


## Adds a new table pair (value:1) for every value in [param arr].
## 	Returns self.
func import_array_as_keys(arr: Array) -> ChanceTable:
	
	for key:Variant in arr:
		table[key] = 1
	return self


## Inverts the picking probability of each key, rounded to ensure integer values.
## Returns self.
func invert_weights() -> ChanceTable:
	
	var max_weight: Variant = table.values().max()
	for key:Variant in table:
		table[key] = int(round((1.0 / table[key]) * max_weight))
	return self


## Returns whether this ChanceTable is valid.
func is_valid() -> bool:
	
	for weight:Variant in table.values():
		if typeof(weight) != TYPE_INT || weight < 0:
			return false
	if UArr.sum(table.values()) <= 0:
		return false
	return true


## Returns a random key from [member table], with respect to its given weigths.
func pick_item() -> Variant:
	
	assert(not table.is_empty(), "Cannot pick value from empty table")
	return table.keys()[R.choose_weighted(table.values())]


## Same as [method pick_item], but excludes any keys in [param except].
## 	Modifies [member table] in-place.
func pick_item_except(except: Array) -> Variant:
	
	## alter values based on except
	var old_values: Dictionary = {}
	for item:Variant in except:
		old_values[item] = table[item]
		table[item] = 0
	## ensure table is still valid after altering
	var return_val: Variant = (pick_item() if is_valid() else null)
	## restore old values
	for item:Variant in except:
		table[item] = old_values[item]
	return return_val


## Returns an array of [param list_size] with:
## [br]| all items from [member base_item_list] that fit.
## [br]| filled up with random items from [member table].
func pick_item_list(list_size: int) -> Array:
	
	var list: Array = base_item_list.slice(0, list_size - 1)
	for _i in range(list_size - list.size()):
		list.append(pick_item())
	return list


## Sets a new base item list. See [method pick_item_list].
func set_base_item_list(new_base_list: Array) -> ChanceTable:
	
	self.base_item_list = new_base_list
	return self


## Sets a new [member table].
func set_table(new_table: Dictionary) -> ChanceTable:
	
	assert(not new_table.is_empty(), "New table cannot be empty")
	self.table = new_table
	assert(is_valid(), """
		New table must contain only positive integer values and at least one
		non-zero value""")
	return self


## Returns an array where each key of [member table] appears x times,
## 	where x equals the key's weight.
func to_array() -> Array:
	
	var arr: Array = []
	for key:Variant in table:
		for _i:int in range(table[key]):
			arr.append(key)
	return arr


## Updates a key from table with a new chance weight [param new_value].
func update_value(key: Variant, new_value: Variant) -> void:
	table[key] = new_value
