class_name Synth
extends RefCounted

static func sine(freq: float, duration: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var total: int = int(duration * float(sample_rate))
	var arr := PackedFloat32Array()
	arr.resize(total)
	var step: float = (TAU * freq) / float(sample_rate)
	var phase: float = 0.0
	for i in range(total):
		arr[i] = sin(phase)
		phase += step
	return arr

static func saw(freq: float, duration: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var total: int = int(duration * float(sample_rate))
	var arr := PackedFloat32Array()
	arr.resize(total)
	var period: float = float(sample_rate) / maxf(1.0, freq)
	for i in range(total):
		var phase: float = fmod(float(i), period) / period
		arr[i] = 2.0 * phase - 1.0
	return arr

static func square(freq: float, duration: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var total: int = int(duration * float(sample_rate))
	var arr := PackedFloat32Array()
	arr.resize(total)
	var period: float = float(sample_rate) / maxf(1.0, freq)
	for i in range(total):
		var phase: float = fmod(float(i), period) / period
		arr[i] = 1.0 if phase < 0.5 else -1.0
	return arr

static func noise(duration: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var total: int = int(duration * float(sample_rate))
	var arr := PackedFloat32Array()
	arr.resize(total)
	for i in range(total):
		arr[i] = randf_range(-1.0, 1.0)
	return arr

static func env_exp(samples: PackedFloat32Array, tau: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var arr := samples.duplicate()
	var total: int = arr.size()
	var dt: float = 1.0 / float(sample_rate)
	var decay: float = exp(-dt / maxf(0.0001, tau))
	var amp: float = 1.0
	for i in range(total):
		arr[i] *= amp
		amp *= decay
	return arr

static func glide(f_start: float, f_end: float, duration: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var total: int = int(duration * float(sample_rate))
	var arr := PackedFloat32Array()
	arr.resize(total)
	var phase: float = 0.0
	for i in range(total):
		var t: float = float(i) / float(total)
		var freq: float = lerpf(f_start, f_end, t)
		phase += (TAU * freq) / float(sample_rate)
		arr[i] = sin(phase)
	return arr

static func echo(samples: PackedFloat32Array, delay_sec: float, feedback: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var arr := samples.duplicate()
	var delay_samples: int = int(delay_sec * float(sample_rate))
	if delay_samples <= 0:
		return arr
	var total: int = arr.size()
	for i in range(delay_samples, total):
		arr[i] += arr[i - delay_samples] * feedback
	return arr

static func lowpass_onepole(samples: PackedFloat32Array, cutoff_hz: float, sample_rate: int = 44100) -> PackedFloat32Array:
	var arr := samples.duplicate()
	var total: int = arr.size()
	var costh: float = 2.0 - cos((TAU * cutoff_hz) / float(sample_rate))
	var coef_b: float = sqrt(costh * costh - 1.0) - costh
	var coef_a: float = 1.0 + coef_b
	var y: float = 0.0
	for i in range(total):
		y = coef_a * arr[i] - coef_b * y
		arr[i] = y
	return arr

static func to_wav(samples: PackedFloat32Array, sample_rate: int = 44100) -> AudioStreamWAV:
	var total: int = samples.size()
	var byte_arr := PackedByteArray()
	byte_arr.resize(total * 2)
	for i in range(total):
		var val: int = clampi(int(samples[i] * 32767.0), -32768, 32767)
		byte_arr.encode_s16(i * 2, val)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = byte_arr
	return wav
