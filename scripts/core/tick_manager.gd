extends Node

signal simulation_tick(delta: float)
signal machine_tick(delta: float)
signal farming_tick(delta: float)
signal economy_tick(delta: float)

const MACHINE_INTERVAL := 0.1
const FARMING_INTERVAL := 1.0
const ECONOMY_INTERVAL := 10.0

var _machine_accumulator := 0.0
var _farming_accumulator := 0.0
var _economy_accumulator := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _physics_process(delta: float) -> void:
	simulation_tick.emit(delta)

func _process(delta: float) -> void:
	_machine_accumulator += delta
	_farming_accumulator += delta
	_economy_accumulator += delta

	while _machine_accumulator >= MACHINE_INTERVAL:
		_machine_accumulator -= MACHINE_INTERVAL
		machine_tick.emit(MACHINE_INTERVAL)

	while _farming_accumulator >= FARMING_INTERVAL:
		_farming_accumulator -= FARMING_INTERVAL
		farming_tick.emit(FARMING_INTERVAL)

	while _economy_accumulator >= ECONOMY_INTERVAL:
		_economy_accumulator -= ECONOMY_INTERVAL
		economy_tick.emit(ECONOMY_INTERVAL)
