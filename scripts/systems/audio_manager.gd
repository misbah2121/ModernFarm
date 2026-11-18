extends Node
## Autoload "AudioManager" (Phase 12): musik, efek suara (SFX), dan suara lingkungan (ambient).
## Asset pack Modern_Farm_v1.2 TIDAK berisi audio. Sistem ini mencari file berdasarkan NAMA:
##   musik   : res://assets/audio/music/<nama>.ogg|.wav|.mp3   (farm, village, forest, mine, menu)
##   sfx     : res://assets/audio/sfx/<nama>.ogg|.wav|.mp3     (step, hoe, water, coin, ...)
##   ambient : res://assets/audio/ambient/<nama>.ogg|.wav|.mp3 (rain)
## File yang tidak ada dilewati tanpa error, jadi suara bisa ditambah kapan saja tanpa mengubah kode.
## Volume diatur per bus: "Music", "SFX", "Ambient" (dibuat otomatis jika belum ada di Audio Bus Layout).

const MUSIC_DIR := "res://assets/audio/music/"
const SFX_DIR := "res://assets/audio/sfx/"
const AMBIENT_DIR := "res://assets/audio/ambient/"
const EXTENSIONS: Array[String] = ["ogg", "wav", "mp3"]
const BUSES: Array[String] = ["Music", "SFX", "Ambient"]
const SFX_VOICES := 8
const FADE_TIME := 0.8

var _music: AudioStreamPlayer
var _ambient: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_index := 0
var _music_key := ""
var _ambient_key := ""
var _cache: Dictionary = {}  # path folder + nama -> AudioStream atau null
var _music_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # tetap bersuara saat game di-pause (menu)
	_ensure_buses()
	_music = _make_player("Music")
	_ambient = _make_player("Ambient")
	for i in SFX_VOICES:
		_sfx.append(_make_player("SFX"))


func _ensure_buses() -> void:
	for bus_name in BUSES:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, bus_name)
			AudioServer.set_bus_send(index, "Master")


func _make_player(bus_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus_name
	add_child(player)
	return player


## Mencari file audio "<folder><nama>.<ext>". null jika tidak ada.
func _find(folder: String, key: String) -> AudioStream:
	var cache_key := folder + key
	if _cache.has(cache_key):
		return _cache[cache_key]
	var stream: AudioStream = null
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [folder, key, ext]
		if ResourceLoader.exists(path):
			stream = load(path) as AudioStream
			break
	_cache[cache_key] = stream
	return stream


func _set_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(wav.get_length() * wav.mix_rate)


# ---------------------------------------------------------------- musik

## Memutar musik (berulang). Nama sama = tidak diulang dari awal. File tidak ada = musik berhenti.
func play_music(key: String) -> void:
	if key == _music_key and _music.playing:
		return
	_music_key = key
	var stream := _find(MUSIC_DIR, key)
	if _music_tween != null:
		_music_tween.kill()
	_music_tween = create_tween()
	if _music.playing:
		_music_tween.tween_property(_music, "volume_db", -40.0, FADE_TIME * 0.5)
	_music_tween.tween_callback(func() -> void:
		_music.stop()
		if stream != null:
			_set_loop(stream)
			_music.stream = stream
			_music.volume_db = -40.0
			_music.play())
	if stream != null:
		_music_tween.tween_property(_music, "volume_db", 0.0, FADE_TIME)


func stop_music() -> void:
	_music_key = ""
	_music.stop()


# ---------------------------------------------------------------- ambient

func play_ambient(key: String) -> void:
	if key == _ambient_key and _ambient.playing:
		return
	_ambient_key = key
	var stream := _find(AMBIENT_DIR, key)
	_ambient.stop()
	if stream == null:
		return
	_set_loop(stream)
	_ambient.stream = stream
	_ambient.play()


func stop_ambient() -> void:
	_ambient_key = ""
	_ambient.stop()


# ---------------------------------------------------------------- efek suara

## Efek suara singkat. pitch_variation = variasi acak nada (0.05 = +-5%).
func play_sfx(key: String, pitch_variation: float = 0.05, volume_db: float = 0.0) -> void:
	if key == "":
		return
	var stream := _find(SFX_DIR, key)
	if stream == null:
		return
	var player := _sfx[_sfx_index]
	_sfx_index = (_sfx_index + 1) % _sfx.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


# ---------------------------------------------------------------- volume

## volume 0.0 - 1.0 untuk bus "Master" / "Music" / "SFX" / "Ambient".
func set_bus_volume(bus_name: String, volume: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	volume = clampf(volume, 0.0, 1.0)
	AudioServer.set_bus_mute(index, volume <= 0.001)
	AudioServer.set_bus_volume_db(index, linear_to_db(maxf(volume, 0.001)))
