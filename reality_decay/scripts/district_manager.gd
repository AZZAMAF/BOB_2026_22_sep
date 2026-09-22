## district_manager.gd
## Manages the 4 alien city districts. Autoload singleton: "DistrictManager"
extends Node

# ─── Signals ────────────────────────────────────────────────────────────────
signal district_stability_changed(index: int, stability: float)
signal district_locked(index: int)
signal reality_decay_updated(pct: float)

# ─── Constants ───────────────────────────────────────────────────────────────
const DISTRICT_NAMES := ["ZETA-7", "KRYO-CORE", "NEXUS-Alpha", "VOID-Sector"]
const DISTRICT_COLORS := [
	Color(0.2, 0.5, 1.0),   # ZETA-7     : Blue crystalline
	Color(0.5, 0.9, 1.0),   # KRYO-CORE  : Ice
	Color(0.2, 1.0, 0.6),   # NEXUS-Alpha: Teal tech
	Color(0.7, 0.2, 1.0),   # VOID-Sector: Purple organic
]

# Extra decay added to non-stabilized districts when one is being stabilized
const COLLATERAL_DECAY_PENALTY := 0.5   # % per second

# ─── District Data ────────────────────────────────────────────────────────────
class District:
	var name: String
	var color: Color
	var stability: float = 100.0       # 0–100 %
	var is_locked: bool = false        # saved by blue button
	var stabilize_timer: float = 0.0   # seconds of active stabilization remaining
	var is_being_stabilized: bool = false

	func _init(n: String, c: Color) -> void:
		name = n
		color = c

var districts: Array[District] = []
var base_decay_rate: float = 1.0       # % per second
var _halted: bool = false

# ─── Lifecycle ───────────────────────────────────────────────────────────────
func _ready() -> void:
	for i in DISTRICT_NAMES.size():
		var d: District = District.new(DISTRICT_NAMES[i], DISTRICT_COLORS[i])
		districts.append(d)

func _process(delta: float) -> void:
	if _halted:
		return
	_update_stabilize_timers(delta)
	_apply_decay(delta)
	_emit_reality_decay()

# ─── Decay ────────────────────────────────────────────────────────────────────
func _apply_decay(delta: float) -> void:
	var stabilized_count: int = 0
	for d in districts:
		if d.is_being_stabilized:
			stabilized_count += 1

	for i in districts.size():
		var d: District = districts[i]
		if d.is_locked:
			continue
		var rate: float = base_decay_rate
		# Collateral penalty: every OTHER district that is being stabilized
		# costs the rest +0.5 %/s
		if not d.is_being_stabilized:
			rate += stabilized_count * COLLATERAL_DECAY_PENALTY

		d.stability = max(0.0, d.stability - rate * delta)
		emit_signal("district_stability_changed", i, d.stability)

func _update_stabilize_timers(delta: float) -> void:
	for d in districts:
		if d.is_being_stabilized:
			d.stabilize_timer -= delta
			if d.stabilize_timer <= 0.0:
				d.is_being_stabilized = false

func _emit_reality_decay() -> void:
	# Reality decay = average instability across all unlocked districts
	var total: float = 0.0
	var count: int = 0
	for d in districts:
		if not d.is_locked:
			total += (100.0 - d.stability)
			count += 1
	var pct: float = (total / count) if count > 0 else 100.0
	emit_signal("reality_decay_updated", pct)

# ─── External API ────────────────────────────────────────────────────────────

func stabilize(index: int, bonus_stability: float, duration: float) -> void:
	if index < 0 or index >= districts.size():
		return
	var d: District = districts[index]
	if d.is_locked:
		return
	d.stability = min(100.0, d.stability + bonus_stability)
	d.is_being_stabilized = true
	d.stabilize_timer = duration
	emit_signal("district_stability_changed", index, d.stability)

func lock_district(index: int) -> void:
	if index < 0 or index >= districts.size():
		return
	var d: District = districts[index]
	if d.is_locked:
		return
	d.is_locked = true
	d.is_being_stabilized = false
	emit_signal("district_locked", index)
	emit_signal("district_stability_changed", index, d.stability)

func set_halted(h: bool) -> void:
	_halted = h

func set_base_decay_rate(r: float) -> void:
	base_decay_rate = r

func increase_decay_rate(amount: float) -> void:
	base_decay_rate += amount

func get_saved_count() -> int:
	var count: int = 0
	for d in districts:
		if d.is_locked:
			count += 1
	return count

func get_saved_districts() -> Array:
	var result: Array = []
	for i in districts.size():
		if districts[i].is_locked:
			result.append(i)
	return result

func get_stability(index: int) -> float:
	if index < 0 or index >= districts.size():
		return 0.0
	return districts[index].stability

func is_district_locked(index: int) -> bool:
	if index < 0 or index >= districts.size():
		return false
	return districts[index].is_locked
