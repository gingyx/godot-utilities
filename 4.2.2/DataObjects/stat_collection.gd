## Abstract template for classes with stat members
extends Resource
class_name StatCollection


## Emitted when [method refresh_all] is called
signal stats_initialized()

const CHOICE_NULL = 0
const CHOICE_YES = 1
const CHOICE_NO = 2


## Connects [param stat_signal] of member [param stat] to [param target]
##  to method _on_stat_StatName_signal_name
func connect_stat_signal(stat: String, stat_signal: String,
		target: Object) -> void:
	
	var method: String = "_on_stat_{}_{}".format(
		[stat.to_pascal_case(), stat_signal], "{}")
	assert(target.has_method(method))
	get(stat).connect(stat_signal, Callable(target, method))


## Returns all members of type GameStat
func get_game_stats() -> Array[GameStat]:
	
	var stats: Array[GameStat] = []
	for pr:Dictionary in get_property_list():
		var val: Variant = get(pr.name)
		if val is GameStat:
			stats.append(val)
	return stats


## Calls [method refresh] on all game stats
## [br]| Used to signal the proper init of all stats
func refresh_all() -> void:
	
	stats_initialized.emit()
	for st:GameStat in get_game_stats():
		st.refresh()
	for pr:Dictionary in get_property_list():
		var val: Variant = get(pr.name)
		if val is ProgressTree:
			val.node_status_changed.emit()


## Resets all members to default values
func reset(keep_signals:bool=true) -> void:
	
	var con_list: Array[Dictionary] = get_signal_connection_list(
		"stats_initialized")
	var script_name: String = get_script().get_path()
	set_script(null)
	set_script(load(script_name))
	if keep_signals:
		for con:Dictionary in con_list:
			if not is_connected(con.signal.get_name(), con.callable):
				connect(con.signal.get_name(), con.callable, con.flags)
