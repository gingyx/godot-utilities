## Class for mapping audio file path names to descriptions.
class_name AudioTranscriber


## Emitted every time a known sound is played
signal transcribed(text: String)

## If [param debug_mode], sounds that are not in [member transcripion_map]
## 	are printed to output
var debug_mode = false
## Dictionary mapping sound names to their transcriptions
var transcripion_map: Dictionary


## Initializes [member transcripion_map].
@warning_ignore("unused_parameter")
func _init(p_transcripion_map: Dictionary) -> void:
	ah.sound_started.connect(_on_sound_played)


# @PRIVATE
func _on_sound_played(sound_path: String) -> void:
	
	var sound_tag: String = (
		sound_path.rsplit("/", true, 1)[1].rsplit(".", true, 1)[0])
	if sound_tag.ends_with("_loop"):
		sound_tag = sound_tag.left(-"_loop".length())
	if sound_tag in transcripion_map:
		transcribed.emit(transcripion_map[sound_tag])
	elif debug_mode:
		prints("[Info] tried to transcribe undefined sound:", sound_path)


## Starts indefinitely transcribing all sounds produced by [param player].
## [br]@PRE Player must be a valid audio stream player.
func connect_player(player: Node) -> void:
	
	assert(U.is_valid_audio_player(player),
			"Player is not a valid AudioStreamPlayer")
	var sound_tag: String = player.stream.resource_path
	player.started.connect(_on_sound_played.bind(sound_tag))


## Stops transcribing sounds produced by [param player].
## [br]@PRE Player must be a valid audio stream player.
func disconnect_player(player: Node) -> void:
	
	assert(U.is_valid_audio_player(player),
			"Player is not a valid AudioStreamPlayer")
	var sound_tag: String = player.stream.resource_path
	player.started.disconnect(_on_sound_played.bind(sound_tag))
